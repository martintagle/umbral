import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tema/tema_umbral.dart';
import 'animacion.dart';
import 'registro_progreso.dart';
import 'umbral_juego.dart';

/// Capa por encima de todo el mundo (los objetos se ordenan por su `y`).
const prioridadEfectos = 1 << 20;

/// Personajes y criaturas se dibujan a la mitad de su tamaño de arte: a 1:1
/// una persona medía dos tiles y medio y no cabía por las puertas. El zoom de
/// la cámara es siempre par, así que cada píxel del sprite sigue ocupando un
/// número entero de píxeles de pantalla.
const escalaSprites = 0.5;

final Paint _pintura = Paint()..isAntiAlias = false;

/// Pintura para dibujar sprites sin suavizar sus píxeles.
Paint pinturaSprites() => Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

/// Pinta un cuadrado de [tamano] píxeles de arte alineado a la cuadrícula.
void pixel(
  Canvas canvas,
  double x,
  double y,
  Color color, [
  double tamano = 1,
]) {
  _pintura.color = color;
  canvas.drawRect(
    Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), tamano, tamano),
    _pintura,
  );
}

/// Número de daño o texto corto que sube y desaparece.
class TextoFlotante extends TextComponent with HasGameReference<UmbralJuego> {
  final double _vida;
  double _t = 0;

  TextoFlotante(
    String texto,
    Vector2 posicion, {
    Color color = Colores.hueso,
    bool grande = true,
    double duracion = 0.7,
  }) : _vida = duracion,
       super(
         text: texto,
         position: posicion,
         anchor: Anchor.bottomCenter,
         priority: prioridadEfectos,
       ) {
    _estilo = (color, grande);
  }

  late final (Color, bool) _estilo;

  @override
  Future<void> onLoad() async {
    // El diseño pide 32 px en pantalla: se divide por el zoom del mundo.
    final zoom = game.zoom;
    final (color, grande) = _estilo;
    textRenderer = TextPaint(
      style: GoogleFonts.silkscreen(
        fontSize: (grande ? 32 : 16) / zoom,
        fontWeight: grande ? FontWeight.w700 : FontWeight.w400,
        color: color,
        shadows: [
          Shadow(color: Colores.abismo, offset: Offset(4 / zoom, 4 / zoom)),
        ],
      ),
    );
  }

  @override
  void update(double dt) {
    _t += dt;
    position.y -= 18 * dt;
    if (_t >= _vida) removeFromParent();
  }
}

/// Arco de tajo de un arma cuerpo a cuerpo.
class Tajo extends PositionComponent {
  final double direccion;
  final double arco;
  final double radio;
  double _t = 0;
  static const _duracion = 0.14;

  Tajo(
    Vector2 centro, {
    required this.direccion,
    required this.arco,
    required this.radio,
  }) : super(position: centro, priority: prioridadEfectos - 1);

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _duracion) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progreso = (_t / _duracion).clamp(0.0, 1.0);
    final inicio = direccion - arco / 2;
    final barrido = arco * (0.4 + 0.6 * progreso);
    final pasos = (radio * arco / 2).ceil();
    for (var i = 0; i <= pasos; i++) {
      final a = inicio + barrido * i / pasos;
      final c = cos(a), s = sin(a);
      pixel(canvas, c * radio, s * radio, Colores.hueso);
      pixel(canvas, c * (radio - 2), s * (radio - 2), Colores.ceniza);
      if (i == pasos) pixel(canvas, c * radio, s * radio, Colores.brasa, 2);
    }
  }
}

/// Tres rasguños en diagonal donde muerde o golpea una criatura.
class Zarpazo extends PositionComponent {
  final double _lado;
  double _t = 0;
  static const _duracion = 0.18;

  Zarpazo(Vector2 centro, {required bool haciaLaDerecha})
    : _lado = haciaLaDerecha ? 1 : -1,
      super(position: centro, priority: prioridadEfectos - 1);

  @override
  void update(double dt) {
    _t += dt;
    if (_t >= _duracion) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final largo = (6 * (_t / _duracion * 2).clamp(0.0, 1.0)).round();
    for (var r = -1; r <= 1; r++) {
      for (var i = 0; i < largo; i++) {
        final x = (i - 3) * _lado + r * 3;
        final y = (i - 3 - r).toDouble();
        pixel(canvas, x, y, i == largo - 1 ? Colores.hueso : Colores.sangre);
      }
    }
  }
}

/// El cuerpo de una criatura derrotada: hace su animación `morir`, queda un
/// momento en el suelo y se apaga.
class Desvanecer extends PositionComponent {
  /// [lado] es 1 si la criatura miraba a la derecha y -1 si a la izquierda.
  Desvanecer(Hoja hoja, Vector2 pies, double lado)
    : _modelo = ModeloAnimado(hoja, paint: pinturaSprites())
        ..scale = Vector2(lado * escalaSprites, escalaSprites)
        ..tramo('morir', 0),
      _morir = hoja['morir'],
      super(position: pies, priority: pies.y.round()) {
    add(_modelo);
  }

  final ModeloAnimado _modelo;
  final Animacion _morir;
  double _t = 0;
  static const _apagado = 0.4;

  @override
  void update(double dt) {
    _t += dt;
    _modelo.tramo('morir', _t / _morir.duracion);
    final p = ((_t - _morir.duracion) / _apagado).clamp(0.0, 1.0);
    _modelo.paint.color = Color.fromRGBO(255, 255, 255, 1 - p);
    if (p >= 1) removeFromParent();
  }
}

/// Un efecto que se ve una vez y desaparece: la chispa de un golpe o la onda
/// expansiva del rey.
class Efecto extends PositionComponent {
  /// [hoja] es la clave en [Hojas] y [nombre] la animación.
  Efecto(String hoja, this._nombre, Vector2 centro)
    : _modelo = ModeloAnimado(Hojas.de(hoja), paint: pinturaSprites())
        ..scale = Vector2.all(escalaSprites)
        ..tramo(_nombre, 0),
      super(position: centro, priority: prioridadEfectos - 1) {
    add(_modelo);
  }

  final String _nombre;
  final ModeloAnimado _modelo;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    final duracion = _modelo.hoja[_nombre].duracion;
    _modelo.tramo(_nombre, _t / duracion);
    if (_t >= duracion) removeFromParent();
  }
}

/// Restos que salen despedidos cuando muere algo.
class Estallido extends PositionComponent {
  final List<(Vector2, Vector2, Color)> _trozos = [];
  double _t = 0;
  static const _duracion = 0.45;

  Estallido(Vector2 centro, List<Color> colores)
    : super(position: centro, priority: prioridadEfectos - 1) {
    final azar = Random();
    for (var i = 0; i < 12; i++) {
      final a = azar.nextDouble() * pi * 2;
      final v = 30 + azar.nextDouble() * 50;
      _trozos.add((
        Vector2.zero(),
        Vector2(cos(a), sin(a)) * v,
        colores[i % colores.length],
      ));
    }
  }

  @override
  void update(double dt) {
    _t += dt;
    for (final (p, v, _) in _trozos) {
      p.addScaled(v, dt);
      v.scale(0.9);
    }
    if (_t >= _duracion) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final tamano = _t < _duracion / 2 ? 2.0 : 1.0;
    for (final (p, _, color) in _trozos) {
      pixel(canvas, p.x, p.y, color, tamano);
    }
  }
}

/// Flecha, orbe, polvo o fuego. Lo puede lanzar el jugador o un enemigo.
class Proyectil extends PositionComponent with HasGameReference<UmbralJuego> {
  final Vector2 velocidad;
  final double distanciaMaxima;
  final int dano;
  final bool critico;
  final bool delJugador;
  final double tamano;
  final Color color;

  /// Animación de `efectos.png` o `efectos-2.png` que lo dibuja, apuntando
  /// hacia donde vuela;
  /// sin ella es una línea o un cuadrado de [color].
  final String? efecto;
  double _recorrido = 0;

  Proyectil({
    required Vector2 origen,
    required Vector2 direccion,
    required double rapidez,
    required this.distanciaMaxima,
    required this.dano,
    required this.delJugador,
    required this.color,
    this.tamano = 2,
    this.critico = false,
    this.efecto,
  }) : velocidad = direccion.normalized() * rapidez,
       super(position: origen, priority: prioridadEfectos - 2) {
    if (efecto case final nombre?) {
      add(
        ModeloAnimado(
          Hojas.de(Hojas.efectos).tiene(nombre)
              ? Hojas.de(Hojas.efectos)
              : Hojas.de(Hojas.efectos2),
          paint: pinturaSprites(),
        )
          ..scale = Vector2.all(escalaSprites)
          ..angle = atan2(velocidad.y, velocidad.x)
          ..reproducir(nombre),
      );
    }
  }

  @override
  void update(double dt) {
    final paso = velocidad * dt;
    position.add(paso);
    _recorrido += paso.length;

    if (_recorrido >= distanciaMaxima ||
        game.zona.bloquea(position.x, position.y)) {
      removeFromParent();
      return;
    }

    if (delJugador) {
      for (final enemigo in game.zona.enemigosVivos) {
        if (enemigo.centro.distanceTo(position) <= enemigo.radio + tamano) {
          enemigo.recibirGolpe(dano, critico, velocidad.normalized());
          removeFromParent();
          return;
        }
      }
    } else {
      final jugador = game.jugador;
      if (jugador.vivo &&
          jugador.centro.distanceTo(position) <= jugador.radio + tamano) {
        jugador.recibirGolpe(dano);
        removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (efecto != null) return;
    if (tamano <= 2) {
      // Flecha o polvo: una línea corta en la dirección de vuelo.
      final d = velocidad.normalized();
      for (var i = 0; i < 4; i++) {
        pixel(canvas, -d.x * i, -d.y * i, i == 0 ? Colores.brasa : color);
      }
    } else {
      pixel(canvas, -tamano / 2, -tamano / 2, color, tamano);
      pixel(canvas, -1, -1, Colores.hueso, 2);
    }
  }
}

/// Lo que el jugador soltó al caer: un montón de brasas que laten en el
/// suelo, visibles aun en la oscuridad. Al pisarlo se recupera.
class ManchaBrasas extends PositionComponent {
  ManchaBrasas(this.botin, Vector2 pies)
    : super(position: pies, priority: prioridadEfectos - 50);

  /// Lo ganado que valen esas brasas.
  final Botin botin;

  final _azar = Random();
  final List<Vector2> _chispas = [];
  double _t = 0;
  double _siguiente = 0;

  @override
  void update(double dt) {
    _t += dt;
    _siguiente -= dt;
    if (_siguiente <= 0) {
      _siguiente = 0.12;
      _chispas.add(Vector2((_azar.nextInt(9) - 4).toDouble(), 0));
    }
    for (final c in _chispas) {
      c.y -= 12 * dt;
    }
    _chispas.removeWhere((c) => c.y < -12);
  }

  @override
  void render(Canvas canvas) {
    // Late como un corazón: el núcleo crece y mengua un píxel.
    final latido = sin(_t * 4) > 0 ? 1.0 : 0.0;
    for (var x = -3 - latido; x <= 3 + latido; x++) {
      pixel(canvas, x, 0, Colores.sangre);
    }
    for (var x = -2.0; x <= 2; x++) {
      pixel(canvas, x, -1, Colores.brasa);
    }
    pixel(canvas, 0, -2 - latido, Colores.hueso);
    for (final c in _chispas) {
      pixel(canvas, c.x, c.y, c.y < -7 ? Colores.ceniza : Colores.brasa);
    }
  }
}

/// Niebla de ceniza que sella una salida mientras el jefe sigue en pie.
class NieblaSello extends PositionComponent {
  NieblaSello(Rect zona)
    : _zona = zona,
      super(priority: prioridadEfectos - 60);

  final Rect _zona;
  final _azar = Random();
  double _t = 0;

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    // Píxeles que suben y cambian a 8 cuadros por segundo.
    final cuadro = (_t * 8).floor();
    final semilla = Random(cuadro);
    for (var i = 0; i < (_zona.width * _zona.height / 6).round(); i++) {
      final x = _zona.left + semilla.nextDouble() * _zona.width;
      final y = _zona.top + semilla.nextDouble() * _zona.height;
      pixel(canvas, x, y,
          _azar.nextBool() ? Colores.ceniza : Colores.hueso.withValues(alpha: 0.6));
    }
  }
}
