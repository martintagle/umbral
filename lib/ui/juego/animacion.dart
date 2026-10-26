import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

/// Cómo se mueve una pieza del sprite.
enum Rol {
  cuerpo,
  cabeza,
  brazo,
  pierna,
  arma,
  ala,
  pata,
  mandibula,
  balanceo,
  onda,
}

/// El golpe de cada arma: decide cómo giran el arma y el brazo que la lleva.
enum TipoAtaque { tajo, mandoble, estocada, arco, libro }

/// Un trozo del sprite (brazo, pierna, arma, ala...) recortado en su propia
/// imagen. Gira y se desplaza alrededor de [pivote], en píxeles del PNG.
class Pieza {
  Pieza._(this.rol, this.imagen, this.origen, this.pivote, this.capa,
      Map<String, dynamic> m)
      : fase = (m['fase'] as num?)?.toDouble() ?? 0,
        amp = (m['amp'] as num?)?.toDouble() ?? 0,
        frec = (m['frec'] as num?)?.toDouble() ?? 1,
        dir = (m['dir'] as num?)?.toDouble() ?? 1,
        armado = m['armado'] as bool? ?? false,
        colgante = m['colgante'] as bool? ?? false,
        ejeX = m['eje'] != 'y';

  final Rol rol;
  final ui.Image imagen;

  /// Esquina superior izquierda de [imagen] dentro del sprite.
  final Offset origen;
  final Offset pivote;
  final int capa;
  final double fase;
  final double amp;
  final double frec;

  /// Mandíbula: -1 la de arriba, 1 la de abajo.
  final double dir;

  /// El brazo que sostiene el arma: la sigue al atacar.
  final bool armado;

  /// Onda: lo de abajo se mueve más (tentáculos, el borde de una capa).
  final bool colgante;

  /// Onda: las filas se desplazan en x; si no, las columnas en y.
  final bool ejeX;
}

/// Las piezas en que se divide un sprite, de atrás hacia delante.
class Esqueleto {
  Esqueleto._(this.piezas, this.ataque, this.ancho, this.alto);

  final List<Pieza> piezas;
  final TipoAtaque? ataque;
  final double ancho;
  final double alto;

  double get centroX => ancho / 2;
}

/// Recorta los sprites según `assets/sprites/animaciones.json`. Se prepara
/// una vez, con las imágenes ya cargadas en la caché de Flame.
abstract final class Esqueletos {
  static final Map<String, Esqueleto> _listos = {};

  /// [rutas] relaciona cada imagen (como la conoce [imagenes]) con su entrada
  /// del JSON: `personajes/<clase>` o `enemigos/<id>`.
  static Future<void> preparar(
      Images imagenes, Map<String, String> rutas) async {
    final config = jsonDecode(
            await rootBundle.loadString('assets/sprites/animaciones.json'))
        as Map<String, dynamic>;
    for (final MapEntry(key: ruta, value: clave) in rutas.entries) {
      if (_listos.containsKey(ruta)) continue;
      final [grupo, nombre] = clave.split('/');
      final datos = (config[grupo] as Map<String, dynamic>)[nombre];
      if (datos == null) continue;
      _listos[ruta] =
          await _cortar(imagenes.fromCache(ruta), datos as Map<String, dynamic>);
    }
  }

  static Esqueleto? de(String ruta) => _listos[ruta];

  static Future<Esqueleto> _cortar(
      ui.Image imagen, Map<String, dynamic> datos) async {
    final w = imagen.width, h = imagen.height;
    final rgba = (await imagen.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    final definiciones = [
      for (final p in datos['piezas'] as List) p as Map<String, dynamic>,
    ];
    final rects = [
      for (final d in definiciones)
        [
          for (final r in d['r'] as List)
            Rect.fromLTWH(
              (r[0] as num).toDouble(),
              (r[1] as num).toDouble(),
              (r[2] as num).toDouble(),
              (r[3] as num).toDouble(),
            ),
        ],
    ];

    // Cada píxel visible va a la primera pieza que lo contiene; el resto, al
    // cuerpo (índice = definiciones.length).
    final duenos = List.filled(w * h, -1);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (rgba[(y * w + x) * 4 + 3] == 0) continue;
        final punto = Offset(x + 0.5, y + 0.5);
        var dueno = definiciones.length;
        for (var i = 0; i < rects.length; i++) {
          if (rects[i].any((r) => r.contains(punto))) {
            dueno = i;
            break;
          }
        }
        duenos[y * w + x] = dueno;
      }
    }

    final piezas = <Pieza>[];
    for (var i = 0; i <= definiciones.length; i++) {
      final esCuerpo = i == definiciones.length;
      final d = esCuerpo ? const <String, dynamic>{} : definiciones[i];
      var x0 = w, y0 = h, x1 = -1, y1 = -1;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (duenos[y * w + x] != i) continue;
          x0 = min(x0, x);
          y0 = min(y0, y);
          x1 = max(x1, x);
          y1 = max(y1, y);
        }
      }
      if (x1 < 0) continue;
      final pw = x1 - x0 + 1, ph = y1 - y0 + 1;
      final bytes = Uint8List(pw * ph * 4);
      for (var y = y0; y <= y1; y++) {
        for (var x = x0; x <= x1; x++) {
          if (duenos[y * w + x] != i) continue;
          final o = (y * w + x) * 4, n = ((y - y0) * pw + (x - x0)) * 4;
          bytes.setRange(n, n + 4, rgba, o);
        }
      }
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
          bytes, pw, ph, ui.PixelFormat.rgba8888, completer.complete);
      final pivote = d['p'] as List?;
      piezas.add(Pieza._(
        esCuerpo ? Rol.cuerpo : Rol.values.byName(d['rol'] as String),
        await completer.future,
        Offset(x0.toDouble(), y0.toDouble()),
        pivote == null
            ? Offset(w / 2, h.toDouble())
            : Offset((pivote[0] as num).toDouble(),
                (pivote[1] as num).toDouble()),
        esCuerpo ? 2 : (d['capa'] as num?)?.toInt() ?? 2,
        d,
      ));
    }
    // sort es estable: a igual capa, se respeta el orden del JSON.
    piezas.sort((a, b) => a.capa.compareTo(b.capa));
    final ataque = datos['ataque'] as String?;
    return Esqueleto._(
      piezas,
      ataque == null ? null : TipoAtaque.values.byName(ataque),
      w.toDouble(),
      h.toDouble(),
    );
  }
}

double _suave(double k) {
  final c = k.clamp(0.0, 1.0);
  return c * c * (3 - 2 * c);
}

/// Un personaje o una criatura dibujados por piezas que se mueven solas:
/// piernas que caminan, brazos que se balancean, armas que giran al golpear,
/// alas que baten y tentáculos que ondulan. Quien lo usa solo actualiza el
/// estado ([andar], [ataque], [preparar]...) cada cuadro.
///
/// Igual que un `SpriteComponent`: tamaño del PNG, ancla abajo al centro y
/// [paint] para tintes y transparencia. Sin esqueleto dibuja el sprite entero.
class ModeloAnimado extends PositionComponent {
  ModeloAnimado({required this.sprite, this.esqueleto, required this.paint})
      : super(
          size: sprite.srcSize,
          anchor: Anchor.bottomCenter,
        ) {
    _t = Random().nextDouble() * 10;
  }

  final Sprite sprite;
  final Esqueleto? esqueleto;
  final Paint paint;

  /// Fuera de la vista no se dibuja.
  bool visible = true;

  double _t = 0;

  /// Fase del paso, en radianes; avanza mientras camina.
  double paso = 0;

  /// 0 quieto, 1 caminando a toda marcha.
  double andar = 0;

  /// Progreso del ataque de 0 a 1, o negativo si no ataca.
  double ataque = -1;

  /// Fracción del ataque en la que el arma golpea.
  double impacto = 0.3;

  /// Carga antes de atacar (criaturas), de 0 a 1.
  double preparar = 0;

  /// Golpe de una criatura: sube a 1 en el impacto y vuelve a 0.
  double golpe = 0;

  /// Progreso del trago de un frasco, o negativo.
  double bebiendo = -1;

  @override
  void update(double dt) {
    _t += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final e = esqueleto;
    if (e == null) {
      sprite.render(canvas, size: size, overridePaint: paint);
      return;
    }
    final arma = _poseArma(e);
    for (final p in e.piezas) {
      if (p.rol == Rol.onda) {
        _ondular(canvas, p);
        continue;
      }
      final (dx, dy, giro, sx, sy) = _pose(e, p, arma);
      canvas.save();
      canvas.translate(p.pivote.dx + dx, p.pivote.dy + dy);
      if (giro != 0) canvas.rotate(giro);
      if (sx != 1 || sy != 1) canvas.scale(sx, sy);
      canvas.drawImage(p.imagen, p.origen - p.pivote, paint);
      canvas.restore();
    }
  }

  /// Rebote del cuerpo al caminar: sube un píxel en cada paso.
  double get _rebote => andar > 0.1 && sin(paso * 2).abs() > 0.5 ? -1 : 0;

  /// Respiración: la cabeza baja un píxel de vez en cuando.
  double get _respira => andar < 0.1 && sin(_t * 2.2) > 0.4 ? 1 : 0;

  /// Lado de la pieza respecto al centro: -1 izquierda, 1 derecha.
  double _ladoDe(Esqueleto e, Pieza p) => p.pivote.dx < e.centroX ? -1 : 1;

  (double, double, double, double, double) _pose(
      Esqueleto e, Pieza p, _PoseArma arma) {
    final t = _t;
    switch (p.rol) {
      case Rol.cuerpo:
        return (0, _rebote, 0, 1, 1);
      case Rol.cabeza:
        final giro = p.amp > 0
            ? sin(t * p.frec) * p.amp * (1 + preparar)
            : sin(t * 1.3) * 0.03;
        return (
          arma.alcance * 1.2,
          _rebote + _respira - preparar * 1.5,
          giro,
          1,
          1,
        );
      case Rol.pierna:
        final s = sin(paso + p.fase * pi);
        return (0, -max(0.0, s) * 2 * andar, s * 0.28 * andar, 1, 1);
      case Rol.brazo:
        final lado = _ladoDe(e, p);
        var giro = -sin(paso + p.fase * pi) * 0.45 * andar +
            sin(t * 1.7 + p.fase * 2) * 0.05;
        if (e.ataque == null) {
          // Criatura: abre los brazos al cargar y los cierra al golpear.
          giro += -lado * (0.7 * preparar - 1.2 * golpe);
        } else if (p.armado) {
          giro = ataque >= 0 ? arma.giroBrazo : giro;
        } else {
          if (ataque >= 0) giro += -lado * 0.3 * arma.alcance;
          if (bebiendo >= 0) {
            final k = bebiendo < 0.25
                ? _suave(bebiendo / 0.25)
                : bebiendo > 0.8
                    ? 1 - _suave((bebiendo - 0.8) / 0.2)
                    : 1.0;
            giro = lado * 2.5 * k;
          }
        }
        return (0, _rebote, giro, 1, 1);
      case Rol.arma:
        return (arma.dx, arma.dy + _rebote, arma.giro, arma.sx, 1);
      case Rol.ala:
        final batir = 0.5 + 0.5 * sin(t * p.frec * (1 + andar * 0.4));
        final cierre = 0.5 * batir + preparar * 0.3;
        return (0, -batir, 0, 1 - cierre, 1 - 0.1 * batir);
      case Rol.pata:
        final ritmo = t * p.frec * (0.35 + andar);
        final giro = sin(ritmo + p.fase * pi) * p.amp * (0.4 + andar) -
            _ladoDe(e, p) * preparar * 0.3;
        return (0, 0, giro, 1, 1);
      case Rol.mandibula:
        final apertura =
            max(0.0, sin(t * 3)) * 0.6 + preparar * 3 + golpe * 4;
        return (0, p.dir * apertura.roundToDouble(), 0, 1, 1);
      case Rol.balanceo:
        final giro = sin(t * p.frec * (1 + andar * 0.6) + p.fase * 2 * pi) *
                p.amp *
                (1 + preparar * 1.5) +
            p.amp * 1.5 * golpe;
        return (0, 0, giro, 1, 1);
      case Rol.onda:
        return (0, 0, 0, 1, 1);
    }
  }

  /// Tiras de una pieza que ondulan: filas que se desplazan a los lados
  /// (tentáculos, la capa del rey) o columnas que suben y bajan (la larva).
  void _ondular(Canvas canvas, Pieza p) {
    final img = p.imagen;
    final w = img.width, h = img.height;
    final amp = p.amp * (1 + andar * 0.5 + preparar);
    final ritmo = _t * p.frec * (1 + andar * 0.5);
    if (p.ejeX) {
      for (var r = 0; r < h; r++) {
        final peso = p.colgante ? (r + 1) / h : 1.0;
        final d = (amp * sin(ritmo + (p.origen.dy + r) * 0.7) * peso)
            .roundToDouble();
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, r.toDouble(), w.toDouble(), 1),
          Rect.fromLTWH(p.origen.dx + d, p.origen.dy + r, w.toDouble(), 1),
          paint,
        );
      }
    } else {
      for (var c = 0; c < w; c++) {
        final d = (amp * sin(ritmo - (p.origen.dx + c) * 0.55))
            .roundToDouble();
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(c.toDouble(), 0, 1, h.toDouble()),
          Rect.fromLTWH(p.origen.dx + c, p.origen.dy + d, 1, h.toDouble()),
          paint,
        );
      }
    }
  }

  /// Dónde está el arma en este cuadro. El ataque tiene tres tiempos: carga
  /// (hasta [impacto]), golpe (un tercio de lo que queda) y vuelta.
  _PoseArma _poseArma(Esqueleto e) {
    final tipo = e.ataque;
    if (tipo == null || ataque < 0) {
      final giro = andar * sin(paso) * 0.1 + sin(_t * 1.8) * 0.03;
      return _PoseArma(giro: giro, giroBrazo: giro * 0.5);
    }
    final p = ataque, m = impacto;
    final carga = p < m ? _suave(p / m) : 1.0;
    final g = p < m ? 0.0 : (p - m) / (1 - m);
    final latigo = p < m ? 0.0 : _suave(g / 0.35);
    final vuelta = g < 0.35 ? 0.0 : _suave((g - 0.35) / 0.65);
    switch (tipo) {
      case TipoAtaque.tajo:
        // Sube el filo sobre el hombro y lo baja de un tajo por delante.
        final giro = p < m ? -2.3 * carga : (-2.3 + 2.9 * latigo) * (1 - vuelta);
        return _PoseArma(
            giro: giro, giroBrazo: giro * 0.55, alcance: carga * (1 - vuelta));
      case TipoAtaque.mandoble:
        // Echa el espadón atrás, por encima, y lo deja caer delante.
        final giro = p < m ? -0.9 * carga : (-0.9 + 3.0 * latigo) * (1 - vuelta);
        return _PoseArma(
          giro: giro,
          dy: -3 * carga * (1 - latigo),
          giroBrazo: giro * 0.6,
          alcance: carga * (1 - vuelta),
        );
      case TipoAtaque.estocada:
        // Apunta la daga al frente, la recoge y la clava.
        final apunta = p < m ? carga : 1 - vuelta;
        final dx = p < m ? -3 * carga : (-3 + 10 * latigo) * (1 - vuelta);
        return _PoseArma(
          giro: -1.5 * apunta,
          dx: dx,
          giroBrazo: -1.3 * apunta,
          alcance: apunta,
        );
      case TipoAtaque.arco:
        // Lleva el arco al frente, lo tensa y retrocede al soltar.
        final frente = p < m ? carga : 1 - vuelta;
        return _PoseArma(
          dx: 13 * frente - 2 * latigo * (1 - vuelta),
          dy: -2 * frente,
          sx: 1 - 0.18 * (p < m ? carga : 0),
          giroBrazo: -1.4 * frente,
          alcance: frente,
        );
      case TipoAtaque.libro:
        // Alza el libro abierto y tiembla al soltar el hechizo.
        final frente = p < m ? carga : 1 - vuelta;
        final temblor = p < m ? 0.0 : sin(g * 70) * (1 - vuelta);
        return _PoseArma(
          giro: -0.35 * frente,
          dx: 9 * frente + temblor,
          dy: -6 * frente,
          giroBrazo: -1.5 * frente,
          alcance: frente,
        );
    }
  }
}

class _PoseArma {
  const _PoseArma({
    this.giro = 0,
    this.dx = 0,
    this.dy = 0,
    this.sx = 1,
    this.giroBrazo = 0,
    this.alcance = 0,
  });

  final double giro;
  final double dx;
  final double dy;
  final double sx;
  final double giroBrazo;

  /// Cuánto se estira el cuerpo hacia el golpe (0 a 1).
  final double alcance;
}
