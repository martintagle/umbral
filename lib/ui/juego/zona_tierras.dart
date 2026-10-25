import 'dart:math';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'iluminacion.dart';
import 'mapa_mundo.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

const _lado = MapaMundo.tile;

/// Tierras del Umbral, la primera zona: el mapa de `assets/mapas/mundo.json`
/// en plena noche. Las coordenadas están en píxeles de arte desde la esquina
/// superior izquierda del mapa.
class ZonaTierras extends World with HasGameReference<UmbralJuego> {
  static const id = 'tierras-del-umbral';
  static const puntoDeGuardado = 'altar-de-brasas';

  /// Antorchas repartidas por los caminos, en tiles.
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
  late final Rect limites;
  late final Vector2 posicionAltar;
  final List<Rect> _obstaculos = [];
  Letrero? _letreroLeido;

  Vector2 get inicio => mapa.inicio;

  Iterable<Enemigo> get enemigosVivos =>
      children.whereType<Enemigo>().where((e) => e.vivo);

  /// Lo llama el juego al cargar, antes de colocar al jugador: así las
  /// colisiones ya existen cuando se comprueba la posición guardada.
  void preparar(MapaMundo mapa, Images imagenes) {
    final tileset = imagenes.fromCache('tiles/tileset.png');
    this.mapa = mapa;
    limites = Rect.fromLTWH(0, 0, mapa.anchoPx, mapa.altoPx);
    final iluminacion = Iluminacion();
    _obstaculos.clear();

    add(_Suelo(mapa, tileset));
    for (var y = 0; y < mapa.alto; y++) {
      add(_FilaAlta(mapa, tileset, y));
    }

    for (final e in mapa.estructuras) {
      final imagen = imagenes.fromCache('sprites/estructuras/${e.sprite}.png');
      final base = (e.y + e.h) * _lado;
      add(SpriteComponent(
        sprite: Sprite(imagen),
        position: Vector2(
            (e.x * _lado + (e.w * _lado - imagen.width) / 2).roundToDouble(),
            base - imagen.height),
        priority: base.round(),
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      ));
      if (e.sprite == 'altar-de-brasas') {
        posicionAltar = Vector2((e.x + e.w / 2) * _lado, base);
        final fuego = posicionAltar + Vector2(0, -26);
        add(_Brasas(fuego));
        iluminacion.fijas.add(
            Luz(fuego, radio: 48, tinte: Colores.brasa, parpadeo: 2));
      }
    }

    for (final (x, y) in _antorchas) {
      final antorcha = Antorcha(MapaMundo.piesEnCelda(x, y));
      add(antorcha);
      _obstaculos.add(antorcha.huella);
      iluminacion.fijas.add(
          Luz(antorcha.llama, radio: 36, tinte: Colores.brasa, parpadeo: 2));
    }

    // Las runas de los tocones brillan en azul; las ventanas, en ámbar.
    for (final (x, y) in mapa.portales) {
      iluminacion.fijas.add(Luz(Vector2((x + 0.5) * _lado, (y + 0.5) * _lado),
          radio: 24, tinte: Colores.alma, parpadeo: 1));
    }
    for (final p in [
      Vector2(626, 264), // campanario de la capilla
      Vector2(950, 274), // farol del árbol de la jaula
      Vector2(504, 633), // ventana de la torre derruida
    ]) {
      iluminacion.fijas
          .add(Luz(p, radio: 20, tinte: Colores.brasa, parpadeo: 1));
    }
    add(iluminacion);

    reiniciarEnemigos();
  }

  /// Quita a todos los enemigos y los vuelve a poner en su sitio, con la vida
  /// llena. Se usa al descansar y al morir.
  void reiniciarEnemigos() {
    for (final e in children.whereType<Enemigo>().toList()) {
      e.removeFromParent();
    }
    for (final c in children.whereType<Proyectil>().toList()) {
      c.removeFromParent();
    }
    for (final e in mapa.enemigos) {
      // El jefe no está en el catálogo del servidor: queda para más adelante.
      final tipo = Enemigos.todos.where((t) => t.id == e.tipo).firstOrNull;
      if (tipo != null) add(Enemigo(tipo, MapaMundo.piesEnCelda(e.x, e.y)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final pies = game.jugador.position;
    game.region.value = mapa.regionEn(pies);

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

  /// [pies] es la caja de colisión; los enemigos además evitan los tocones.
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
  bool bloquea(double x, double y) => mapa.bloqueaProyectil(x, y);

  void limitar(Vector2 p) {
    p.x = p.x.clamp(limites.left + 8, limites.right - 8);
    p.y = p.y.clamp(limites.top + 24, limites.bottom - 4);
  }

  bool cercaDelAltar(Vector2 pies) => pies.distanceTo(posicionAltar) < 42;
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
    _imagen = grabadora
        .endRecording()
        .toImageSync(mapa.anchoPx.toInt(), mapa.altoPx.toInt());
  }

  late final Image _imagen;
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void render(Canvas canvas) => canvas.drawImage(_imagen, Offset.zero, _pintura);
}

/// Árboles, rocas, cercas, cofres y letreros de una fila del mapa. Comparte
/// orden con los sprites según su base: el jugador pasa por detrás o delante.
class _FilaAlta extends PositionComponent with HasGameReference<UmbralJuego> {
  _FilaAlta(this._mapa, this._tileset, this._fila)
      : super(priority: ((_fila + 1) * _lado).round()) {
    final entidades = _mapa.nombresEntidades;
    for (var x = 0; x < _mapa.ancho; x++) {
      final o = _mapa.objetos[_fila][x];
      if (_mapa.objetosAltos.contains(o)) {
        _celdas.add((x, _mapa.indiceObjetos + o));
      }
    }
    for (final (x, y) in _mapa.cofres) {
      if (y == _fila) {
        _celdas.add((x, _mapa.indiceEntidades + entidades.indexOf('cofre')));
      }
    }
    for (final l in _mapa.letreros) {
      if (l.y == _fila) {
        _celdas.add((l.x, _mapa.indiceEntidades + entidades.indexOf('letrero')));
      }
    }
  }

  final MapaMundo _mapa;
  final Image _tileset;
  final int _fila;
  final List<(int, int)> _celdas = [];
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void render(Canvas canvas) {
    final vista = game.camera.visibleWorldRect;
    final y = _fila * _lado;
    if (y > vista.bottom || y + _lado < vista.top) return;
    for (final (x, cuadro) in _celdas) {
      if (x * _lado > vista.right || (x + 1) * _lado < vista.left) continue;
      _tile(canvas, _tileset, _mapa, cuadro, x, _fila, _pintura);
    }
  }
}

void _tile(Canvas canvas, Image tileset, MapaMundo mapa, int cuadro, int x,
    int y, Paint pintura) {
  final columnas = mapa.columnasTileset;
  canvas.drawImageRect(
    tileset,
    Rect.fromLTWH((cuadro % columnas) * _lado, (cuadro ~/ columnas) * _lado, _lado, _lado),
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
