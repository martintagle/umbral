import 'dart:math';

import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
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
import 'efectos.dart';
import 'enemigo.dart';
import 'estilo_combate.dart';
import 'jugador.dart';
import 'registro_progreso.dart';
import 'tipos_enemigo.dart';
import 'mapa_mundo.dart';
import 'zona_tierras.dart';

/// Envía el progreso. La pantalla lo implementa con `PartidaServicio`.
typedef GuardarProgreso = Future<PartidaJugable> Function(
    String partidaId, Progreso progreso);

/// El juego en tiempo real. Las reglas de progresión las aplica el servidor:
/// aquí solo se juega con los valores de [combate] y se anota en [_registro]
/// lo que pasa, que se envía al descansar, al revivir o al salir.
class UmbralJuego extends FlameGame<ZonaTierras> with KeyboardEvents {
  UmbralJuego({
    required PartidaJugable partida,
    required Map<String, Recompensa> recompensas,
    required this.alGuardar,
  })  : _guardada = partida,
        _registro = RegistroProgreso(recompensas),
        super(world: ZonaTierras()) {
    images.prefix = 'assets/';
  }

  final GuardarProgreso alGuardar;

  /// Última versión confirmada por el servidor.
  PartidaJugable _guardada;
  final RegistroProgreso _registro;
  late String? _puntoDeGuardado = personaje.ubicacion.ultimoPuntoGuardado;
  late final Jugador jugador;

  PersonajeDto get personaje => _guardada.partida.personaje;
  Combate get combate => _guardada.combate;

  // Estado que dibuja el HUD de Flutter.
  final vida = ValueNotifier<int>(1);
  final vidaMaxima = ValueNotifier<int>(1);
  final nivel = ValueNotifier<int>(1);
  final exp = ValueNotifier<int>(0);
  final expSiguiente = ValueNotifier<int>(1);
  final oro = ValueNotifier<int>(0);
  final enElAltar = ValueNotifier<bool>(false);
  final muerto = ValueNotifier<bool>(false);
  final guardando = ValueNotifier<bool>(false);
  final aviso = ValueNotifier<String?>(null);

  /// Región del mapa en la que está el jugador; la pantalla anuncia los cambios.
  final region = ValueNotifier<String>('');

  /// Lo pone la pantalla: abre el menú de pausa (tecla Escape).
  VoidCallback? alPedirMenu;

  final Vector2 direccionJoystick = Vector2.zero();
  bool botonAtaque = false;
  final Set<LogicalKeyboardKey> _teclas = {};
  int _avisoId = 0;
  bool _avisoNivelMostrado = false;
  final _azar = Random();

  ZonaTierras get zona => world;

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

  @override
  Color backgroundColor() => Colores.abismo;

  @override
  Future<void> onLoad() async {
    final mapa = await MapaMundo.cargar();
    await images.loadAll([
      'tiles/tileset.png',
      for (final c in clasesUi.values)
        for (final ap in ['hombre', 'mujer'])
          c.sprite(ap).replaceFirst('assets/', ''),
      for (final e in Enemigos.todos) e.sprite,
      for (final s in {for (final e in mapa.estructuras) e.sprite})
        'sprites/estructuras/$s.png',
    ]);
    zona.preparar(mapa, images);

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
          : zona.inicio.clone(),
    );
    await world.add(jugador);
    region.value = zona.mapa.regionEn(jugador.position);

    camera.follow(jugador, snap: true);
    _limitarCamara();
  }

  bool _posicionValida(Vector2 p) => world.libre(
      Rect.fromCenter(center: Offset(p.x, p.y - 2.5), width: 12, height: 5));

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Escala entera (el diseño no permite escalas fraccionarias) que deja ver
    // unos 110 píxeles de arte en el lado corto de la pantalla.
    final lado = min(size.x, size.y);
    camera.viewfinder.zoom = (lado / 110).floorToDouble().clamp(2, 4);
    if (isLoaded) _limitarCamara();
  }

  /// Mantiene la vista dentro del mapa. El centro de la cámara puede ir hasta
  /// media vista de cada borde; se calcula aquí porque `considerViewport` de
  /// Flame mide la vista en píxeles de pantalla e ignora el zoom.
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
    enElAltar.value = jugador.isMounted &&
        jugador.vivo &&
        world.cercaDelAltar(jugador.position);
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _teclas
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyE && enElAltar.value) {
        descansar();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        alPedirMenu?.call();
      }
    }
    return KeyEventResult.handled;
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
    world.add(TextoFlotante(
      '+${recompensa.exp} EXP  +${recompensa.oro} ORO',
      enemigo.centro - Vector2(0, 22),
      color: Colores.brasa,
      grande: false,
      duracion: 1.1,
    ));
    _mostrarProgreso();
    if (exp.value >= expSiguiente.value && !_avisoNivelMostrado) {
      _avisoNivelMostrado = true;
      mostrarAviso('Tu experiencia basta para subir de nivel. Descansa en el altar.');
    }
  }

  void jugadorMuerto() {
    muerto.value = true;
    _registro.muertes++;
    world.add(Estallido(jugador.centro, const [
      Colores.sangre,
      Colores.hueso,
      Colores.abismo,
    ]));
  }

  /// Despierta junto al altar con la vida llena. Los enemigos vuelven.
  Future<void> revivir() async {
    vida.value = combate.vidaMaxima;
    jugador.reaparecer(zona.inicio.clone());
    world.reiniciarEnemigos();
    muerto.value = false;
    await guardar(silencioso: true);
  }

  /// Descanso en el altar: vida llena, enemigos de vuelta y partida guardada.
  /// Es aquí donde se sube de nivel.
  Future<void> descansar() async {
    if (guardando.value || !enElAltar.value) return;
    vida.value = combate.vidaMaxima;
    world.reiniciarEnemigos();
    _puntoDeGuardado = ZonaTierras.puntoDeGuardado;
    final ok = await guardar(silencioso: true);
    if (ok) mostrarAviso('Descansas junto a las brasas. Partida guardada.');
  }

  /// Envía el registro y aplica la respuesta del servidor. Devuelve `false` si
  /// no se pudo guardar (y lo avisa); el registro se conserva para reintentar.
  Future<bool> guardar({bool silencioso = false}) async {
    if (guardando.value) return false;
    guardando.value = true;
    final enviado = _registro.aProgreso(
      vidaActual: vida.value,
      ubicacion: UbicacionDto(
        zonaId: ZonaTierras.id,
        x: jugador.position.x.round(),
        y: jugador.position.y.round(),
        ultimoPuntoGuardado: _puntoDeGuardado,
      ),
    );
    try {
      final nivelAntes = personaje.nivel;
      _guardada = await alGuardar(_guardada.partida.partidaId, enviado);
      _registro.descontar(enviado);
      _mostrarProgreso();
      if (personaje.nivel > nivelAntes) {
        vida.value = personaje.vidaActual;
        _avisoNivelMostrado = false;
        mostrarAviso('Subes a nivel ${personaje.nivel}. Tu vida se renueva.');
      } else if (!silencioso) {
        mostrarAviso('Partida guardada.');
      }
      return true;
    } catch (e) {
      mostrarAviso('No se pudo guardar. $e');
      return false;
    } finally {
      guardando.value = false;
    }
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
