import 'dart:math';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

import '../sonido.dart';
import '../tema/tema_umbral.dart';
import 'ambiente.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'escenario.dart';
import 'iluminacion.dart';
import 'mapa_interiores.dart';
import 'mapa_mundo.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

const _lado = MapaMundo.tile;

/// Una zona del mundo abierto en plena noche: las Tierras del Umbral
/// (`assets/mapas/mundo.json`) o una de las zonas 2 a 6 (`docs/zonas.md`).
/// Las coordenadas están en píxeles de arte desde la esquina superior
/// izquierda del mapa.
///
/// En las zonas 2 a 6 la arena del jefe está tras una reja que abre la llave
/// de un cofre, y la salida tras otra que se abre al vencer al jefe. La Hoz se
/// da por conseguida: las zarzas se cortan.
class ZonaTierras extends Escenario {
  /// La primera zona, donde empieza la partida.
  static const id = MapaMundo.primera;

  /// El altar de la aldea Cenizal, como lo guardaban las partidas de antes de
  /// las zonas nuevas. Los altares de las demás zonas son `altar:<zona>:<n>`.
  static const puntoDeGuardado = 'altar-de-brasas';

  /// Antorchas repartidas por los caminos de la zona 1, en tiles.
  static const _antorchas = [
    // Aldea Cenizal
    (27, 21), (38, 21), (27, 26), (34, 29), (30, 13),
    // Bosque Podrido
    (16, 7), (21, 11), (34, 12), (48, 8),
    // Cementerio de los Callados
    (46, 22), (52, 25), (55, 22), (60, 22),
    // Lago Negro
    (19, 25), (19, 27), (8, 17), (5, 35),
    // Ruinas del Sur
    (30, 35), (34, 35), (28, 40), (35, 40), (51, 38),
  ];

  late final MapaMundo mapa;
  @override
  late final Rect limites;

  /// Base de cada altar de brasas, en el orden del mapa.
  final List<Vector2> altares = [];

  /// Lo que cambia al encender cada altar, en el mismo orden.
  final List<({SpriteComponent sprite, _Brasas brasas, Luz luz})> _fogatas =
      [];
  final List<Rect> _obstaculos = [];
  final Map<int, _FilaAlta> _filas = {};
  late final Image _tileset;
  late final _Suelo _suelo;
  Letrero? _letreroLeido;

  /// Luz de brasa de cada muro agrietado aún en pie, por el id del mecanismo.
  final Map<String, List<Luz>> _lucesGrietas = {};
  double _avisoReja = 0;

  /// Puertas de las estructuras que tienen interior: el punto justo delante
  /// de la puerta y la sala a la que llevan.
  final List<(Vector2, Sala)> puertas = [];

  static const _distanciaPuerta = 14.0;
  /// Desde la celda de al lado: los pies quedan a unos 22 px del centro.
  static const _distanciaObjeto = 28.0;

  String get zonaId => mapa.id;
  Vector2 get inicio => mapa.inicio;

  @override
  String regionEn(Vector2 pies) => mapa.regionEn(pies);

  @override
  bool pisaPiedra(Vector2 pies) => mapa.piedra(pies.x, pies.y - 1);

  @override
  bool esAgua(double x, double y) => mapa.agua(x, y);

  /// Las criaturas que vienen de la zona anterior son aquí las débiles:
  /// abundan como tales.
  bool esDebil(String tipo) =>
      mapa.numero > 1 && mapa.enemigosDeLaZona.take(3).contains(tipo);

  /// Pies de quien despierta junto al altar [n]. En la zona 1, el inicio de
  /// siempre.
  Vector2 junto(int n) {
    if (mapa.numero == 1 || n >= altares.length) return inicio.clone();
    final base = altares[n];
    for (final (dx, dy) in const [(0, 20), (-20, 18), (20, 18), (0, 34)]) {
      final pies = base + Vector2(dx.toDouble(), dy.toDouble());
      if (libre(_caja(pies))) return pies;
    }
    return inicio.clone();
  }

  /// Dónde aparece quien llega por el paso [paso] de esta zona: dos celdas
  /// hacia dentro del borde.
  Vector2 llegadaPor(Paso paso) {
    final (dx, dy) = paso.y == 0
        ? (0, 1)
        : paso.x == 0
        ? (1, 0)
        : paso.x == mapa.ancho - 1
        ? (-1, 0)
        : (0, -1);
    for (final n in const [2, 3, 1]) {
      final pies = MapaMundo.piesEnCelda(paso.x + dx * n, paso.y + dy * n);
      if (libre(_caja(pies))) return pies;
    }
    return inicio.clone();
  }

  static Rect _caja(Vector2 pies) =>
      Rect.fromCenter(center: Offset(pies.x, pies.y - 1.5), width: 8, height: 3);

  /// Lo llama el juego al cargar, antes de colocar al jugador: así las
  /// colisiones ya existen cuando se comprueba la posición guardada.
  void preparar(MapaMundo mapa, Interiores interiores, Images imagenes) {
    _tileset = imagenes.fromCache(mapa.tileset);
    final extra = _Extra(
      variantes: imagenes.fromCache(mapa.tilesetVariantes),
      bordes: imagenes.fromCache(mapa.tilesetBordes),
      animados: imagenes.fromCache(mapa.tilesetAnimados),
    );
    this.mapa = mapa;
    limites = Rect.fromLTWH(0, 0, mapa.anchoPx, mapa.altoPx);
    final clima = Clima.de(mapa.id);
    final iluminacion = Iluminacion(
      oscuridad: clima.oscuridad,
      noche: clima.noche,
    );
    _obstaculos.clear();
    _ponerPuertas(interiores);

    // Lo que ya se abrió en la partida queda abierto antes de pintar nada.
    for (final m in mapa.mecanismos) {
      if (game.mecanismoActivado(_idMecanismo(m))) _resolver(m);
    }

    add(_suelo = _Suelo(mapa, _tileset, extra));
    add(_Animados(mapa, extra.animados));
    for (var y = 0; y < mapa.alto; y++) {
      add(_filas[y] = _FilaAlta(mapa, _tileset, extra.animados, y));
    }
    for (var y = 0; y < mapa.alto; y++) {
      for (var x = 0; x < mapa.ancho; x++) {
        final o = mapa.objetos[y][x];
        if (mapa.objetosAltos.contains(o)) _poner(x, y, mapa.indiceObjetos + o);
      }
    }
    // Los cofres con requisito no existen hasta cumplirlo: los saca [update].
    for (final c in mapa.cofres) {
      if (_cofreVisible(c)) _ponerCofre(c);
    }
    for (final l in mapa.letreros) {
      _poner(l.x, l.y, _entidad('letrero'));
    }

    for (final e in mapa.estructuras) {
      final imagen = imagenes.fromCache('sprites/estructuras/${e.sprite}.png');
      final base = (e.y + e.h) * _lado;
      // Las entradas de las mazmorras vienen dibujadas a 8× (512 px para una
      // huella de 64): se reducen al ancho de su huella para no tapar la
      // vista. Escala entera inversa, así cada píxel de arte sigue entero.
      final escala =
          1 / max(1, (imagen.width / (e.w * _lado)).ceil()).toDouble();
      final ancho = imagen.width * escala, alto = imagen.height * escala;
      final sprite = SpriteComponent(
        sprite: Sprite(imagen),
        size: Vector2(ancho, alto),
        position: Vector2(
          (e.x * _lado + (e.w * _lado - ancho) / 2).roundToDouble(),
          base - alto,
        ),
        priority: base.round(),
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      );
      add(sprite);
      if (e.sprite == 'altar-de-brasas') {
        final altar = Vector2((e.x + e.w / 2) * _lado, base);
        altares.add(altar);
        final brasas = _Brasas(altar + Vector2(0, -26));
        final luz = Luz(
          brasas.position,
          radio: 48,
          tinte: Colores.brasa,
          parpadeo: 2,
        );
        add(brasas);
        iluminacion.fijas.add(luz);
        _fogatas.add((sprite: sprite, brasas: brasas, luz: luz));
      } else if (e.puerta.isNotEmpty) {
        // La entrada de la mazmorra arde como un faro en la arena.
        iluminacion.fijas.add(
          Luz(
            Vector2((e.x + e.w / 2) * _lado, base - 16),
            radio: 40,
            tinte: Colores.brasa,
            parpadeo: 2,
          ),
        );
      }
    }

    if (mapa.numero == 1) {
      for (final (x, y) in _antorchas) {
        final antorcha = Antorcha(MapaMundo.piesEnCelda(x, y));
        add(antorcha);
        _obstaculos.add(antorcha.huella);
        iluminacion.fijas.add(
          Luz(antorcha.llama, radio: 36, tinte: Colores.brasa, parpadeo: 2),
        );
      }
      for (final p in [
        Vector2(626, 264), // campanario de la capilla
        Vector2(950, 274), // farol del árbol de la jaula
        Vector2(504, 633), // ventana de la torre derruida
      ]) {
        iluminacion.fijas.add(
          Luz(p, radio: 20, tinte: Colores.brasa, parpadeo: 1),
        );
      }
    } else {
      // Las zonas nuevas no traen antorchas: los letreros tienen un farol.
      for (final l in mapa.letreros) {
        iluminacion.fijas.add(
          Luz(
            MapaMundo.centroDe(l.x, l.y),
            radio: 30,
            tinte: Colores.brasa,
            parpadeo: 2,
          ),
        );
      }
    }

    // Por las grietas de los muros que siguen en pie escapa algo de brasa.
    for (final m in mapa.mecanismos) {
      if (m.tipo != 'grieta' || game.mecanismoActivado(_idMecanismo(m))) {
        continue;
      }
      final luces = [
        for (final (x, y) in m.celdas)
          Luz(
            MapaMundo.centroDe(x, y),
            radio: 14,
            tinte: Colores.brasa,
            parpadeo: 1,
          ),
      ];
      iluminacion.fijas.addAll(luces);
      _lucesGrietas[m.id] = luces;
    }
    add(iluminacion);
    ponerAmbiente(this, clima);

    abrirCerrojos();
    reiniciarEnemigos();
  }

  /// Un cofre sin requisito, o con el requisito cumplido.
  bool _cofreVisible(CofreMapa c) => switch (c.requiere) {
    final r? => game.datosOreste.cumple(r, game, c.id),
    null => true,
  };

  /// Cofres con requisito ya puestos en el mapa.
  final Set<CofreMapa> _cofresMostrados = {};

  /// La k-ésima estructura con un sprite lleva a la k-ésima sala de entrada
  /// de ese sprite en `interiores.json`: en la zona 1, la choza del norte a la
  /// Choza en ruinas y la del sur a la Herrería abandonada. En las demás, la
  /// Herrera espera en cada choza, y la entrada de la arena baja a la
  /// mazmorra del jefe.
  void _ponerPuertas(Interiores interiores) {
    final comunes = interiores.mapas.first;
    final herreria = interiores.porSlug('herreria-abandonada');
    final usadas = <String, int>{};
    for (final e in mapa.estructuras) {
      final Sala? sala;
      // Una estructura puede decir a qué sala lleva (el Refugio del
      // Apagador); entonces no cuenta para el orden de las de su sprite.
      if (e.interior case final slug?) {
        sala = interiores.porSlug(slug);
        if (sala != null) puertas.add((_puertaDe(e), sala));
        continue;
      }
      final k = usadas.update(e.sprite, (n) => n + 1, ifAbsent: () => 0);
      if (mapa.jefe case (entrada: final entrada?, mazmorra: final id?, tipo: _)
          when entrada == e.sprite) {
        sala = interiores.mazmorra(id)?.entradas(e.sprite).firstOrNull;
      } else if (mapa.numero > 1 && e.sprite == 'choza-en-ruinas') {
        sala = herreria;
      } else {
        final salas = comunes.entradas(e.sprite);
        sala = k < salas.length ? salas[k] : null;
      }
      if (sala != null) puertas.add((_puertaDe(e), sala));
    }
  }

  /// El punto justo delante de la puerta de [e].
  static Vector2 _puertaDe(Estructura e) =>
      Vector2((e.x + e.w / 2) * _lado, (e.y + e.h) * _lado + 3);

  int _entidad(String nombre) =>
      mapa.indiceEntidades + mapa.nombresEntidades.indexOf(nombre);

  void _poner(int x, int y, int cuadro) => _filas[y]!.poner(x, cuadro);

  /// Id del cofre en la partida: `zonaId/cofreId`.
  String idCofre(CofreMapa c) => '${mapa.id}/${c.id}';

  void _ponerCofre(CofreMapa c) => _poner(
    c.x,
    c.y,
    _entidad(game.cofreAbierto(idCofre(c)) ? 'cofre-abierto' : 'cofre'),
  );

  /// Abre lo que ya no debe estar cerrado: la reja de la arena si se tiene
  /// la llave de la zona, y la de la salida si cayó su jefe.
  void abrirCerrojos() {
    final reja = mapa.objeto('reja'), abierta = mapa.objeto('reja-abierta');
    if (reja < 0) return;
    final llave = mapa.cofres.any(
      (c) => c.contenido.startsWith('llave') && game.cofreAbierto(idCofre(c)),
    );
    final jefeVencido = switch (mapa.jefe) {
      final j? => game.jefesDerrotados.contains(j.tipo),
      null => false,
    };
    final salida = mapa.salida?.rejas ?? const [];
    for (var y = 0; y < mapa.alto; y++) {
      for (var x = 0; x < mapa.ancho; x++) {
        if (mapa.objetos[y][x] != reja) continue;
        if (salida.contains((x, y)) ? jefeVencido : llave) {
          _cambiar(x, y, abierta);
        }
      }
    }
  }

  void _cambiar(int x, int y, int objeto) {
    mapa.cambiarObjeto(x, y, objeto);
    _poner(x, y, mapa.indiceObjetos + objeto);
  }

  /// Id del mecanismo en la partida: `zonaId/mecanismoId`.
  String _idMecanismo(Mecanismo m) => '${mapa.id}/${m.id}';

  /// Deja [m] resuelto en el mapa, sin efectos: la palanca accionada con su
  /// pasarela arriba, o el muro roto. Para lo ya activado al cargar la zona.
  void _resolver(Mecanismo m) {
    if (m.tipo == 'palanca') {
      mapa.cambiarObjeto(m.x!, m.y!, mapa.objeto('palanca-activa'));
      for (final (x, y) in m.celdas) {
        mapa.cambiarSuelo(x, y, mapa.sueloLlamado('puente'));
      }
    } else {
      for (final (x, y) in m.celdas) {
        _derribar(x, y);
      }
    }
  }

  /// El muro de (x, y) pasa al suelo de al lado, con escombros encima.
  void _derribar(int x, int y) {
    mapa.cambiarSuelo(x, y, mapa.sueloVecino(x, y));
    mapa.cambiarObjeto(x, y, mapa.objeto('escombros'));
  }

  /// La palanca sin accionar a mano de [pies], si hay una.
  Mecanismo? _palancaCerca(Vector2 pies) => mapa.mecanismos
      .where(
        (m) =>
            m.tipo == 'palanca' &&
            MapaMundo.centroDe(m.x!, m.y!).distanceTo(pies) <
                _distanciaObjeto &&
            !game.mecanismoActivado(_idMecanismo(m)),
      )
      .firstOrNull;

  /// Baja la palanca [m]: su pasarela sube del agua tabla a tabla, desde la
  /// orilla.
  void _accionarPalanca(Mecanismo m) {
    final id = _idMecanismo(m);
    if (game.mecanismoActivado(id)) return;
    game.activarMecanismo(id);
    _cambiar(m.x!, m.y!, mapa.objeto('palanca-activa'));
    add(Estallido(
      MapaMundo.centroDe(m.x!, m.y!),
      const [Colores.ceniza, Colores.hueso],
    ));
    Sonido.efecto(Audios.ataque(game.personaje.claseCodigo), volumen: 0.5);
    game.mostrarAviso(m.texto);
    final puente = mapa.sueloLlamado('puente');
    var siguiente = 0;
    late final TimerComponent tablas;
    tablas = TimerComponent(
      period: _esperaTabla,
      repeat: true,
      onTick: () {
        final (x, y) = m.celdas[siguiente++];
        mapa.cambiarSuelo(x, y, puente);
        _suelo.repintar(x, y);
        add(Estallido(
          MapaMundo.centroDe(x, y),
          const [Colores.alma, Colores.hueso],
        ));
        if (siguiente == m.celdas.length) tablas.removeFromParent();
      },
    );
    add(tablas);
  }

  /// Entre una tabla de la pasarela y la siguiente.
  static const _esperaTabla = 0.06;

  /// Rompe los muros agrietados en pie cuyo centro [alcanza] el ataque.
  @override
  void golpearMuros(bool Function(Vector2 centro) alcanza) {
    for (final m in mapa.mecanismos) {
      if (m.tipo == 'grieta' &&
          m.celdas.any((c) => alcanza(MapaMundo.centroDe(c.$1, c.$2)))) {
        romperGrieta(m);
      }
    }
  }

  /// El muro agrietado [m] se desmorona y deja paso.
  void romperGrieta(Mecanismo m) {
    final id = _idMecanismo(m);
    if (game.mecanismoActivado(id)) return;
    game.activarMecanismo(id);
    for (final (x, y) in m.celdas) {
      _derribar(x, y);
      _suelo.repintar(x, y);
      add(Estallido(
        MapaMundo.centroDe(x, y),
        const [Colores.ceniza, Colores.hueso],
      ));
    }
    for (final luz in _lucesGrietas.remove(m.id) ?? const <Luz>[]) {
      luz.encendida = false;
    }
    Sonido.efecto(Audios.muerteEnemigo, volumen: 0.6);
    game.mostrarAviso(m.texto);
  }

  @override
  void reiniciarEnemigos() {
    for (final e in children.whereType<Enemigo>().toList()) {
      e.removeFromParent();
    }
    for (final c in children.whereType<Proyectil>().toList()) {
      c.removeFromParent();
    }
    // Cada punto del mapa es un grupo, mayor cuanto más débil es su criatura,
    // que crece con el nivel del jugador.
    // Las que cayeron desde el último descanso no vuelven.
    for (final e in mapa.enemigos) {
      final n = game.criaturasPorGrupo(e.tipo) - game.caidosEn(_origen(e));
      for (var i = 0; i < n; i++) {
        _aparecer(e, cerca: i > 0);
      }
    }
    final esperadas = mapa.enemigos.fold(
      0.0,
      (total, e) => total + game.criaturasEsperadas(e.tipo),
    );
    _maximoVivos = (esperadas * 1.25).round();
    _esperaRefuerzo = game.intervaloRefuerzos;
  }

  final _azar = Random();
  int _maximoVivos = 0;
  double _esperaRefuerzo = 0;

  /// Pone una criatura del punto [e]: en su celda o, si [cerca], en una celda
  /// libre dentro de su radio.
  void _aparecer(EnemigoMapa e, {bool cerca = true}) {
    final tipo = Enemigos.porId(e.tipo);
    if (tipo == null || tipo.jefe) return;
    var pies = MapaMundo.piesEnCelda(e.x, e.y);
    if (cerca) {
      for (var intento = 0; intento < 8; intento++) {
        final p = MapaMundo.piesEnCelda(
          e.x + _azar.nextInt(e.radio * 2 + 1) - e.radio,
          e.y + _azar.nextInt(e.radio * 2 + 1) - e.radio,
        );
        if (libre(_caja(p), enemigo: true)) {
          pies = p;
          break;
        }
      }
    }
    add(Enemigo(tipo, pies, fuerza: game.fuerzaEnemigos, origen: _origen(e)));
  }

  /// Punto de aparición de [e], para anotar sus caídas: `<zona>#<n>`.
  String _origen(EnemigoMapa e) => '$zonaId#${mapa.enemigos.indexOf(e)}';

  /// Mientras el jugador está en el mundo llegan criaturas nuevas a puntos
  /// alejados de él, cada vez más seguido según su nivel. El punto se elige
  /// al azar según [UmbralJuego.pesoRefuerzo]: casi siempre llegan débiles.
  void _refuerzos(double dt) {
    _esperaRefuerzo -= dt;
    if (_esperaRefuerzo > 0) return;
    _esperaRefuerzo = game.intervaloRefuerzos;
    if (enemigosVivos.length >= _maximoVivos) return;
    final pies = game.jugador.position;
    final lejanos = mapa.enemigos
        .where((e) => MapaMundo.piesEnCelda(e.x, e.y).distanceTo(pies) > 180)
        .toList();
    final pesos = [for (final e in lejanos) game.pesoRefuerzo(e.tipo)];
    final total = pesos.fold(0, (a, b) => a + b);
    if (total == 0) return;
    var tirada = _azar.nextInt(total);
    for (var i = 0; i < lejanos.length; i++) {
      tirada -= pesos[i];
      if (tirada < 0) {
        _aparecer(lejanos[i]);
        return;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _avisoReja = max(0, _avisoReja - dt);
    for (final c in mapa.cofres) {
      if (c.requiere != null &&
          !_cofresMostrados.contains(c) &&
          _cofreVisible(c)) {
        _cofresMostrados.add(c);
        _ponerCofre(c);
      }
    }
    for (var i = 0; i < _fogatas.length; i++) {
      final f = _fogatas[i];
      final encendida =
          game.fogataEncendida(UmbralJuego.fogataAltar(zonaId, i));
      f.luz.encendida = f.brasas.encendida = encendida;
      f.sprite.paint.colorFilter = encendida ? null : filtroApagada;
    }
    if (identical(game.zona, this) && game.jugador.vivo) _refuerzos(dt);
    final pies = game.jugador.position;

    // Al acercarse a un letrero se lee una vez, hasta alejarse de él.
    final cerca = mapa.letreros
        .where((l) => MapaMundo.piesEnCelda(l.x, l.y).distanceTo(pies) < 24)
        .firstOrNull;
    if (cerca != null && cerca != _letreroLeido) game.mostrarAviso(cerca.texto);
    if (cerca != null) {
      _letreroLeido = cerca;
    } else if (_letreroLeido case final l?
        when MapaMundo.piesEnCelda(l.x, l.y).distanceTo(pies) > 48) {
      _letreroLeido = null;
    }
  }

  /// Pisar la casilla de salida lleva a la zona siguiente; la de entrada, de
  /// vuelta a la anterior. Los pasos del borde miden dos o tres casillas.
  @override
  void pisando(Vector2 pies) {
    final tx = pies.x ~/ _lado, ty = (pies.y - 1) ~/ _lado;
    bool en(Paso p) => p.x == 0 || p.x == mapa.ancho - 1
        ? tx == p.x && (ty - p.y).abs() <= 1
        : ty == p.y && (tx - p.x).abs() <= 1;
    if (mapa.salida case final s? when en(s)) {
      game.cruzarFrontera(s.zona, adelante: true);
    } else if (mapa.entrada case final e? when en(e)) {
      game.cruzarFrontera(e.zona, adelante: false);
    }
  }

  @override
  List<AccionContexto> accionesEn(Vector2 pies) {
    final altar = altarCerca(pies);
    if (altar != null) {
      return game.accionesFogata(
        UmbralJuego.fogataAltar(zonaId, altar),
        donde: _fogatas[altar].brasas.position,
        descansar: () => game.descansar(altar: altar),
      );
    }
    if (_palancaCerca(pies) case final m?) {
      return [
        AccionContexto(
          'Accionar la palanca',
          () => _accionarPalanca(m),
          boton: 'abrir',
        ),
      ];
    }
    for (final (punto, sala) in puertas) {
      if (punto.distanceTo(pies) < _distanciaPuerta) {
        return [AccionContexto('Entrar', () => game.entrar(sala, punto))];
      }
    }
    for (final c in mapa.cofres) {
      if (MapaMundo.centroDe(c.x, c.y).distanceTo(pies) < _distanciaObjeto &&
          _cofreVisible(c) &&
          !game.cofreAbierto(idCofre(c))) {
        return [
          AccionContexto('Abrir el cofre', () => _abrirCofre(c), boton: 'abrir'),
        ];
      }
    }
    if (_objetoCerca(pies, 'zarza') case (final x, final y)) {
      return [
        AccionContexto(
          'Cortar la zarza',
          () => _cortarZarza(x, y),
          boton: 'abrir',
        ),
      ];
    }
    if (_objetoCerca(pies, 'reja') case (final x, final y)) {
      return [
        AccionContexto(
          'Examinar la reja',
          () => _examinarReja(x, y),
          boton: 'leer',
        ),
      ];
    }
    return const [];
  }

  /// La celda más cercana a [pies] con el objeto [nombre], si está a mano.
  (int, int)? _objetoCerca(Vector2 pies, String nombre) {
    final o = mapa.objeto(nombre);
    if (o < 0) return null;
    final cx = pies.x ~/ _lado, cy = (pies.y - 1) ~/ _lado;
    (int, int)? mejor;
    var distancia = _distanciaObjeto;
    for (var y = max(0, cy - 2); y <= min(mapa.alto - 1, cy + 2); y++) {
      for (var x = max(0, cx - 2); x <= min(mapa.ancho - 1, cx + 2); x++) {
        if (mapa.objetos[y][x] != o) continue;
        final d = MapaMundo.centroDe(x, y).distanceTo(pies);
        if (d < distancia) {
          distancia = d;
          mejor = (x, y);
        }
      }
    }
    return mejor;
  }

  void _abrirCofre(CofreMapa c) {
    final id = idCofre(c);
    if (game.cofreAbierto(id)) return;
    final oro = switch (c.contenido) {
      'oro' => int.tryParse(
            RegExp(r'(\d+) de oro').firstMatch(c.texto)?.group(1) ?? '',
          ) ??
          0,
      _ => 0,
    };
    game.abrirCofre(id, c.texto, oro: oro, curar: c.contenido == 'pocion-vida');
    _ponerCofre(c);
    if (c.contenido.startsWith('llave')) abrirCerrojos();
  }

  /// Corta la zarza de (x, y) y las que la tocan: una mata entera de un tajo.
  void _cortarZarza(int x, int y) {
    final zarza = mapa.objeto('zarza'), cortada = mapa.objeto('zarza-cortada');
    final pendientes = [(x, y)];
    while (pendientes.isNotEmpty) {
      final (cx, cy) = pendientes.removeLast();
      if (cx < 0 || cy < 0 || cx >= mapa.ancho || cy >= mapa.alto) continue;
      if (mapa.objetos[cy][cx] != zarza) continue;
      _cambiar(cx, cy, cortada);
      pendientes.addAll([(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]);
    }
    game.cortarZarza(MapaMundo.centroDe(x, y));
  }

  void _examinarReja(int x, int y) {
    if (_avisoReja > 0) return;
    _avisoReja = 1;
    final deSalida = mapa.salida?.rejas.contains((x, y)) ?? false;
    game.mostrarAviso(
      deSalida
          ? 'La reja no cede. Algo la sostiene desde la arena.'
          : 'La reja está cerrada. La llave debe de estar en algún cofre de '
                'la zona.',
    );
  }

  /// [pies] es la caja de colisión. Las criaturas pasan por donde el jugador.
  @override
  bool libre(Rect pies, {bool enemigo = false}) {
    for (final esquina in [
      pies.topLeft,
      pies.topRight,
      pies.bottomLeft,
      pies.bottomRight,
    ]) {
      if (mapa.solido(esquina.dx, esquina.dy)) return false;
    }
    for (final o in _obstaculos) {
      if (o.overlaps(pies)) return false;
    }
    return true;
  }

  /// Para proyectiles: chocan con muros, árboles, estructuras y el borde.
  @override
  bool bloquea(double x, double y) => mapa.bloqueaProyectil(x, y);

  /// El altar junto al que está [pies], por su número, o `null`.
  int? altarCerca(Vector2 pies) {
    for (var i = 0; i < altares.length; i++) {
      if (pies.distanceTo(altares[i]) < 42) return i;
    }
    return null;
  }

  bool cercaDelAltar(Vector2 pies) => altarCerca(pies) != null;
}

/// Las hojas extra del tileset (`docs/graficos.md`).
class _Extra {
  const _Extra({
    required this.variantes,
    required this.bordes,
    required this.animados,
  });

  /// Una fila por suelo y cuatro variantes; la 0 es la del tileset.
  final Image variantes;

  /// Una fila por suelo con lo que derrama sobre sus vecinos (N, S, O, E y
  /// las cuatro esquinas) y una última fila con la orilla del agua.
  final Image bordes;

  /// Filas de cuatro cuadros: ondas del agua, pasto alto, pino, árbol seco y
  /// zarza.
  final Image animados;
}

/// Qué suelo se derrama sobre cuál en los bordes: el de número mayor cubre
/// el filo del menor. Los que no están no se mezclan (muros, puentes).
const _precedencia = {
  'agua': 0,
  'pasarela-hundida': 0,
  'adoquin': 1,
  'losa-cripta': 1,
  'camino': 2,
  'tierra-tumba': 3,
  'suelo-bosque': 4,
  'pasto': 5,
  'pasto-hierba': 5,
};
const _muros = {'muro-roca', 'muro-agrietado', 'hueco'};
const _aguas = {'agua', 'pasarela-hundida'};

/// Objetos altos que echan sombra al pie, con su medio ancho en píxeles.
const _sombraObjeto = {
  'pino': 6,
  'arbol-seco': 5,
  'roca': 6,
  'piedra-sellada': 6,
  'palanca': 5,
  'palanca-activa': 5,
};

/// Filas de `-animados.png`.
const _filaOndas = 0;
const _filaPastoAlto = 1;
const _filasMecidas = {'pino': 2, 'arbol-seco': 3, 'zarza': 4};

/// Lados en el orden de las columnas de `-bordes.png`: (columna, dx, dy).
const _lados = [(0, 0, -1), (1, 0, 1), (2, -1, 0), (3, 1, 0)];

/// Esquinas: (columna, dx, dy, lado vertical, lado horizontal).
const _esquinas = [
  (4, -1, -1, 0, 2),
  (5, 1, -1, 0, 3),
  (6, -1, 1, 1, 2),
  (7, 1, 1, 1, 3),
];

/// Cuál de las cuatro variantes lleva la celda (x, y): la base algo más de
/// la mitad de las veces. Siempre la misma para la misma celda.
int varianteDe(int x, int y) {
  final k = (x * 7919 + y * 104729 + x * y * 31) % 100;
  return k < 52
      ? 0
      : k < 68
      ? 1
      : k < 84
      ? 2
      : 3;
}

/// El reloj del viento que mece pasto y árboles: lo avanza [_Animados].
double _viento = 0;

/// Suelo y objetos bajos (escombros, zarza cortada...), dibujados una vez en
/// una imagen del tamaño del mapa: cada celda con su variante, los bordes que
/// le derraman sus vecinos, la orilla si es agua, la corona y la cara del
/// acantilado si es muro, y las sombras de muros, árboles y estructuras. Las
/// celdas que cambian después (una pasarela que sube, un muro roto) se
/// pintan encima cada cuadro, con sus vecinas.
class _Suelo extends PositionComponent {
  _Suelo(this._mapa, this._tileset, this._extra) : super(priority: -1 << 20) {
    final mapa = _mapa;
    final n = mapa.nombresSuelo;
    _filaOrilla = n.length;
    _filaMuro = n.indexOf('muro-roca');
    _pastoAlto = mapa.objeto('pasto-alto');
    _sombras = {
      for (final MapEntry(:key, :value) in _sombraObjeto.entries)
        if (mapa.objeto(key) >= 0) mapa.objeto(key): value,
    };
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    for (var y = 0; y < mapa.alto; y++) {
      for (var x = 0; x < mapa.ancho; x++) {
        _pintarCelda(canvas, x, y);
      }
    }
    // Las estructuras se asientan con una sombra a lo ancho de su base.
    for (final e in mapa.estructuras) {
      final base = (e.y + e.h) * _lado;
      _elipse(canvas, (e.x + e.w / 2) * _lado, base - 1, e.w * _lado / 2 + 2, 3);
    }
    _imagen = grabadora.endRecording().toImageSync(
      mapa.anchoPx.toInt(),
      mapa.altoPx.toInt(),
    );
  }

  final MapaMundo _mapa;
  final Image _tileset;
  final _Extra _extra;
  late final int _filaOrilla, _filaMuro, _pastoAlto;
  late final Map<int, int> _sombras;
  late final Image _imagen;
  final Set<(int, int)> _repintadas = {};
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;
  static final _sombra = Paint()..isAntiAlias = false;

  /// Vuelve a pintar la celda (x, y) y sus vecinas con su suelo y su objeto
  /// bajo de ahora: los bordes y las sombras cambian con ella.
  void repintar(int x, int y) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final vx = x + dx, vy = y + dy;
        if (vx >= 0 && vy >= 0 && vx < _mapa.ancho && vy < _mapa.alto) {
          _repintadas.add((vx, vy));
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawImage(_imagen, Offset.zero, _pintura);
    for (final (x, y) in _repintadas) {
      _pintarCelda(canvas, x, y);
    }
  }

  String? _nombre(int x, int y) {
    if (x < 0 || y < 0 || x >= _mapa.ancho || y >= _mapa.alto) return null;
    return _mapa.nombresSuelo[_mapa.suelo[y][x]];
  }

  void _hoja(Canvas canvas, Image hoja, int columna, int fila, int x, int y) =>
      canvas.drawImageRect(
        hoja,
        Rect.fromLTWH(columna * _lado, fila * _lado, _lado, _lado),
        Rect.fromLTWH(x * _lado, y * _lado, _lado, _lado),
        _pintura,
      );

  void _pintarCelda(Canvas canvas, int x, int y) {
    final mapa = _mapa;
    final s = mapa.suelo[y][x];
    final nombre = mapa.nombresSuelo[s];
    _hoja(canvas, _extra.variantes, varianteDe(x, y), s, x, y);

    if (_aguas.contains(nombre)) {
      // Sombra de la ribera y espuma donde el agua toca tierra.
      for (final (col, dx, dy) in _lados) {
        final v = _nombre(x + dx, y + dy);
        if (v != null && !_aguas.contains(v) && v != 'puente') {
          _hoja(canvas, _extra.bordes, col, _filaOrilla, x, y);
        }
      }
    }

    if (_precedencia[nombre] case final p?) {
      // Los suelos de más precedencia derraman su filo sobre esta celda.
      for (final (col, dx, dy) in _lados) {
        final v = _nombre(x + dx, y + dy);
        final pv = _precedencia[v];
        if (pv != null && pv > p) {
          _hoja(canvas, _extra.bordes, col, mapa.nombresSuelo.indexOf(v!), x, y);
        }
      }
      for (final (col, dx, dy, a, b) in _esquinas) {
        final v = _nombre(x + dx, y + dy);
        final pv = _precedencia[v];
        if (pv == null || pv <= p) continue;
        final va = _precedencia[_nombre(x + _lados[a].$2, y + _lados[a].$3)] ?? -1;
        final vb = _precedencia[_nombre(x + _lados[b].$2, y + _lados[b].$3)] ?? -1;
        if (va < pv && vb < pv) {
          _hoja(canvas, _extra.bordes, col, mapa.nombresSuelo.indexOf(v!), x, y);
        }
      }
    }

    if (_muros.contains(nombre)) {
      // Donde termina la roca: corona arriba, cara de acantilado abajo.
      bool fuera(int dx, int dy) {
        final v = _nombre(x + dx, y + dy);
        return v != null && !_muros.contains(v);
      }
      for (final (col, dx, dy) in _lados) {
        if (fuera(dx, dy)) _hoja(canvas, _extra.bordes, col, _filaMuro, x, y);
      }
      for (final (col, _, _, a, b) in _esquinas) {
        if (fuera(_lados[a].$2, _lados[a].$3) && fuera(_lados[b].$2, _lados[b].$3)) {
          _hoja(canvas, _extra.bordes, col, _filaMuro, x, y);
        }
      }
    } else {
      // El muro de arriba echa sombra sobre esta celda; los de los lados,
      // un filo oscuro.
      if (_muros.contains(_nombre(x, y - 1))) {
        for (final (k, a) in const [(0, 0.42), (1, 0.28), (2, 0.16), (3, 0.07)]) {
          _sombra.color = Colores.abismo.withValues(alpha: a);
          canvas.drawRect(
            Rect.fromLTWH(x * _lado, y * _lado + k, _lado, 1),
            _sombra,
          );
        }
      }
      _sombra.color = Colores.abismo.withValues(alpha: 0.2);
      if (_muros.contains(_nombre(x - 1, y))) {
        canvas.drawRect(Rect.fromLTWH(x * _lado, y * _lado, 1, _lado), _sombra);
      }
      if (_muros.contains(_nombre(x + 1, y))) {
        canvas.drawRect(
          Rect.fromLTWH(x * _lado + _lado - 1, y * _lado, 1, _lado),
          _sombra,
        );
      }
    }

    final o = mapa.objetos[y][x];
    if (_sombras[o] case final r?) {
      _elipse(canvas, x * _lado + 8, y * _lado + 14, r.toDouble(), 2);
    }
    // El pasto alto lo mece [_Animados]; el resto de objetos bajos va aquí.
    if (o >= 0 && !mapa.objetosAltos.contains(o) && o != _pastoAlto) {
      _tile(canvas, _tileset, mapa, mapa.indiceObjetos + o, x, y, _pintura);
    }
  }

  /// Sombra ovalada de píxeles: tres filas, la del medio la más ancha.
  static void _elipse(Canvas canvas, double cx, double cy, double rx, double ry) {
    _sombra.color = Colores.abismo.withValues(alpha: 0.32);
    for (var fila = -ry; fila <= ry; fila++) {
      final k = sqrt(max(0.0, 1 - (fila / (ry + 0.5)) * (fila / (ry + 0.5))));
      final media = (rx * k).roundToDouble();
      canvas.drawRect(
        Rect.fromLTWH((cx - media).roundToDouble(), (cy + fila).roundToDouble(), media * 2, 1),
        _sombra,
      );
    }
  }
}

/// Lo que se mueve en el suelo: ondas en el agua y pasto alto que se mece.
/// Solo dibuja las celdas a la vista.
class _Animados extends PositionComponent with HasGameReference<UmbralJuego> {
  _Animados(this._mapa, this._hoja) : super(priority: -(1 << 20) + 1) {
    _agua = _mapa.nombresSuelo.indexOf('agua');
    _pastoAlto = _mapa.objeto('pasto-alto');
  }

  final MapaMundo _mapa;
  final Image _hoja;
  late final int _agua, _pastoAlto;
  double _t = 0;
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void update(double dt) {
    _t += dt;
    _viento += dt;
  }

  @override
  void render(Canvas canvas) {
    final vista = game.camera.visibleWorldRect;
    final x0 = max(0, (vista.left / _lado).floor());
    final y0 = max(0, (vista.top / _lado).floor());
    final x1 = min(_mapa.ancho - 1, (vista.right / _lado).floor());
    final y1 = min(_mapa.alto - 1, (vista.bottom / _lado).floor());
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        if (_mapa.suelo[y][x] == _agua) {
          // Cada celda a su ritmo, para que el lago no lata entero a la vez.
          final cuadro = ((_t * 2.2).floor() + x * 3 + y * 5) % 4;
          _dibujar(canvas, cuadro, _filaOndas, x, y);
        }
        if (_pastoAlto >= 0 && _mapa.objetos[y][x] == _pastoAlto) {
          _dibujar(canvas, cuadroMecido(x, y), _filaPastoAlto, x, y);
        }
      }
    }
  }

  void _dibujar(Canvas canvas, int columna, int fila, int x, int y) =>
      canvas.drawImageRect(
        _hoja,
        Rect.fromLTWH(columna * _lado, fila * _lado, _lado, _lado),
        Rect.fromLTWH(x * _lado, y * _lado, _lado, _lado),
        _pintura,
      );
}

/// Cuadro (0 a 3) de algo que mece el viento en la celda (x, y): las ráfagas
/// cruzan el mapa de oeste a este.
int cuadroMecido(int x, int y) =>
    ((_viento * 2.4 - x * 0.45 - y * 0.15).floor()) % 4;

/// Árboles, rocas, cercas, rejas, cofres y letreros de una fila del mapa.
/// Comparte orden con los sprites según su base: el jugador pasa por detrás o
/// delante. Lo que se abre o se corta cambia aquí su cuadro. Pinos, árboles
/// secos y zarzas se mecen con el viento.
class _FilaAlta extends PositionComponent with HasGameReference<UmbralJuego> {
  _FilaAlta(this._mapa, this._tileset, this._animados, this._fila)
    : super(priority: ((_fila + 1) * _lado).round()) {
    _mecidos = {
      for (final MapEntry(:key, :value) in _filasMecidas.entries)
        if (_mapa.objeto(key) >= 0) _mapa.indiceObjetos + _mapa.objeto(key): value,
    };
  }

  final MapaMundo _mapa;
  final Image _tileset;
  final Image _animados;
  final int _fila;
  late final Map<int, int> _mecidos;

  /// Cuadro del tileset en cada columna que tiene algo.
  final Map<int, int> _celdas = {};
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  void poner(int x, int cuadro) => _celdas[x] = cuadro;

  @override
  void render(Canvas canvas) {
    final vista = game.camera.visibleWorldRect;
    final y = _fila * _lado;
    if (y > vista.bottom || y + _lado < vista.top) return;
    for (final MapEntry(key: x, value: cuadro) in _celdas.entries) {
      if (x * _lado > vista.right || (x + 1) * _lado < vista.left) continue;
      if (_mecidos[cuadro] case final fila?) {
        canvas.drawImageRect(
          _animados,
          Rect.fromLTWH(cuadroMecido(x, _fila) * _lado, fila * _lado, _lado, _lado),
          Rect.fromLTWH(x * _lado, y, _lado, _lado),
          _pintura,
        );
      } else {
        _tile(canvas, _tileset, _mapa, cuadro, x, _fila, _pintura);
      }
    }
  }
}

void _tile(
  Canvas canvas,
  Image tileset,
  MapaMundo mapa,
  int cuadro,
  int x,
  int y,
  Paint pintura,
) {
  final columnas = mapa.columnasTileset;
  canvas.drawImageRect(
    tileset,
    Rect.fromLTWH(
      (cuadro % columnas) * _lado,
      (cuadro ~/ columnas) * _lado,
      _lado,
      _lado,
    ),
    Rect.fromLTWH(x * _lado, y * _lado, _lado, _lado),
    pintura,
  );
}

/// Chispas del altar: la luz cálida marca un lugar que vale la pena visitar.
/// Suben meciéndose, pasan de amarillo a rojo y se apagan en ceniza; brillan
/// sobre la oscuridad. De vez en cuando sueltan una brasa a las partículas
/// del lugar, que vuela más lejos.
class _Brasas extends PositionComponent with HasGameReference<UmbralJuego>, Brilla {
  _Brasas(Vector2 posicion) : super(position: posicion, priority: 1 << 19);

  final _azar = Random();
  final List<(Vector2, double)> _chispas = [];
  double _t = 0;
  double _reloj = 0;

  /// Apagado no echa chispas nuevas; las que había se apagan solas.
  bool encendida = true;

  static const _vida = 1.1;

  @override
  void update(double dt) {
    _t += dt;
    _reloj += dt;
    if (_reloj > 0.07 && encendida) {
      _reloj = 0;
      _chispas.add((Vector2((_azar.nextDouble() - 0.5) * 7, 0), 0));
      if (_azar.nextDouble() < 0.12) {
        (parent as Escenario?)?.particulas?.brasas(position.clone(), ancho: 4);
      }
    }
    for (var i = 0; i < _chispas.length; i++) {
      final (p, edad) = _chispas[i];
      p.y -= (16 - edad * 6) * dt;
      p.x += sin(_t * 5 + p.y * 0.4) * 4 * dt;
      _chispas[i] = (p, edad + dt);
    }
    _chispas.removeWhere((c) => c.$2 > _vida);
  }

  static const _colores = [
    Color(0xFFF2C14E),
    Colores.brasa,
    Colores.brasa,
    Colores.sangre,
    Colores.ceniza,
  ];

  @override
  void pintarBrillo(Canvas canvas) {
    for (final (p, edad) in _chispas) {
      final k = edad / _vida;
      puntoBrillante(
        canvas,
        position.x + p.x,
        position.y + p.y,
        _colores[min(_colores.length - 1, (k * _colores.length).floor())],
        k < 0.8 ? 1 : (1 - k) * 5,
      );
    }
  }
}
