import 'dart:math';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

import '../tema/tema_umbral.dart';
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
  final List<Rect> _obstaculos = [];
  final Map<int, _FilaAlta> _filas = {};
  late final Image _tileset;
  Letrero? _letreroLeido;
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
    this.mapa = mapa;
    limites = Rect.fromLTWH(0, 0, mapa.anchoPx, mapa.altoPx);
    final iluminacion = Iluminacion();
    _obstaculos.clear();
    _ponerPuertas(interiores);

    add(_Suelo(mapa, _tileset));
    for (var y = 0; y < mapa.alto; y++) {
      add(_filas[y] = _FilaAlta(mapa, _tileset, y));
    }
    for (var y = 0; y < mapa.alto; y++) {
      for (var x = 0; x < mapa.ancho; x++) {
        final o = mapa.objetos[y][x];
        if (mapa.objetosAltos.contains(o)) _poner(x, y, mapa.indiceObjetos + o);
      }
    }
    for (final c in mapa.cofres) {
      _ponerCofre(c);
    }
    for (final l in mapa.letreros) {
      _poner(l.x, l.y, _entidad('letrero'));
    }

    for (final e in mapa.estructuras) {
      final imagen = imagenes.fromCache('sprites/estructuras/${e.sprite}.png');
      final base = (e.y + e.h) * _lado;
      add(
        SpriteComponent(
          sprite: Sprite(imagen),
          position: Vector2(
            (e.x * _lado + (e.w * _lado - imagen.width) / 2).roundToDouble(),
            base - imagen.height,
          ),
          priority: base.round(),
          paint: Paint()
            ..filterQuality = FilterQuality.none
            ..isAntiAlias = false,
        ),
      );
      if (e.sprite == 'altar-de-brasas') {
        final altar = Vector2((e.x + e.w / 2) * _lado, base);
        altares.add(altar);
        final fuego = altar + Vector2(0, -26);
        add(_Brasas(fuego));
        iluminacion.fijas.add(
          Luz(fuego, radio: 48, tinte: Colores.brasa, parpadeo: 2),
        );
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

    // Las runas de los tocones brillan en azul.
    for (final (x, y) in mapa.portales) {
      iluminacion.fijas.add(
        Luz(MapaMundo.centroDe(x, y), radio: 24, tinte: Colores.alma, parpadeo: 1),
      );
    }
    add(iluminacion);

    abrirCerrojos();
    reiniciarEnemigos();
  }

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
      final k = usadas.update(e.sprite, (n) => n + 1, ifAbsent: () => 0);
      final Sala? sala;
      if (mapa.jefe case (entrada: final entrada?, mazmorra: final id?, tipo: _)
          when entrada == e.sprite) {
        sala = interiores.mazmorra(id)?.entradas(e.sprite).firstOrNull;
      } else if (mapa.numero > 1 && e.sprite == 'choza-en-ruinas') {
        sala = herreria;
      } else {
        final salas = comunes.entradas(e.sprite);
        sala = k < salas.length ? salas[k] : null;
      }
      if (sala != null) {
        puertas.add((
          Vector2((e.x + e.w / 2) * _lado, (e.y + e.h) * _lado + 3),
          sala,
        ));
      }
    }
  }

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
    for (final e in mapa.enemigos) {
      final n = game.criaturasPorGrupo(e.tipo);
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
    add(Enemigo(tipo, pies, fuerza: game.fuerzaEnemigos));
  }

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
      return [
        AccionContexto(
          'Descansar',
          () => game.descansar(altar: altar),
          boton: 'descansar',
        ),
        game.accionSubirNivel(),
      ];
    }
    for (final (punto, sala) in puertas) {
      if (punto.distanceTo(pies) < _distanciaPuerta) {
        return [AccionContexto('Entrar', () => game.entrar(sala, punto))];
      }
    }
    for (final c in mapa.cofres) {
      if (MapaMundo.centroDe(c.x, c.y).distanceTo(pies) < _distanciaObjeto &&
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

  /// [pies] es la caja de colisión; los enemigos además evitan los tocones.
  @override
  bool libre(Rect pies, {bool enemigo = false}) {
    final solido = enemigo ? mapa.solidoEnemigo : mapa.solido;
    for (final esquina in [
      pies.topLeft,
      pies.topRight,
      pies.bottomLeft,
      pies.bottomRight,
    ]) {
      if (solido(esquina.dx, esquina.dy)) return false;
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

/// Suelo y objetos bajos (troncos, pasto alto, escombros...), dibujados una
/// vez en una imagen del tamaño del mapa.
class _Suelo extends PositionComponent {
  _Suelo(MapaMundo mapa, Image tileset) : super(priority: -1 << 20) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    final pintura = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (var y = 0; y < mapa.alto; y++) {
      for (var x = 0; x < mapa.ancho; x++) {
        _tile(canvas, tileset, mapa, mapa.suelo[y][x], x, y, pintura);
        final o = mapa.objetos[y][x];
        if (o >= 0 && !mapa.objetosAltos.contains(o)) {
          _tile(canvas, tileset, mapa, mapa.indiceObjetos + o, x, y, pintura);
        }
      }
    }
    _imagen = grabadora.endRecording().toImageSync(
      mapa.anchoPx.toInt(),
      mapa.altoPx.toInt(),
    );
  }

  late final Image _imagen;
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void render(Canvas canvas) =>
      canvas.drawImage(_imagen, Offset.zero, _pintura);
}

/// Árboles, rocas, cercas, rejas, cofres y letreros de una fila del mapa.
/// Comparte orden con los sprites según su base: el jugador pasa por detrás o
/// delante. Lo que se abre o se corta cambia aquí su cuadro.
class _FilaAlta extends PositionComponent with HasGameReference<UmbralJuego> {
  _FilaAlta(this._mapa, this._tileset, this._fila)
    : super(priority: ((_fila + 1) * _lado).round());

  final MapaMundo _mapa;
  final Image _tileset;
  final int _fila;

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
      _tile(canvas, _tileset, _mapa, cuadro, x, _fila, _pintura);
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
class _Brasas extends PositionComponent {
  _Brasas(Vector2 posicion) : super(position: posicion, priority: 1 << 19);

  final _azar = Random();
  final List<Vector2> _chispas = [];
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    if (_t > 0.15) {
      _t = 0;
      _chispas.add(Vector2((_azar.nextInt(7) - 3).toDouble(), 0));
    }
    for (final c in _chispas) {
      c.y -= 14 * dt;
    }
    _chispas.removeWhere((c) => c.y < -14);
  }

  @override
  void render(Canvas canvas) {
    for (final c in _chispas) {
      pixel(canvas, c.x, c.y, c.y < -8 ? Colores.ceniza : Colores.brasa);
    }
  }
}
