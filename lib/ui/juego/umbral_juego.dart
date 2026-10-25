import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../dto/personaje_dto.dart';
import '../../dto/ubicacion_dto.dart';
import '../../servicio/modelos/combate.dart';
import '../../servicio/modelos/partida_jugable.dart';
import '../../servicio/modelos/progreso.dart';
import '../../servicio/modelos/recompensa.dart';
import '../clases_ui.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'escenario.dart';
import 'estilo_combate.dart';
import 'jugador.dart';
import 'mapa_interiores.dart';
import 'mapa_mundo.dart';
import 'registro_progreso.dart';
import 'sala_interior.dart';
import 'tipos_enemigo.dart';
import 'zona_tierras.dart';

/// Envía el progreso. La pantalla lo implementa con `PartidaServicio`.
typedef GuardarProgreso = Future<PartidaJugable> Function(
    String partidaId, Progreso progreso);

/// Pantallas de Flutter que se abren desde el juego.
enum PantallaJuego { estadisticas, herreria }

/// El juego en tiempo real. Las reglas de progresión las aplica el servidor:
/// aquí solo se juega con los valores de [combate] y se anota en [_registro]
/// lo que pasa, que se envía al descansar, al revivir o al salir.
class UmbralJuego extends FlameGame<Escenario> with KeyboardEvents {
  UmbralJuego({
    required PartidaJugable partida,
    required Map<String, Recompensa> recompensas,
    required this.alGuardar,
  })  : _guardada = partida,
        _registro = RegistroProgreso(recompensas),
        super(world: ZonaTierras()) {
    images.prefix = 'assets/';
    tierras = world as ZonaTierras;
  }

  final GuardarProgreso alGuardar;

  /// Última versión confirmada por el servidor.
  PartidaJugable _guardada;
  final RegistroProgreso _registro;
  late String? _puntoDeGuardado = personaje.ubicacion.ultimoPuntoGuardado;
  late final Jugador jugador;

  /// El mundo abierto. Mientras el jugador está en un interior, [world] es la
  /// sala y este se conserva tal como quedó.
  late final ZonaTierras tierras;
  late final MapaInteriores _interiores;
  final Map<Sala, SalaInterior> _salas = {};

  /// Delante de qué puerta del mundo se vuelve al salir de los interiores;
  /// `null` si el jugador está en el mundo.
  Vector2? _retorno;

  /// Evita volver a cruzar una salida en el mismo instante de llegar.
  double _esperaCruce = 0;

  PersonajeDto get personaje => _guardada.partida.personaje;
  Combate get combate => _guardada.combate;
  PartidaJugable get partidaGuardada => _guardada;

  // Estado que dibuja el HUD de Flutter.
  final vida = ValueNotifier<int>(1);
  final vidaMaxima = ValueNotifier<int>(1);
  final estamina = ValueNotifier<double>(estaminaMaxima);
  final nivel = ValueNotifier<int>(1);
  final exp = ValueNotifier<int>(0);
  final expSiguiente = ValueNotifier<int>(1);
  final oro = ValueNotifier<int>(0);
  final muerto = ValueNotifier<bool>(false);
  final guardando = ValueNotifier<bool>(false);
  final aviso = ValueNotifier<String?>(null);

  /// Verdadero un momento cuando se intenta atacar sin estamina suficiente.
  final sinEstamina = ValueNotifier<bool>(false);

  /// Lo que se puede hacer donde está el jugador.
  final acciones = ValueNotifier<List<AccionContexto>>(const []);

  /// Región del mapa o sala en la que está el jugador; la pantalla anuncia
  /// los cambios.
  final region = ValueNotifier<String>('');

  /// Lo pone la pantalla: abre el menú de pausa (tecla Escape).
  VoidCallback? alPedirMenu;

  /// Lo pone la pantalla: abre la pantalla de estadísticas o la herrería.
  void Function(PantallaJuego)? alAbrirPantalla;

  static const estaminaMaxima = 100.0;
  static const _recuperacionEstamina = 34.0;

  /// Tras gastar estamina tarda un poco en empezar a recuperarse.
  static const _pausaEstamina = 0.6;
  double _esperaEstamina = 0;
  double _avisoEstamina = 0;

  final Vector2 direccionJoystick = Vector2.zero();
  bool botonAtaque = false;
  final Set<LogicalKeyboardKey> _teclas = {};
  int _avisoId = 0;
  bool _avisoNivelMostrado = false;
  final _azar = Random();

  Escenario get zona => world;

  /// Escala entera de pantalla: 1 píxel de arte = [zoom] píxeles lógicos.
  double get zoom => camera.viewfinder.zoom;

  Vector2 get direccionEntrada {
    final teclado = Vector2(
      (_tecla(LogicalKeyboardKey.keyD, LogicalKeyboardKey.arrowRight) ? 1 : 0) -
          (_tecla(LogicalKeyboardKey.keyA, LogicalKeyboardKey.arrowLeft) ? 1 : 0),
      (_tecla(LogicalKeyboardKey.keyS, LogicalKeyboardKey.arrowDown) ? 1 : 0) -
          (_tecla(LogicalKeyboardKey.keyW, LogicalKeyboardKey.arrowUp) ? 1 : 0),
    );
    return teclado.length2 > 0 ? teclado.normalized() : direccionJoystick;
  }

  bool get atacando =>
      botonAtaque ||
      _tecla(LogicalKeyboardKey.space, LogicalKeyboardKey.keyJ);

  bool _tecla(LogicalKeyboardKey a, LogicalKeyboardKey b) =>
      _teclas.contains(a) || _teclas.contains(b);

  /// Si la experiencia alcanza para al menos un nivel (o quedan puntos de la
  /// regla anterior sin repartir).
  bool get puedeSubirNivel =>
      exp.value >= expSiguiente.value || personaje.puntosLibres > 0;

  /// Acción de los altares de brasas: se resalta cuando alcanza la
  /// experiencia.
  AccionContexto accionSubirNivel({required String icono}) => AccionContexto(
        'Subir de nivel',
        () => abrirPantalla(PantallaJuego.estadisticas),
        icono: icono,
        estilo: puedeSubirNivel ? EstiloBoton.acento : EstiloBoton.secundario,
      );

  @override
  Color backgroundColor() => Colores.abismo;

  @override
  Future<void> onLoad() async {
    final mapa = await MapaMundo.cargar();
    _interiores = await MapaInteriores.cargar();
    await images.loadAll([
      'tiles/tileset.png',
      'interiores/${_interiores.tileset}',
      for (final c in clasesUi.values)
        for (final ap in ['hombre', 'mujer'])
          c.sprite(ap).replaceFirst('assets/', ''),
      for (final e in [...Enemigos.todos, Enemigos.reyHueco]) e.sprite,
      for (final s in {for (final e in mapa.estructuras) e.sprite})
        'sprites/estructuras/$s.png',
    ]);
    tierras.preparar(mapa, _interiores, images);

    _mostrarProgreso();
    vida.value = personaje.vidaActual > 0
        ? min(personaje.vidaActual, combate.vidaMaxima)
        : combate.vidaMaxima;

    final u = personaje.ubicacion;
    final guardada = Vector2(u.x.toDouble(), u.y.toDouble());
    jugador = Jugador(
      rutaSprite: claseUi(personaje.clase)
          .sprite(personaje.apariencia)
          .replaceFirst('assets/', ''),
      estilo: estiloDe(personaje.clase),
      // Las partidas de antes de este mapa (y las nuevas, que el servidor
      // crea en otra zona) empiezan junto al altar.
      pies: u.zonaId == ZonaTierras.id && _posicionValida(guardada)
          ? guardada
          : tierras.inicio.clone(),
    );
    await world.add(jugador);
    region.value = zona.regionEn(jugador.position);

    camera.follow(jugador, snap: true);
    _limitarCamara();
  }

  bool _posicionValida(Vector2 p) => tierras.libre(
      Rect.fromCenter(center: Offset(p.x, p.y - 1.5), width: 8, height: 3));

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Escala entera y par (los sprites van a la mitad: así cada uno de sus
    // píxeles sigue siendo entero) que deja ver unos 100 píxeles de arte, seis
    // tiles, en el lado corto de la pantalla.
    final lado = min(size.x, size.y);
    camera.viewfinder.zoom =
        ((lado / 96 / 2).floor() * 2).clamp(2, 8).toDouble();
    if (isLoaded) _limitarCamara();
  }

  /// Mantiene la vista dentro del escenario. El centro de la cámara puede ir
  /// hasta media vista de cada borde; si la sala es más chica que la vista,
  /// queda centrada. Se calcula aquí porque `considerViewport` de Flame mide
  /// la vista en píxeles de pantalla e ignora el zoom.
  void _limitarCamara() {
    final l = zona.limites;
    final medio = size / (zoom * 2);
    final dx = min(medio.x, l.width / 2), dy = min(medio.y, l.height / 2);
    camera.setBounds(
        Rectangle.fromLTRB(l.left + dx, l.top + dy, l.right - dx, l.bottom - dy));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!muerto.value) _registro.segundos += dt;
    _recuperarEstamina(dt);
    if (!jugador.isMounted) return;

    final pies = jugador.position;
    region.value = zona.regionEn(pies);
    _esperaCruce = max(0, _esperaCruce - dt);
    if (jugador.vivo && _esperaCruce == 0) zona.pisando(pies);
    _ponerAcciones(jugador.vivo ? zona.accionesEn(pies) : const []);
  }

  /// Solo avisa a la pantalla si cambian las etiquetas o estilos: las
  /// acciones se calculan cada cuadro.
  void _ponerAcciones(List<AccionContexto> nuevas) {
    if (listEquals([for (final a in acciones.value) (a.etiqueta, a.estilo)],
        [for (final a in nuevas) (a.etiqueta, a.estilo)])) {
      return;
    }
    acciones.value = nuevas;
  }

  void _recuperarEstamina(double dt) {
    _avisoEstamina = max(0, _avisoEstamina - dt);
    if (_avisoEstamina == 0) sinEstamina.value = false;
    if (_esperaEstamina > 0) {
      _esperaEstamina = max(0, _esperaEstamina - dt);
    } else if (estamina.value < estaminaMaxima) {
      estamina.value =
          min(estaminaMaxima, estamina.value + _recuperacionEstamina * dt);
    }
  }

  /// Gasta [costo] de estamina si alcanza. Si no, la barra parpadea.
  bool gastarEstamina(double costo) {
    if (estamina.value < costo) {
      _avisoEstamina = 0.35;
      sinEstamina.value = true;
      return false;
    }
    estamina.value -= costo;
    _esperaEstamina = _pausaEstamina;
    return true;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _teclas
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyE &&
          acciones.value.isNotEmpty) {
        acciones.value.first.alPulsar();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        alPedirMenu?.call();
      }
    }
    return KeyEventResult.handled;
  }

  /// Suelta teclas, cruceta y botón de ataque: se usa al abrir otra pantalla,
  /// que se queda con las pulsaciones.
  void soltarControles() {
    _teclas.clear();
    botonAtaque = false;
    direccionJoystick.setZero();
  }

  void abrirPantalla(PantallaJuego pantalla) => alAbrirPantalla?.call(pantalla);

  /// Pasa al interior [sala] desde la puerta del mundo en [puerta].
  void entrar(Sala sala, Vector2 puerta) {
    _retorno = puerta.clone();
    final destino = _sala(sala);
    _cambiarA(destino, destino.llegada('salida'));
  }

  /// El jugador pisó la salida o la escalera de bajada de [desde].
  void cruzar(SalaInterior desde, String tipo) {
    final sala = desde.sala;
    if (tipo == 'bajada') {
      final abajo = _interiores.abajo(sala);
      if (abajo == null) return;
      final destino = _sala(abajo);
      _cambiarA(destino, destino.llegada('salida'));
      return;
    }
    final arriba = _interiores.arriba(sala);
    if (arriba != null) {
      final destino = _sala(arriba);
      _cambiarA(destino, destino.llegada('bajada'));
    } else {
      _salirAlMundo();
    }
  }

  SalaInterior _sala(Sala sala) =>
      _salas.putIfAbsent(sala, () => SalaInterior(_interiores, sala));

  void _salirAlMundo() {
    final puerta = _retorno ?? tierras.inicio;
    _retorno = null;
    _cambiarA(tierras, puerta.clone());
  }

  void _cambiarA(Escenario destino, Vector2 pies) {
    if (!identical(destino, world)) {
      jugador.parent = destino;
      world = destino;
    }
    jugador.position.setFrom(pies);
    camera.follow(jugador, snap: true);
    _limitarCamara();
    _esperaCruce = 0.4;
    region.value = destino.regionEn(pies);
  }

  /// Daño de un golpe del jugador: el de su nivel ±10 % y posible crítico.
  (int, bool) tirarDano() {
    final critico = _azar.nextDouble() < combate.probabilidadCritico;
    final variacion = 0.9 + _azar.nextDouble() * 0.2;
    final multiplicador = critico ? combate.multiplicadorCritico : 1;
    return ((combate.dano * variacion * multiplicador).round(), critico);
  }

  /// La armadura resta daño, pero todo golpe quita al menos 1.
  int danoRecibido(int danoEnemigo) => max(1, danoEnemigo - combate.defensa);

  void enemigoDerrotado(Enemigo enemigo) {
    _registro.enemigoDerrotado(enemigo.tipo.id);
    final recompensa = _registro.recompensa(enemigo.tipo.id);
    zona.add(TextoFlotante(
      '+${recompensa.exp} EXP  +${recompensa.oro} ORO',
      enemigo.centro - Vector2(0, 14),
      color: Colores.brasa,
      grande: false,
      duracion: 1.1,
    ));
    _mostrarProgreso();
    if (enemigo.tipo == Enemigos.reyHueco) {
      mostrarAviso('El Rey Hueco se deshace en ceniza.');
    } else if (exp.value >= expSiguiente.value && !_avisoNivelMostrado) {
      _avisoNivelMostrado = true;
      mostrarAviso('Tu experiencia basta para subir de nivel en un altar de brasas.');
    }
  }

  void jugadorMuerto() {
    muerto.value = true;
    _registro.muertes++;
    zona.add(Estallido(jugador.centro, const [
      Colores.sangre,
      Colores.hueso,
      Colores.abismo,
    ]));
  }

  /// Vida llena (pociones de un cofre).
  void curar(String mensaje) {
    vida.value = combate.vidaMaxima;
    mostrarAviso(mensaje);
  }

  /// Despierta junto al altar con la vida llena. Los enemigos vuelven.
  Future<void> revivir() async {
    vida.value = combate.vidaMaxima;
    estamina.value = estaminaMaxima;
    _retorno = null;
    _cambiarA(tierras, tierras.inicio.clone());
    jugador.reaparecer(tierras.inicio.clone());
    _reiniciarTodo();
    muerto.value = false;
    await guardar(silencioso: true);
  }

  /// Descanso en el altar: vida llena, enemigos de vuelta y partida guardada.
  Future<void> descansar() async {
    if (guardando.value) return;
    vida.value = combate.vidaMaxima;
    estamina.value = estaminaMaxima;
    _reiniciarTodo();
    _puntoDeGuardado = ZonaTierras.puntoDeGuardado;
    final ok = await guardar(silencioso: true);
    if (ok) mostrarAviso('Descansas junto a las brasas. Partida guardada.');
  }

  void _reiniciarTodo() {
    tierras.reiniciarEnemigos();
    for (final s in _salas.values) {
      if (s.isLoaded) s.reiniciarEnemigos();
    }
  }

  /// Envía el registro y aplica la respuesta del servidor. Devuelve `false` si
  /// no se pudo guardar (y lo avisa); el registro se conserva para reintentar.
  Future<bool> guardar({bool silencioso = false}) async {
    if (guardando.value) return false;
    guardando.value = true;
    // Dentro de un interior se guarda la puerta del mundo por la que se entró.
    final pies = _retorno ?? jugador.position;
    final enviado = _registro.aProgreso(
      vidaActual: vida.value,
      ubicacion: UbicacionDto(
        zonaId: ZonaTierras.id,
        x: pies.x.round(),
        y: pies.y.round(),
        ultimoPuntoGuardado: _puntoDeGuardado,
      ),
    );
    try {
      _guardada = await alGuardar(_guardada.partida.partidaId, enviado);
      _registro.descontar(enviado);
      _mostrarProgreso();
      if (!silencioso) mostrarAviso('Partida guardada.');
      return true;
    } catch (e) {
      mostrarAviso('No se pudo guardar. $e');
      return false;
    } finally {
      guardando.value = false;
    }
  }

  /// Aplica una partida que el servidor devolvió fuera del guardado (niveles
  /// subidos o equipo mejorado). Si sube la vida máxima, la vida actual sube
  /// lo mismo.
  void aplicarPartida(PartidaJugable nueva) {
    final maximaAntes = combate.vidaMaxima;
    _guardada = nueva;
    vida.value = (vida.value + combate.vidaMaxima - maximaAntes)
        .clamp(1, combate.vidaMaxima);
    _mostrarProgreso();
    _avisoNivelMostrado = false;
    acciones.value = const []; // se recalculan con el nuevo estado
  }

  void mostrarAviso(String texto) {
    final id = ++_avisoId;
    aviso.value = texto;
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (_avisoId == id) aviso.value = null;
    });
  }

  /// Lo guardado más lo ganado desde entonces.
  void _mostrarProgreso() {
    vidaMaxima.value = combate.vidaMaxima;
    nivel.value = personaje.nivel;
    exp.value = personaje.exp + _registro.exp;
    expSiguiente.value = combate.expSiguiente;
    oro.value = personaje.oro + _registro.oro;
  }
}
