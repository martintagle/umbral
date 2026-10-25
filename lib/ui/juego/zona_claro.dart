import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

/// Zona de prueba: un claro con un cementerio, una capilla y una aldea en
/// ruinas. Las coordenadas están en píxeles de arte; la entrada es (0, 0).
class ZonaClaro extends World with HasGameReference<UmbralJuego> {
  static const id = 'claro-de-las-lapidas';
  static const nombre = 'El Claro de las Lápidas';
  static const puntoDeGuardado = 'altar-del-claro';
  static const limites = Rect.fromLTRB(-320, -260, 320, 220);

  /// Donde empieza un personaje nuevo (el servidor lo crea en 0,0) y donde
  /// reaparece al morir. El altar queda justo delante, sin que el jugador lo tape.
  static final Vector2 entrada = Vector2.zero();
  static final Vector2 posicionAltar = Vector2(0, -36);

  final List<Rect> _obstaculos = [];

  Iterable<Enemigo> get enemigosVivos =>
      children.whereType<Enemigo>().where((e) => e.vivo);

  static const _estructuras = <(String, double, double, double, double)>[
    // (sprite, x, y, ancho de la base, alto de la base)
    ('altar-de-brasas', 0, -36, 24, 8),
    ('pozo', -84, -52, 26, 10),
    ('estatua-sin-rostro', 64, -64, 18, 8),
    ('capilla', 0, -176, 60, 22),
    ('lapidas', 130, -92, 28, 8),
    ('lapidas', 168, -66, 28, 8),
    ('lapidas', 140, -36, 28, 8),
    ('lapidas', 190, -118, 28, 8),
    ('lapidas', 104, -128, 28, 8),
    ('choza-en-ruinas', -196, -112, 56, 18),
    ('torre-derruida', 230, 132, 40, 16),
    ('arbol-de-la-jaula', -214, 144, 14, 8),
    ('lapidas', -170, 176, 28, 8),
    ('entrada-de-cripta', 244, -206, 56, 14),
  ];

  static final _enemigos = <(TipoEnemigo, double, double)>[
    (Enemigos.ojoErrante, -140, -8),
    (Enemigos.ojoErrante, -112, 64),
    (Enemigos.fauce, 154, -16),
    (Enemigos.fauce, 206, -156),
    (Enemigos.polillaOsaria, 92, 124),
    (Enemigos.polillaOsaria, -62, 164),
    (Enemigos.larvaCirio, -76, -196),
    (Enemigos.manojo, 182, 176),
    (Enemigos.ahorcadoFungico, -236, 64),
  ];

  @override
  Future<void> onLoad() async {
    add(_Suelo());
    for (final (nombre, x, y, ancho, alto) in _estructuras) {
      final sprite = Sprite(game.images.fromCache('sprites/estructuras/$nombre.png'));
      add(SpriteComponent(
        sprite: sprite,
        position: Vector2(x, y),
        anchor: Anchor.bottomCenter,
        priority: y.round(),
        paint: Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false,
      ));
      _obstaculos.add(Rect.fromLTWH(x - ancho / 2, y - alto, ancho, alto));
    }
    add(_Brasas(posicionAltar + Vector2(0, -26)));
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
    for (final (tipo, x, y) in _enemigos) {
      add(Enemigo(tipo, Vector2(x, y)));
    }
  }

  bool libre(Rect pies) {
    if (!limites.deflate(4).contains(pies.topLeft) ||
        !limites.deflate(4).contains(pies.bottomRight)) {
      return false;
    }
    for (final o in _obstaculos) {
      if (o.overlaps(pies)) return false;
    }
    return true;
  }

  /// Para proyectiles: choca con la base de las estructuras y con el borde.
  bool bloquea(double x, double y) {
    if (!limites.contains(Offset(x, y))) return true;
    for (final o in _obstaculos) {
      if (o.contains(Offset(x, y))) return true;
    }
    return false;
  }

  void limitar(Vector2 p) {
    p.x = p.x.clamp(limites.left + 8, limites.right - 8);
    p.y = p.y.clamp(limites.top + 24, limites.bottom - 4);
  }

  bool cercaDelAltar(Vector2 pies) => pies.distanceTo(posicionAltar) < 42;
}

/// Suelo de tierra y musgo, generado una vez y guardado como imagen.
class _Suelo extends PositionComponent {
  _Suelo() : super(priority: -1 << 20);

  late final Picture _imagen;

  static const _tierra = [
    Color(0xFF1C1820),
    Color(0xFF1F1A23),
    Color(0xFF19151C),
    Color(0xFF221C26),
  ];
  static const _camino = [Color(0xFF2A2229), Color(0xFF2E262C), Color(0xFF272026)];
  static const _musgo = [Color(0xFF2B3320), Color(0xFF33401F)];

  /// Tramos de camino entre la entrada y los lugares importantes.
  static const _tramos = [
    (Offset(0, 0), Offset(0, -170)),
    (Offset(0, -40), Offset(150, -80)),
    (Offset(0, -10), Offset(-190, -100)),
    (Offset(0, 0), Offset(220, 130)),
  ];

  @override
  Future<void> onLoad() async {
    const l = ZonaClaro.limites;
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    final azar = Random(7);
    final pintura = Paint()..isAntiAlias = false;
    const celda = 8.0;

    for (var y = l.top; y < l.bottom; y += celda) {
      for (var x = l.left; x < l.right; x += celda) {
        pintura.color = _tierra[azar.nextInt(_tierra.length)];
        canvas.drawRect(Rect.fromLTWH(x, y, celda, celda), pintura);
      }
    }

    for (final (a, b) in _tramos) {
      final pasos = ((b - a).distance / 4).ceil();
      for (var i = 0; i <= pasos; i++) {
        final p = Offset.lerp(a, b, i / pasos)!;
        for (var j = 0; j < 3; j++) {
          pintura.color = _camino[azar.nextInt(_camino.length)];
          final dx = (azar.nextInt(5) - 2) * 4.0, dy = (azar.nextInt(3) - 1) * 4.0;
          canvas.drawRect(
              Rect.fromLTWH((p.dx + dx).roundToDouble() - 6,
                  (p.dy + dy).roundToDouble() - 4, 12, 8),
              pintura);
        }
      }
    }

    // Matas de musgo y piedrecitas sueltas.
    for (var i = 0; i < 260; i++) {
      final x = (l.left + azar.nextDouble() * l.width).roundToDouble();
      final y = (l.top + azar.nextDouble() * l.height).roundToDouble();
      if (azar.nextBool()) {
        pintura.color = _musgo[azar.nextInt(_musgo.length)];
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 2), pintura);
        canvas.drawRect(Rect.fromLTWH(x + 2, y - 1, 1, 3), pintura);
      } else {
        pintura.color = const Color(0xFF3A3440);
        canvas.drawRect(Rect.fromLTWH(x, y, 2, 1), pintura);
      }
    }

    // Borde en tres bandas cada vez más oscuras: el claro se pierde en la noche.
    for (var banda = 0; banda < 3; banda++) {
      pintura.color = Colores.abismo.withValues(alpha: 0.35 + banda * 0.3);
      final r = l.deflate(banda * 8.0);
      final interior = r.deflate(8);
      canvas.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(l.inflate(400))
          ..addRect(interior),
        pintura,
      );
    }

    _imagen = grabadora.endRecording();
  }

  @override
  void render(Canvas canvas) => canvas.drawPicture(_imagen);
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
