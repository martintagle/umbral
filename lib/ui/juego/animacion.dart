import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Una fila de una hoja: sus cuadros, cuánto dura cada uno y en qué cuadro
/// pasa algo (el impacto del golpe, soltar el disparo, la cura...).
class Animacion {
  Animacion._(this.sprites, this.duraciones, this.bucle, this.eventos);

  final List<Sprite> sprites;

  /// Segundos de cada cuadro.
  final List<double> duraciones;
  final bool bucle;
  final Map<String, int> eventos;

  int get cuadros => sprites.length;
  double get duracion => duracionTramo(0, cuadros);

  /// Segundos que duran los cuadros [desde, hasta).
  double duracionTramo(int desde, int hasta) {
    var total = 0.0;
    for (var i = desde; i < hasta; i++) {
      total += duraciones[i];
    }
    return total;
  }

  /// Cuadros de los golpes de un combo (`golpe`, `golpe1`, `golpe2`...), en
  /// orden.
  List<int> get golpes => [
    for (final MapEntry(:key, :value) in eventos.entries)
      if (key.startsWith('golpe')) value,
  ]..sort();

  /// Cuadro que toca a los [t] segundos de empezar.
  int cuadroEn(double t) {
    if (bucle) t %= duracion;
    return _buscar(t, 0, cuadros);
  }

  /// Cuadro que toca al [progreso] (0 a 1) de los cuadros [desde, hasta),
  /// repartido según lo que dura cada uno.
  int cuadroEnTramo(double progreso, int desde, int hasta) {
    if (hasta <= desde) return min(desde, cuadros - 1);
    final t = progreso.clamp(0.0, 1.0) * duracionTramo(desde, hasta);
    return _buscar(t, desde, hasta);
  }

  int _buscar(double t, int desde, int hasta) {
    for (var i = desde; i < hasta; i++) {
      t -= duraciones[i];
      if (t < 0) return i;
    }
    return hasta - 1;
  }
}

/// Una hoja de sprites: una fila por animación y un cuadro por columna.
class Hoja {
  Hoja._(this.celda, this.ancla, this._animaciones);

  final Vector2 celda;

  /// Punto de la celda que va sobre la posición (los pies; en los efectos,
  /// el centro).
  final Vector2 ancla;
  final Map<String, Animacion> _animaciones;

  bool tiene(String nombre) => _animaciones.containsKey(nombre);

  Animacion operator [](String nombre) =>
      _animaciones[nombre] ?? (throw ArgumentError('Sin animación $nombre'));
}

/// Las hojas cuadro a cuadro de `assets/sprites/animaciones/`, según
/// `hojas.json`. Se preparan una vez, al cargar el juego.
abstract final class Hojas {
  static final Map<String, Hoja> _listas = {};

  static const efectos = 'efectos/efectos';
  static const ondaExpansiva = 'efectos/onda-expansiva';

  /// [claves] son `grupo/nombre` de `hojas.json`: `personajes/mago-mujer`,
  /// `enemigos/fauce`, `efectos/efectos`...
  static Future<void> preparar(Images imagenes, Iterable<String> claves) async {
    final config =
        jsonDecode(
              await rootBundle.loadString(
                'assets/sprites/animaciones/hojas.json',
              ),
            )
            as Map<String, dynamic>;
    for (final clave in claves) {
      if (_listas.containsKey(clave)) continue;
      final [grupo, nombre] = clave.split('/');
      final datos =
          (config[grupo] as Map<String, dynamic>)[nombre]
              as Map<String, dynamic>;
      final imagen = await imagenes.load(
        'sprites/animaciones/${datos['archivo']}',
      );
      final c = datos['celda'] as Map<String, dynamic>;
      final a = datos['ancla'] as Map<String, dynamic>;
      final celda = Vector2(
        (c['ancho'] as num).toDouble(),
        (c['alto'] as num).toDouble(),
      );
      _listas[clave] = Hoja._(
        celda,
        Vector2((a['x'] as num).toDouble(), (a['y'] as num).toDouble()),
        {
          for (final MapEntry(key: n, value: v)
              in (datos['animaciones'] as Map<String, dynamic>).entries)
            n: _animacion(imagen, celda, v as Map<String, dynamic>),
        },
      );
    }
  }

  static Animacion _animacion(
    ui.Image imagen,
    Vector2 celda,
    Map<String, dynamic> d,
  ) {
    final fila = (d['fila'] as num).toDouble();
    return Animacion._(
      [
        for (var i = 0; i < (d['cuadros'] as num).toInt(); i++)
          Sprite(
            imagen,
            srcPosition: Vector2(i * celda.x, fila * celda.y),
            srcSize: celda,
          ),
      ],
      [for (final ms in d['ms'] as List) (ms as num) / 1000],
      d['bucle'] as bool? ?? false,
      {
        for (final MapEntry(:key, :value)
            in (d['eventos'] as Map<String, dynamic>? ?? const {}).entries)
          key: (value as num).toInt(),
      },
    );
  }

  static Hoja de(String clave) =>
      _listas[clave] ?? (throw StateError('Hoja $clave sin preparar'));
}

/// Un personaje, una criatura o un efecto dibujado con su hoja. Quien lo usa
/// elige cada cuadro qué mostrar: una animación que avanza sola
/// ([reproducir]) o un tramo según el progreso de una acción ([tramo]), para
/// que el golpe del dibujo caiga justo cuando el juego lo cuenta.
///
/// Igual que un `SpriteComponent`: tamaño de la celda, ancla en los pies y
/// [paint] para tintes y transparencia.
class ModeloAnimado extends PositionComponent {
  ModeloAnimado(this.hoja, {required this.paint})
    : super(
        size: hoja.celda.clone(),
        anchor: Anchor(
          hoja.ancla.x / hoja.celda.x,
          hoja.ancla.y / hoja.celda.y,
        ),
      );

  final Hoja hoja;
  final Paint paint;

  /// Fuera de la vista no se dibuja.
  bool visible = true;

  /// La animación que avanza con su propio reloj, o `null` si se muestra un
  /// tramo.
  Animacion? _reloj;
  double _t = 0;
  double _velocidad = 1;
  Sprite? _cuadro;

  /// Muestra [nombre] con su propio reloj; empieza desde el principio si
  /// antes se mostraba otra cosa.
  void reproducir(String nombre, {double velocidad = 1}) {
    final a = hoja[nombre];
    if (!identical(a, _reloj)) {
      _reloj = a;
      _t = 0;
      _cuadro = a.sprites.first;
    }
    _velocidad = velocidad;
  }

  /// Muestra el cuadro de [nombre] que toca al [progreso] (0 a 1) de los
  /// cuadros [desde, hasta).
  void tramo(String nombre, double progreso, {int desde = 0, int? hasta}) {
    final a = hoja[nombre];
    _reloj = null;
    _cuadro = a.sprites[a.cuadroEnTramo(progreso, desde, hasta ?? a.cuadros)];
  }

  @override
  void update(double dt) {
    final a = _reloj;
    if (a == null) return;
    _t += dt * _velocidad;
    _cuadro = a.sprites[a.cuadroEn(_t)];
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    _cuadro?.render(canvas, size: size, overridePaint: paint);
  }
}
