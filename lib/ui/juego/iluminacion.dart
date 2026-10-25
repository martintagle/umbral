import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'umbral_juego.dart';

/// Un punto de luz en el mundo. [parpadeo] es cuántos píxeles crece y mengua
/// el radio, como una llama.
class Luz {
  Luz(this.posicion, {required this.radio, this.tinte, this.parpadeo = 0});

  final Vector2 posicion;
  final double radio;

  /// Color que la luz añade a lo que ilumina; `null` para luz neutra.
  final Color? tinte;
  final double parpadeo;
  final double _fase = Random().nextDouble() * 100;

  int radioEn(double t) {
    if (parpadeo == 0) return radio.round();
    final onda = sin(t * 7 + _fase) * 0.6 + sin(t * 13 + _fase * 2) * 0.4;
    return (radio + onda * parpadeo).round();
  }
}

/// Noche cerrada sobre todo el mundo. Cada luz abre un círculo en anillos
/// escalonados alineados a los píxeles de arte, sin degradados suaves.
///
/// Va por encima de los sprites y por debajo de los efectos: los números de
/// daño, los tajos y los proyectiles se ven aunque caigan en la oscuridad.
class Iluminacion extends Component with HasGameReference<UmbralJuego> {
  /// [oscuridad] es la opacidad de la noche: los interiores son algo menos
  /// cerrados que el bosque.
  Iluminacion({double oscuridad = 0.96})
      : _pinturaOscuridad = Paint()
          ..color = Colores.abismo.withValues(alpha: oscuridad),
        super(priority: prioridadEfectos - 100);

  final List<Luz> fijas = [];

  /// (fracción del radio, cuánto borra de la oscuridad). Del anillo exterior
  /// al centro, que queda limpio.
  static const _anillos = [(1.0, 0.3), (0.84, 0.35), (0.68, 0.45), (0.52, 1.0)];

  /// (fracción del radio, intensidad) del color que añade una luz con tinte.
  static const _halo = [(0.75, 0.05), (0.45, 0.07)];

  static const _luzVela = 26.0;

  /// El rango de visión del personaje.
  final _jugador = Luz(Vector2.zero(), radio: 68, parpadeo: 1);

  /// Las larvas-cirio llevan velas encendidas en el lomo.
  final _velas = Expando<Luz>();

  final _pinturaCapa = Paint();
  final Paint _pinturaOscuridad;
  final _borrar = Paint()
    ..blendMode = BlendMode.dstOut
    ..isAntiAlias = false;
  final _tenir = Paint()
    ..blendMode = BlendMode.plus
    ..isAntiAlias = false;
  final Map<int, Path> _circulos = {};
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final vista = game.camera.visibleWorldRect.inflate(4);
    // Las llamas cambian a 10 cuadros por segundo, como una animación de píxel.
    final t = (_t * 10).floorToDouble() / 10;
    final luces = <(Luz, double, double, int)>[];
    void anotar(Luz luz, Vector2 p) {
      final r = luz.radioEn(t);
      if (p.x + r < vista.left ||
          p.x - r > vista.right ||
          p.y + r < vista.top ||
          p.y - r > vista.bottom) {
        return;
      }
      luces.add((luz, p.x.roundToDouble(), p.y.roundToDouble(), r));
    }

    for (final luz in fijas) {
      anotar(luz, luz.posicion);
    }
    anotar(_jugador, game.jugador.centro);
    for (final e in game.zona.enemigosVivos) {
      if (e.tipo.id == 'larva-cirio') {
        final vela = _velas[e] ??=
            Luz(Vector2.zero(), radio: _luzVela, tinte: Colores.brasa, parpadeo: 2);
        anotar(vela, e.centro - Vector2(0, 4));
      }
    }

    canvas.saveLayer(vista, _pinturaCapa);
    canvas.drawRect(vista, _pinturaOscuridad);
    for (final (_, x, y, r) in luces) {
      for (final (fraccion, fuerza) in _anillos) {
        _borrar.color = Color.fromRGBO(0, 0, 0, fuerza);
        _circulo(canvas, x, y, (r * fraccion).round(), _borrar);
      }
    }
    canvas.restore();

    // El tinte no sale del escenario: alrededor de una sala no hay nada que
    // iluminar.
    canvas
      ..save()
      ..clipRect(game.zona.limites);
    for (final (luz, x, y, r) in luces) {
      final tinte = luz.tinte;
      if (tinte == null) continue;
      for (final (fraccion, fuerza) in _halo) {
        _tenir.color = tinte.withValues(alpha: fuerza);
        _circulo(canvas, x, y, (r * fraccion).round(), _tenir);
      }
    }
    canvas.restore();
  }

  void _circulo(Canvas canvas, double x, double y, int radio, Paint pintura) {
    if (radio <= 0) return;
    canvas.save();
    canvas.translate(x, y);
    canvas.drawPath(_circulos.putIfAbsent(radio, () => _pathCirculo(radio)), pintura);
    canvas.restore();
  }

  /// Círculo hecho de filas de un píxel de alto: el borde queda escalonado.
  static Path _pathCirculo(int r) {
    final path = Path();
    for (var fila = -r; fila < r; fila++) {
      final y = fila + 0.5;
      final media = sqrt(r * r - y * y).roundToDouble();
      if (media > 0) {
        path.addRect(Rect.fromLTWH(-media, fila.toDouble(), media * 2, 1));
      }
    }
    return path;
  }
}

/// Antorcha clavada en el suelo. Su `position` es la base del poste.
class Antorcha extends PositionComponent {
  Antorcha(Vector2 base) : super(position: base, priority: base.y.round());

  /// Donde está la llama, para colocar su luz.
  Vector2 get llama => position + Vector2(0, -17);

  /// Base del poste: lo único que no se puede atravesar.
  Rect get huella => Rect.fromCenter(
      center: Offset(position.x, position.y - 2), width: 6, height: 4);

  static const _madera = Color(0xFF3B2A22);
  static const _maderaLuz = Color(0xFF5A4030);
  static const _hierro = Color(0xFF4A4250);

  final _azar = Random();
  final List<Vector2> _chispas = [];
  double _t = 0;
  double _chispa = 0;
  int _cuadro = 0;

  @override
  void update(double dt) {
    _t += dt;
    _chispa += dt;
    _cuadro = (_t * 8).floor();
    if (_chispa > 0.35 + _azar.nextDouble() * 0.4) {
      _chispa = 0;
      _chispas.add(Vector2((_azar.nextInt(3) - 1).toDouble(), -21));
    }
    for (final c in _chispas) {
      c.y -= 10 * dt;
    }
    _chispas.removeWhere((c) => c.y < -32);
  }

  @override
  void render(Canvas canvas) {
    // Sombra, poste con su lado iluminado a la izquierda y cuenco de hierro.
    pixel(canvas, -2, -1, Colores.abismo);
    pixel(canvas, 1, -1, Colores.abismo);
    for (var y = -13; y < 0; y++) {
      pixel(canvas, -1, y.toDouble(), _maderaLuz);
      pixel(canvas, 0, y.toDouble(), _madera);
    }
    for (var x = -3; x <= 2; x++) {
      pixel(canvas, x.toDouble(), -15, x == -3 || x == 2 ? Colores.abismo : _hierro);
      if (x > -3 && x < 2) pixel(canvas, x.toDouble(), -14, _hierro);
    }

    // Llama: cuatro columnas que cambian de alto en cada cuadro.
    const altos = [
      [2, 4, 3, 1],
      [3, 5, 4, 2],
      [2, 5, 3, 2],
      [1, 4, 4, 2],
    ];
    final fila = altos[_cuadro % altos.length];
    for (var i = 0; i < 4; i++) {
      final x = (i - 2).toDouble();
      for (var h = 0; h < fila[i]; h++) {
        final color = h == 0 && (i == 1 || i == 2)
            ? Colores.hueso
            : h >= fila[i] - 1 && fila[i] > 2
                ? Colores.sangre
                : Colores.brasa;
        pixel(canvas, x, -16 - h.toDouble(), color);
      }
    }
    for (final c in _chispas) {
      pixel(canvas, c.x, c.y, c.y < -27 ? Colores.ceniza : Colores.brasa);
    }
  }
}
