import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';

import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'escenario.dart';
import 'iluminacion.dart';
import 'mapa_interiores.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

const _lado = 16.0;

/// Una sala interior (`docs/diseno/interiores.md`). Se crea una vez por sala y
/// se conserva: lo abierto sigue abierto hasta descansar.
class SalaInterior extends Escenario {
  SalaInterior(this.mapa, this.sala) {
    _solido = Uint8List(sala.ancho * sala.alto);
    for (var y = 0; y < sala.alto; y++) {
      for (var x = 0; x < sala.ancho; x++) {
        final o = sala.objetos[y][x];
        if (mapa.sueloBloquea.contains(sala.suelo[y][x]) ||
            (o >= 0 && !mapa.objetosTransitables.contains(o))) {
          _solido[y * sala.ancho + x] = 1;
        }
      }
    }
  }

  final MapaInteriores mapa;
  final Sala sala;
  late final Uint8List _solido;
  final Set<PuntoSala> _abiertos = {};

  static const _distanciaInteraccion = 22.0;

  @override
  Rect get limites =>
      Rect.fromLTWH(0, 0, sala.ancho * _lado, sala.alto * _lado);

  @override
  String regionEn(Vector2 pies) => sala.nombre;

  @override
  Future<void> onLoad() async {
    final tileset =
        game.images.fromCache('interiores/${mapa.tileset}');
    add(_SueloSala(mapa, sala, tileset));
    for (var y = 0; y < sala.alto; y++) {
      add(_FilaSala(mapa, sala, tileset, y));
    }

    final iluminacion = Iluminacion(oscuridad: 0.88);
    void luz(int x, int y, double radio, Color? tinte, {double alto = 4}) =>
        iluminacion.fijas.add(Luz(
            Vector2((x + 0.5) * _lado, (y + 0.5) * _lado - alto),
            radio: radio,
            tinte: tinte,
            parpadeo: tinte == Colores.brasa ? 2 : 0));
    final candelabro = mapa.objeto('candelabro'),
        forja = mapa.objeto('forja'),
        altar = mapa.objeto('altar-brasas'),
        altarCapilla = mapa.objeto('altar-capilla'),
        vitral = mapa.objeto('vitral'),
        salida = mapa.suelo('umbral-salida');
    for (var y = 0; y < sala.alto; y++) {
      for (var x = 0; x < sala.ancho; x++) {
        final o = sala.objetos[y][x];
        if (o == candelabro) luz(x, y, 34, Colores.brasa);
        if (o == forja) luz(x, y, 46, Colores.brasa);
        if (o == altar) luz(x, y, 42, Colores.brasa);
        if (o == altarCapilla) luz(x, y, 26, Colores.brasa);
        if (o == vitral) luz(x, y, 22, Colores.alma);
        if (sala.suelo[y][x] == salida) luz(x, y, 22, null, alto: 0);
      }
    }
    add(iluminacion);
    reiniciarEnemigos();
  }

  @override
  bool libre(Rect pies, {bool enemigo = false}) {
    for (final esquina in [
      pies.topLeft,
      pies.topRight,
      pies.bottomLeft,
      pies.bottomRight,
    ]) {
      if (bloquea(esquina.dx, esquina.dy)) return false;
    }
    return true;
  }

  @override
  bool bloquea(double x, double y) {
    if (x < 0 || y < 0) return true;
    final tx = x ~/ _lado, ty = y ~/ _lado;
    if (tx >= sala.ancho || ty >= sala.alto) return true;
    return _solido[ty * sala.ancho + tx] == 1;
  }

  @override
  void reiniciarEnemigos() {
    _abiertos.clear();
    for (final e in children.whereType<Enemigo>().toList()) {
      e.removeFromParent();
    }
    for (final c in children.whereType<Proyectil>().toList()) {
      c.removeFromParent();
    }
    // El Rey Hueco espera delante de su trono.
    if (sala.punto('jefe') case final p?) {
      add(Enemigo(Enemigos.reyHueco, piesEn(p.x, p.y)));
    }
  }

  /// Pies de alguien de pie en la celda (x, y).
  static Vector2 piesEn(int x, int y) =>
      Vector2((x + 0.5) * _lado, (y + 1) * _lado - 3);

  /// Dónde aparece el jugador al llegar por el punto [tipo] (`salida` o
  /// `bajada`): en la fila contigua, del lado de dentro de la sala.
  Vector2 llegada(String tipo) {
    final p = sala.punto(tipo)!;
    final (desde, hasta) = _tramo(p);
    final fila = p.y >= sala.alto - 1 ? p.y - 1 : p.y + 1;
    return Vector2((desde + hasta + 1) / 2 * _lado, (fila + 1) * _lado - 3);
  }

  /// Celdas contiguas de la fila de [p] con el mismo suelo: una salida o una
  /// escalera pueden medir dos tiles.
  (int, int) _tramo(PuntoSala p) {
    final tile = sala.suelo[p.y][p.x];
    var desde = p.x, hasta = p.x;
    while (desde > 0 && sala.suelo[p.y][desde - 1] == tile) {
      desde--;
    }
    while (hasta < sala.ancho - 1 && sala.suelo[p.y][hasta + 1] == tile) {
      hasta++;
    }
    return (desde, hasta);
  }

  @override
  void pisando(Vector2 pies) {
    final tx = pies.x ~/ _lado, ty = (pies.y - 1) ~/ _lado;
    for (final p in sala.puntos) {
      if (p.tipo != 'salida' && p.tipo != 'bajada') continue;
      final (desde, hasta) = _tramo(p);
      if (ty == p.y && tx >= desde && tx <= hasta) {
        game.cruzar(this, p.tipo);
        return;
      }
    }
  }

  @override
  List<AccionContexto> accionesEn(Vector2 pies) {
    PuntoSala? cerca;
    var mejor = _distanciaInteraccion;
    for (final p in sala.puntos) {
      final d = Vector2((p.x + 0.5) * _lado, (p.y + 0.5) * _lado)
          .distanceTo(pies);
      if (d < mejor) {
        mejor = d;
        cerca = p;
      }
    }
    return switch (cerca?.tipo) {
      'herreria' => [
          AccionContexto('Usar el yunque',
              () => game.abrirPantalla(PantallaJuego.herreria),
              icono: 'yunque', estilo: EstiloBoton.acento),
        ],
      'estadisticas' => [game.accionSubirNivel(icono: 'altar')],
      'cofre' => [
          AccionContexto(
              _abiertos.contains(cerca) ? 'Cofre vacío' : 'Abrir el cofre',
              () => _abrirCofre(cerca!),
              icono: 'mochila'),
        ],
      'secreto' => [
          AccionContexto('Examinar',
              () => game.mostrarAviso('La trampilla está atrancada desde abajo.'),
              icono: 'candado'),
        ],
      'subida' => [
          AccionContexto(
              'Subir',
              () => game.mostrarAviso(
                  'La escalera al mirador se derrumbó a mitad de camino.'),
              icono: 'candado'),
        ],
      _ => const [],
    };
  }

  void _abrirCofre(PuntoSala p) {
    if (_abiertos.contains(p)) {
      game.mostrarAviso('Ya no queda nada. Vuelve después de descansar.');
      return;
    }
    _abiertos.add(p);
    // No hay objetos que llevarse: el arma es lo único que se porta.
    if (sala.slug == 'choza-en-ruinas') {
      game.curar('Bebes las pociones del cofre. Tu vida se renueva.');
    } else {
      game.mostrarAviso('El cofre está vacío. Alguien llegó antes.');
    }
  }
}

/// Suelo, muros y objetos de paso, dibujados una vez en una imagen.
class _SueloSala extends PositionComponent {
  _SueloSala(MapaInteriores mapa, Sala sala, Image tileset)
      : super(priority: -1 << 20) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    for (var y = 0; y < sala.alto; y++) {
      for (var x = 0; x < sala.ancho; x++) {
        _tile(canvas, tileset, mapa, sala.suelo[y][x], x, y);
        final o = sala.objetos[y][x];
        if (o >= 0 && mapa.objetosTransitables.contains(o)) {
          _tile(canvas, tileset, mapa, mapa.indiceObjetos + o, x, y);
        }
      }
    }
    _imagen = grabadora.endRecording().toImageSync(
        (sala.ancho * _lado).toInt(), (sala.alto * _lado).toInt());
  }

  late final Image _imagen;

  @override
  void render(Canvas canvas) =>
      canvas.drawImage(_imagen, Offset.zero, _pintura);
}

/// Muebles de una fila: se ordenan con los sprites según su base.
class _FilaSala extends PositionComponent {
  _FilaSala(this._mapa, Sala sala, this._tileset, this._fila)
      : super(priority: ((_fila + 1) * _lado).round()) {
    for (var x = 0; x < sala.ancho; x++) {
      final o = sala.objetos[_fila][x];
      if (o >= 0 && !_mapa.objetosTransitables.contains(o)) {
        _celdas.add((x, _mapa.indiceObjetos + o));
      }
    }
  }

  final MapaInteriores _mapa;
  final Image _tileset;
  final int _fila;
  final List<(int, int)> _celdas = [];

  @override
  void render(Canvas canvas) {
    for (final (x, cuadro) in _celdas) {
      _tile(canvas, _tileset, _mapa, cuadro, x, _fila);
    }
  }
}

final _pintura = Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

void _tile(Canvas canvas, Image tileset, MapaInteriores mapa, int cuadro,
    int x, int y) {
  final columnas = mapa.columnasTileset;
  canvas.drawImageRect(
    tileset,
    Rect.fromLTWH((cuadro % columnas) * _lado, (cuadro ~/ columnas) * _lado,
        _lado, _lado),
    Rect.fromLTWH(x * _lado, y * _lado, _lado, _lado),
    _pintura,
  );
}
