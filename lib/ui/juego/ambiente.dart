import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'escenario.dart';
import 'iluminacion.dart';
import 'umbral_juego.dart';

/// Lo que flota en el aire de cada lugar.
enum TipoAire { ceniza, esporas, sal, motas, brasas, vacio, polvo }

/// El aire de una zona o de una sala (`docs/graficos.md`): el color de la
/// noche, la niebla, lo que flota y las criaturas que no pelean.
class Clima {
  const Clima({
    required this.noche,
    this.oscuridad = 0.94,
    required this.niebla,
    this.nieblaOpacidad = 0.14,
    this.viento = 6,
    required this.aire,
    this.densidad = 1,
    this.luciernagas = 0,
    this.cuervos = 0,
    this.ratas = 0,
    this.polillas = true,
    this.ondas = true,
  });

  /// Color de la oscuridad: la noche no es negra, tiene el tono de su lugar.
  final Color noche;
  final double oscuridad;
  final Color niebla;
  final double nieblaOpacidad;

  /// Píxeles por segundo que el viento empuja la niebla y lo que flota.
  final double viento;
  final TipoAire aire;

  /// Partículas en el aire por cada 100×100 píxeles de vista.
  final double densidad;
  final int luciernagas;
  final int cuervos;
  final int ratas;

  /// Polillas alrededor de las luces cercanas.
  final bool polillas;

  /// Peces que rompen el agua.
  final bool ondas;

  static Clima de(String zona) => switch (zona) {
    'cienaga' => const Clima(
      noche: Color(0xFF0B120C),
      niebla: Color(0xFFB8C49A),
      nieblaOpacidad: 0.24,
      viento: 3,
      aire: TipoAire.esporas,
      densidad: 1.4,
      luciernagas: 14,
      cuervos: 2,
    ),
    'minas' => const Clima(
      noche: Color(0xFF0A0A12),
      oscuridad: 0.96,
      niebla: Color(0xFF9A98B0),
      nieblaOpacidad: 0.1,
      viento: 2,
      aire: TipoAire.sal,
      densidad: 1.2,
      ratas: 4,
    ),
    'abadia' => const Clima(
      noche: Color(0xFF0A0E16),
      niebla: Color(0xFF9FB8C8),
      nieblaOpacidad: 0.18,
      viento: 4,
      aire: TipoAire.motas,
      luciernagas: 6,
      cuervos: 3,
      ratas: 2,
    ),
    'paramo' => const Clima(
      noche: Color(0xFF140C0A),
      niebla: Color(0xFF8A7A70),
      nieblaOpacidad: 0.16,
      viento: 14,
      aire: TipoAire.brasas,
      densidad: 1.3,
      cuervos: 4,
      ondas: false,
    ),
    'umbral' => const Clima(
      noche: Color(0xFF0A0610),
      oscuridad: 0.95,
      niebla: Color(0xFF6A5A80),
      nieblaOpacidad: 0.2,
      viento: 2,
      aire: TipoAire.vacio,
      densidad: 1.5,
      polillas: false,
      ondas: false,
    ),
    // Tierras del Umbral: noche azul, ceniza fina, luciérnagas en el pasto.
    _ => const Clima(
      noche: Color(0xFF0A0D18),
      niebla: Color(0xFFA8B0C8),
      nieblaOpacidad: 0.13,
      aire: TipoAire.ceniza,
      luciernagas: 10,
      cuervos: 3,
    ),
  };

  /// Las salas: polvo que solo se ve a la luz y la niebla del tema de su
  /// mazmorra.
  static Clima interior(String? zona) {
    final fuera = de(zona ?? '');
    return Clima(
      noche: fuera.noche,
      oscuridad: 0.88,
      niebla: fuera.niebla,
      nieblaOpacidad: zona == null ? 0.06 : 0.1,
      viento: 1.5,
      aire: zona == 'cienaga'
          ? TipoAire.esporas
          : zona == 'umbral'
          ? TipoAire.vacio
          : TipoAire.polvo,
      densidad: 0.9,
      ratas: zona == 'minas' || zona == 'abadia' || zona == null ? 2 : 0,
      polillas: true,
      ondas: false,
    );
  }
}

/// Pone en [e] la niebla, el aire y la vida de su [clima].
void ponerAmbiente(Escenario e, Clima clima) {
  e
    ..add(Niebla(clima))
    ..add(Particulas(clima))
    ..add(VidaSuelo(clima))
    ..add(VidaAire(clima))
    ..add(CapaBrillo());
}

/// Lo luminoso (luciérnagas, chispas, brasas) se dibuja encima de la
/// oscuridad con [pintarBrillo].
mixin Brilla on Component {
  void pintarBrillo(Canvas canvas);
}

/// Por encima de [Iluminacion]: lo que brilla se ve aunque esté a oscuras.
class CapaBrillo extends Component {
  CapaBrillo() : super(priority: prioridadEfectos - 90);

  @override
  void render(Canvas canvas) {
    for (final c in parent!.children) {
      if (c is Brilla) c.pintarBrillo(canvas);
    }
  }
}

final _halo = Paint()..isAntiAlias = false;

/// Un punto que brilla: núcleo de [tamano] y un halo tenue de un píxel.
void puntoBrillante(
  Canvas canvas,
  double x,
  double y,
  Color color,
  double alfa, {
  int tamano = 1,
}) {
  final px = x.roundToDouble(), py = y.roundToDouble();
  _halo.color = color.withValues(alpha: alfa * 0.28);
  canvas.drawRect(Rect.fromLTWH(px - 1, py - 1, tamano + 2.0, tamano + 2.0), _halo);
  _halo.color = color.withValues(alpha: alfa);
  canvas.drawRect(Rect.fromLTWH(px, py, tamano.toDouble(), tamano.toDouble()), _halo);
}

// ------------------------------------------------------------------ niebla

/// Dos capas de niebla (`assets/tiles/niebla.png`) que el viento arrastra a
/// distinta velocidad. Va encima de los sprites y debajo de la oscuridad:
/// solo se ve donde hay luz, como niebla de verdad.
class Niebla extends Component with HasGameReference<UmbralJuego> {
  Niebla(this.clima) : super(priority: prioridadEfectos - 150);

  final Clima clima;
  late final Image _textura;
  double _t = 0;
  final _pintura = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  Future<void> onLoad() async {
    _textura = await game.images.load('tiles/niebla.png');
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    if (clima.nieblaOpacidad <= 0) return;
    final vista = game.camera.visibleWorldRect;
    // La capa lejana va más lenta y es más tenue.
    _capa(canvas, vista, clima.viento * 0.55, 3, clima.nieblaOpacidad * 0.6, 0);
    _capa(canvas, vista, clima.viento, -2, clima.nieblaOpacidad, 97);
  }

  void _capa(
    Canvas canvas,
    Rect vista,
    double vx,
    double vy,
    double opacidad,
    double desfase,
  ) {
    final w = _textura.width.toDouble(), h = _textura.height.toDouble();
    // Respira: la densidad sube y baja despacio.
    final respiro = 0.8 + 0.2 * sin(_t * 0.35 + desfase);
    _pintura.colorFilter = ColorFilter.mode(
      clima.niebla.withValues(alpha: opacidad * respiro),
      BlendMode.modulate,
    );
    final ox = ((_t * vx + desfase * 13) % w).roundToDouble();
    final oy = ((_t * vy + desfase * 7) % h).roundToDouble();
    final x0 = ((vista.left - ox) / w).floor() * w + ox;
    final y0 = ((vista.top - oy) / h).floor() * h + oy;
    for (var y = y0; y < vista.bottom; y += h) {
      for (var x = x0; x < vista.right; x += w) {
        canvas.drawImage(_textura, Offset(x, y), _pintura);
      }
    }
  }
}

// -------------------------------------------------------------- partículas

class _Particula {
  _Particula(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.vida,
    this.color,
    this.tamano,
    this.brilla,
    this.gravedad,
    this.arrastre,
    this.oscila,
  ) : total = vida,
      fase = _azar.nextDouble() * 6.28;

  double x, y, vx, vy, vida;
  final double total, gravedad, arrastre, oscila, fase;
  final Color color;
  final int tamano;
  final bool brilla;

  /// Entra y sale con suavidad: 0 al nacer y al morir.
  double get alfa {
    final k = 1 - vida / total;
    return min(1.0, min(k * 6, (1 - k) * 3));
  }

  static final _azar = Random();
}

/// Todas las partículas de un lugar: el aire de su [clima] y las que piden
/// los golpes, los pasos y las muertes ([emitir] y sus atajos).
class Particulas extends Component
    with HasGameReference<UmbralJuego>, Brilla {
  Particulas(this.clima) : super(priority: prioridadEfectos - 140);

  final Clima clima;
  final List<_Particula> _vivas = [];
  final _azar = Random();
  static const _maximo = 420;
  double _t = 0;
  double _deuda = 0;

  @override
  void onMount() {
    super.onMount();
    (parent! as Escenario).particulas = this;
  }

  void emitir({
    required Vector2 en,
    required List<Color> colores,
    int n = 1,
    double rapidez = 20,
    double angulo = -pi / 2,
    double abertura = 2 * pi,
    double vida = 0.5,
    double gravedad = 0,
    double arrastre = 0.92,
    int tamano = 1,
    bool brilla = false,
    double dispersion = 0,
    double oscila = 0,
  }) {
    for (var i = 0; i < n && _vivas.length < _maximo; i++) {
      final a = angulo + (_azar.nextDouble() - 0.5) * abertura;
      final v = rapidez * (0.5 + _azar.nextDouble() * 0.5);
      _vivas.add(
        _Particula(
          en.x + (_azar.nextDouble() - 0.5) * dispersion * 2,
          en.y + (_azar.nextDouble() - 0.5) * dispersion * 2,
          cos(a) * v,
          sin(a) * v,
          vida * (0.7 + _azar.nextDouble() * 0.6),
          colores[_azar.nextInt(colores.length)],
          tamano,
          brilla,
          gravedad,
          arrastre,
          oscila,
        ),
      );
    }
  }

  /// Polvo de los pies al andar o rodar.
  void polvo(Vector2 pies, {int n = 2, bool piedra = false}) => emitir(
    en: pies,
    n: n,
    colores: piedra
        ? const [Color(0xFF8A8290), Color(0xFF6B6370)]
        : const [Color(0xFF7A6248), Color(0xFF5A4632)],
    rapidez: 14,
    abertura: 2.4,
    vida: 0.35,
    gravedad: 18,
    arrastre: 0.85,
    dispersion: 2,
  );

  /// Chispas del arma al dar en [en], hacia [hacia].
  void chispas(Vector2 en, Vector2 hacia, {int n = 6, bool critico = false}) =>
      emitir(
        en: en,
        n: critico ? n * 2 : n,
        colores: critico
            ? const [Colores.brasa, Colores.hueso, Color(0xFFF2C14E)]
            : const [Colores.hueso, Colores.brasa],
        rapidez: critico ? 110 : 75,
        angulo: atan2(hacia.y, hacia.x),
        abertura: 1.6,
        vida: 0.22,
        gravedad: 60,
        arrastre: 0.86,
        brilla: true,
      );

  /// Gotas de sangre que caen al suelo.
  void sangre(Vector2 en, Vector2 hacia, {int n = 5}) => emitir(
    en: en,
    n: n,
    colores: const [Colores.sangre, Color(0xFF6E1418)],
    rapidez: 45,
    angulo: atan2(hacia.y, hacia.x),
    abertura: 1.4,
    vida: 0.45,
    gravedad: 140,
    arrastre: 0.9,
  );

  /// El alma de una criatura que muere: motas que suben.
  void alma(Vector2 en, {int n = 10, Color color = Colores.alma}) => emitir(
    en: en,
    n: n,
    colores: [color, Colores.hueso],
    rapidez: 18,
    abertura: 1.2,
    vida: 1.3,
    gravedad: -14,
    arrastre: 0.97,
    brilla: true,
    dispersion: 4,
    oscila: 8,
  );

  /// Brasas que suben de un fuego.
  void brasas(Vector2 en, {int n = 1, double ancho = 3}) => emitir(
    en: en,
    n: n,
    colores: const [Color(0xFFF2C14E), Colores.brasa, Colores.brasa, Colores.sangre],
    rapidez: 10,
    abertura: 0.8,
    vida: 1.1,
    gravedad: -22,
    arrastre: 0.97,
    brilla: true,
    dispersion: ancho,
    oscila: 6,
  );

  @override
  void update(double dt) {
    _t += dt;
    _aire(dt);
    for (final p in _vivas) {
      p.vida -= dt;
      p.vx *= pow(p.arrastre, dt * 60).toDouble();
      p.vy = p.vy * pow(p.arrastre, dt * 60).toDouble() + p.gravedad * dt;
      p.x += (p.vx + (p.oscila == 0 ? 0 : sin(_t * 2.2 + p.fase) * p.oscila)) * dt;
      p.y += p.vy * dt;
    }
    _vivas.removeWhere((p) => p.vida <= 0);
  }

  /// Mantiene el aire lleno: nacen partículas por toda la vista, a la
  /// densidad del clima.
  void _aire(double dt) {
    final vista = game.camera.visibleWorldRect.inflate(16);
    final objetivo = vista.width * vista.height / 10000 * clima.densidad * 2.2;
    final ambientales = _vivas.length;
    if (ambientales > objetivo + 40) return;
    // Cada partícula vive unos 4 s: hay que reponer objetivo / 4 por segundo.
    _deuda += objetivo / 4 * dt;
    while (_deuda >= 1) {
      _deuda -= 1;
      final x = vista.left + _azar.nextDouble() * vista.width;
      final y = vista.top + _azar.nextDouble() * vista.height;
      _nacerAire(x, y);
    }
  }

  void _nacerAire(double x, double y) {
    if (_vivas.length >= _maximo) return;
    final viento = clima.viento;
    final en = Vector2(x, y);
    switch (clima.aire) {
      case TipoAire.ceniza:
        emitir(
          en: en,
          colores: const [Color(0xFF9A8F86), Color(0xFF6B6068)],
          rapidez: 0,
          vida: 4.5,
          gravedad: 0,
          arrastre: 1,
          oscila: 4,
        );
        _vivas.last
          ..vx = viento * 0.8
          ..vy = 7;
      case TipoAire.esporas:
        emitir(
          en: en,
          colores: const [Color(0xFFB8C46A), Color(0xFFD8C8A0)],
          rapidez: 0,
          vida: 4,
          arrastre: 1,
          oscila: 6,
          brilla: _azar.nextDouble() < 0.5,
        );
        _vivas.last
          ..vx = viento * 0.5
          ..vy = -4;
      case TipoAire.sal:
        emitir(
          en: en,
          colores: const [Color(0xFFD6D4E0), Color(0xFF9FD0DC)],
          rapidez: 0,
          vida: 3.5,
          arrastre: 1,
          oscila: 2,
          brilla: _azar.nextDouble() < 0.35,
        );
        _vivas.last
          ..vx = viento * 0.3
          ..vy = 4;
      case TipoAire.motas:
        emitir(
          en: en,
          colores: const [Colores.alma, Color(0xFF9FD0DC)],
          rapidez: 0,
          vida: 4,
          arrastre: 1,
          oscila: 5,
          brilla: true,
        );
        _vivas.last
          ..vx = viento * 0.4
          ..vy = -3;
      case TipoAire.brasas:
        final brasa = _azar.nextDouble() < 0.35;
        emitir(
          en: en,
          colores: brasa
              ? const [Colores.brasa, Colores.sangre]
              : const [Color(0xFF9A8F86), Color(0xFF6B6068)],
          rapidez: 0,
          vida: 3.5,
          arrastre: 1,
          oscila: 3,
          brilla: brasa,
        );
        _vivas.last
          ..vx = viento
          ..vy = brasa ? -6 : 5;
      case TipoAire.vacio:
        final claro = _azar.nextDouble() < 0.3;
        emitir(
          en: en,
          colores: claro
              ? const [Color(0xFFE8DCC4), Color(0xFFB8A0D8)]
              : const [Color(0xFF2A1E3A), Color(0xFF0D0B10)],
          rapidez: 0,
          vida: 4,
          arrastre: 1,
          oscila: 3,
          brilla: claro,
        );
        _vivas.last
          ..vx = viento * 0.2
          ..vy = -6;
      case TipoAire.polvo:
        emitir(
          en: en,
          colores: const [Color(0xFFC8BCA4), Color(0xFF9A8F86)],
          rapidez: 0,
          vida: 5,
          arrastre: 1,
          oscila: 2.5,
        );
        _vivas.last
          ..vx = viento
          ..vy = (_azar.nextDouble() - 0.5) * 2;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _vivas) {
      if (p.brilla) continue;
      pixel(
        canvas,
        p.x,
        p.y,
        p.color.withValues(alpha: p.alfa * 0.85),
        p.tamano.toDouble(),
      );
    }
  }

  @override
  void pintarBrillo(Canvas canvas) {
    for (final p in _vivas) {
      if (!p.brilla) continue;
      // Titila: la sal y las motas parpadean.
      final titilo = 0.75 + 0.25 * sin(_t * 9 + p.fase);
      puntoBrillante(canvas, p.x, p.y, p.color, p.alfa * titilo, tamano: p.tamano);
    }
  }
}

// ------------------------------------------------------------------- vida

/// Criaturas del suelo que no pelean: cuervos que picotean y vuelan al
/// acercarse, ratas que cruzan y ondas de peces en el agua. Van justo encima
/// del suelo.
class VidaSuelo extends Component with HasGameReference<UmbralJuego> {
  VidaSuelo(this.clima) : super(priority: -(1 << 19));

  final Clima clima;
  final _azar = Random();
  final List<_Cuervo> _cuervos = [];
  final List<_Rata> _ratas = [];
  final List<(Vector2, double)> _ondas = [];
  double _t = 0;
  double _esperaCuervo = 0;
  double _esperaRata = 0;
  double _esperaOnda = 0;

  Escenario get _lugar => parent! as Escenario;

  /// Un punto libre al azar dentro de la vista, lejos de [pies].
  Vector2? _sitioLibre(Rect vista, Vector2 pies, double lejos) {
    for (var i = 0; i < 10; i++) {
      final p = Vector2(
        vista.left + _azar.nextDouble() * vista.width,
        vista.top + _azar.nextDouble() * vista.height,
      );
      if (p.distanceTo(pies) < lejos) continue;
      if (_lugar.libre(Rect.fromCenter(center: Offset(p.x, p.y), width: 6, height: 4)) &&
          _lugar.limites.contains(Offset(p.x, p.y))) {
        return p;
      }
    }
    return null;
  }

  @override
  void update(double dt) {
    _t += dt;
    if (!game.jugador.isMounted || !identical(game.zona, _lugar)) return;
    final vista = game.camera.visibleWorldRect;
    final pies = game.jugador.position;

    _esperaCuervo -= dt;
    if (_cuervos.length < clima.cuervos && _esperaCuervo <= 0) {
      _esperaCuervo = 2 + _azar.nextDouble() * 4;
      if (_sitioLibre(vista.deflate(8), pies, 60) case final p?) {
        _cuervos.add(_Cuervo(p, _azar.nextBool() ? 1 : -1));
      }
    }
    for (final c in _cuervos) {
      c.update(dt, pies, _azar);
    }
    _cuervos.removeWhere(
      (c) => c.volando && !vista.inflate(40).contains(Offset(c.p.x, c.p.y)),
    );

    _esperaRata -= dt;
    if (_ratas.length < clima.ratas && _esperaRata <= 0) {
      _esperaRata = 3 + _azar.nextDouble() * 5;
      if (_sitioLibre(vista, pies, 50) case final p?) _ratas.add(_Rata(p));
    }
    for (final r in _ratas) {
      r.update(dt, pies, _lugar, _azar);
    }
    _ratas.removeWhere(
      (r) => r.vida <= 0 || !vista.inflate(60).contains(Offset(r.p.x, r.p.y)),
    );

    if (clima.ondas) {
      _esperaOnda -= dt;
      if (_esperaOnda <= 0) {
        _esperaOnda = 0.5 + _azar.nextDouble() * 1.2;
        for (var i = 0; i < 6; i++) {
          final p = Vector2(
            vista.left + _azar.nextDouble() * vista.width,
            vista.top + _azar.nextDouble() * vista.height,
          );
          if (_lugar.esAgua(p.x, p.y) &&
              _lugar.esAgua(p.x - 6, p.y) &&
              _lugar.esAgua(p.x + 6, p.y)) {
            _ondas.add((p, 0));
            break;
          }
        }
      }
      for (var i = 0; i < _ondas.length; i++) {
        _ondas[i] = (_ondas[i].$1, _ondas[i].$2 + dt);
      }
      _ondas.removeWhere((o) => o.$2 > 1.2);
    }
  }

  static const _agua = Color(0xFF9FD0DC);

  @override
  void render(Canvas canvas) {
    for (final (p, t) in _ondas) {
      // Anillo de píxeles que se abre y se apaga.
      final r = 1 + t * 5;
      final a = (1 - t / 1.2) * 0.55;
      final pasos = (r * 4).ceil() + 4;
      for (var i = 0; i < pasos; i++) {
        final ang = i / pasos * 2 * pi;
        pixel(canvas, p.x + cos(ang) * r, p.y + sin(ang) * r * 0.5,
            _agua.withValues(alpha: a));
      }
      if (t < 0.25) pixel(canvas, p.x, p.y - 1, Colores.hueso.withValues(alpha: 0.6));
    }
    for (final r in _ratas) {
      r.render(canvas);
    }
    for (final c in _cuervos) {
      if (!c.volando) c.render(canvas, _t);
    }
  }

  /// Los cuervos que vuelan se dibujan por encima de todo.
  void renderVolando(Canvas canvas) {
    for (final c in _cuervos) {
      if (c.volando) c.render(canvas, _t);
    }
  }
}

class _Cuervo {
  _Cuervo(this.p, this.lado);

  final Vector2 p;
  double lado;
  bool volando = false;
  final Vector2 _v = Vector2.zero();
  double _picoteo = 0;
  double _alto = 0;

  void update(double dt, Vector2 pies, Random azar) {
    if (!volando) {
      _picoteo -= dt;
      if (_picoteo < -0.25) _picoteo = 0.4 + azar.nextDouble() * 1.6;
      if (azar.nextDouble() < dt * 0.3) lado = -lado;
      if (p.distanceTo(pies) < 38) {
        // Se espanta: sale volando lejos del jugador y hacia arriba.
        volando = true;
        final huida = (p - pies)..normalize();
        _v.setValues(huida.x * 60, -45 + huida.y * 20);
        lado = _v.x < 0 ? -1 : 1;
      }
    } else {
      _v.y -= 25 * dt;
      p.addScaled(_v, dt);
      _alto += dt * 20;
    }
  }

  static const _negro = Color(0xFF15121A);
  static const _ala = Color(0xFF2A2430);

  void render(Canvas canvas, double t) {
    final x = p.x, y = p.y - _alto;
    if (volando) {
      final arriba = (t * 14).floor().isEven;
      // Cuerpo y alas en V que baten.
      pixel(canvas, x, y, _negro);
      pixel(canvas, x + lado, y, _negro);
      for (var i = 1; i <= 3; i++) {
        final dy = arriba ? -i * 0.6 : i * 0.3;
        pixel(canvas, x - i, y + dy, _ala);
        pixel(canvas, x + 1 + i, y + dy, _ala);
      }
      return;
    }
    // Sombra, cuerpo, cabeza que picotea y un ojo.
    pixel(canvas, x - 1, y + 1, Colores.abismo.withValues(alpha: 0.4));
    pixel(canvas, x, y + 1, Colores.abismo.withValues(alpha: 0.4));
    pixel(canvas, x - lado, y - 1, _negro);
    pixel(canvas, x, y - 1, _ala);
    pixel(canvas, x - lado * 2, y - 1, _negro);
    pixel(canvas, x, y, _negro);
    final pica = _picoteo < 0 ? 1.0 : 0.0;
    pixel(canvas, x + lado, y - 2 + pica, _negro);
    pixel(canvas, x + lado * 2, y - 2 + pica, const Color(0xFF6B6370));
    pixel(canvas, x + lado, y - 3 + pica, _negro);
  }
}

class _Rata {
  _Rata(this.p);

  final Vector2 p;
  final Vector2 _dir = Vector2.zero();
  double _quieta = 0.5;
  double _corre = 0;
  double vida = 14;

  void update(double dt, Vector2 pies, Escenario lugar, Random azar) {
    vida -= dt;
    final cerca = p.distanceTo(pies) < 40;
    if (_corre > 0 || cerca) {
      if (cerca && _corre <= 0) {
        _dir.setFrom((p - pies)..normalize());
        _corre = 0.8;
      }
      _corre -= dt;
      final paso = _dir * (cerca ? 70 : 45) * dt;
      final q = p + paso;
      if (lugar.libre(Rect.fromCenter(center: Offset(q.x, q.y), width: 4, height: 3))) {
        p.setFrom(q);
      } else {
        _corre = 0;
      }
    } else {
      _quieta -= dt;
      if (_quieta <= 0) {
        _quieta = 0.6 + azar.nextDouble() * 1.5;
        final a = azar.nextDouble() * 2 * pi;
        _dir.setValues(cos(a), sin(a) * 0.6);
        _corre = 0.3 + azar.nextDouble() * 0.5;
      }
    }
  }

  static const _pelo = Color(0xFF4A4038);

  void render(Canvas canvas) {
    final l = _dir.x < 0 ? -1.0 : 1.0;
    final anda = _corre > 0 && (p.x * 2).floor().isEven ? 1.0 : 0.0;
    pixel(canvas, p.x - l, p.y, _pelo);
    pixel(canvas, p.x, p.y, _pelo);
    pixel(canvas, p.x + l, p.y - 1, _pelo);
    pixel(canvas, p.x + l * 2, p.y, const Color(0xFF6B6068));
    pixel(canvas, p.x - l * 2, p.y + anda, const Color(0xFFB07A6A));
    pixel(canvas, p.x - l * 3, p.y + 1 - anda, const Color(0xFFB07A6A));
    pixel(canvas, p.x + l, p.y - 1, const Color(0xFF0D0B10), 1);
  }
}

/// Criaturas del aire: polillas alrededor de las luces, luciérnagas en la
/// hierba (con su propia luz) y los cuervos que huyen.
class VidaAire extends Component
    with HasGameReference<UmbralJuego>, Brilla, AportaLuz {
  VidaAire(this.clima) : super(priority: prioridadEfectos - 145);

  final Clima clima;
  final _azar = Random();
  final List<_Luciernaga> _luciernagas = [];
  final List<_Polilla> _polillas = [];
  double _t = 0;
  double _buscar = 0;

  Escenario get _lugar => parent! as Escenario;

  @override
  void update(double dt) {
    _t += dt;
    if (!game.jugador.isMounted || !identical(game.zona, _lugar)) return;
    final vista = game.camera.visibleWorldRect;
    final fuera = vista.inflate(40);

    while (_luciernagas.length < clima.luciernagas) {
      _luciernagas.add(
        _Luciernaga(
          Vector2(
            vista.left + _azar.nextDouble() * vista.width,
            vista.top + _azar.nextDouble() * vista.height,
          ),
          _azar,
        ),
      );
    }
    for (final l in _luciernagas) {
      l.update(dt, _azar);
      // Las que quedan atrás reaparecen en el otro lado de la vista.
      if (!fuera.contains(Offset(l.p.x, l.p.y))) {
        l.p.setValues(
          vista.left + _azar.nextDouble() * vista.width,
          vista.top + _azar.nextDouble() * vista.height,
        );
      }
    }

    // Polillas: hasta tres por cada luz encendida cerca del jugador.
    _buscar -= dt;
    if (clima.polillas && _buscar <= 0) {
      _buscar = 1;
      final luces = _lugar.iluminacion?.fijas ?? const <Luz>[];
      _polillas.removeWhere((p) => !p.luz.encendida);
      for (final luz in luces) {
        if (!luz.encendida || luz.radio < 24) continue;
        if (!vista.inflate(20).contains(Offset(luz.posicion.x, luz.posicion.y))) continue;
        final ya = _polillas.where((p) => identical(p.luz, luz)).length;
        if (ya < 2) _polillas.add(_Polilla(luz, _azar));
      }
      _polillas.removeWhere(
        (p) => !vista.inflate(80).contains(Offset(p.luz.posicion.x, p.luz.posicion.y)),
      );
    }
    for (final p in _polillas) {
      p.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _polillas) {
      p.render(canvas, _t);
    }
    _lugar.children.whereType<VidaSuelo>().firstOrNull?.renderVolando(canvas);
  }

  static const _verde = Color(0xFFD8E070);

  @override
  void pintarBrillo(Canvas canvas) {
    for (final l in _luciernagas) {
      final a = l.brillo(_t);
      if (a > 0.05) puntoBrillante(canvas, l.p.x, l.p.y, _verde, a);
    }
  }

  @override
  void aportarLuces(void Function(Luz luz, Vector2 en) anotar) {
    for (final l in _luciernagas) {
      if (l.brillo(_t) > 0.6) anotar(l.luz, l.p);
    }
  }
}

class _Luciernaga {
  _Luciernaga(this.p, Random azar)
    : _fase = azar.nextDouble() * 10,
      _ritmo = 0.6 + azar.nextDouble() * 0.8;

  final Vector2 p;
  final Vector2 _v = Vector2.zero();
  final double _fase, _ritmo;
  final luz = Luz(Vector2.zero(), radio: 7, tinte: const Color(0xFFD8E070));

  void update(double dt, Random azar) {
    _v.x += (azar.nextDouble() - 0.5) * 40 * dt;
    _v.y += (azar.nextDouble() - 0.5) * 40 * dt;
    _v.clampLength(0, 9);
    p.addScaled(_v, dt);
  }

  /// Se enciende y se apaga despacio, cada una a su ritmo.
  double brillo(double t) => max(0.0, sin(t * _ritmo + _fase)) * 0.95;
}

class _Polilla {
  _Polilla(this.luz, Random azar)
    : _radio = 7 + azar.nextDouble() * 8,
      _vel = (azar.nextBool() ? 1 : -1) * (2.5 + azar.nextDouble() * 2),
      _ang = azar.nextDouble() * 6.28,
      _alto = 4 + azar.nextDouble() * 6;

  final Luz luz;
  final double _radio, _vel, _alto;
  double _ang;

  void update(double dt) => _ang += _vel * dt;

  static const _ala = Color(0xFFC9B8A4);
  static const _cuerpo = Color(0xFF7A6A58);

  void render(Canvas canvas, double t) {
    // Vuela en espiral irregular alrededor de la llama.
    final r = _radio + sin(t * 3.1 + _ang) * 3;
    final x = luz.posicion.x + cos(_ang) * r;
    final y = luz.posicion.y - _alto + sin(_ang * 1.7) * r * 0.5;
    final abierta = (t * 18 + _ang).floor().isEven;
    pixel(canvas, x, y, _cuerpo);
    if (abierta) {
      pixel(canvas, x - 1, y - 1, _ala);
      pixel(canvas, x + 1, y - 1, _ala);
    } else {
      pixel(canvas, x - 1, y, _ala);
      pixel(canvas, x + 1, y, _ala);
    }
  }
}
