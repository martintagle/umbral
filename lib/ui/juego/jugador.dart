import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../sonido.dart';
import '../tema/tema_umbral.dart';
import 'animacion.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'estilo_combate.dart';
import 'umbral_juego.dart';

/// El personaje del jugador. Su `position` son los pies; el modelo animado
/// se dibuja encima con el ancla abajo al centro, a [escalaSprites].
///
/// Además de atacar puede rodar (unas décimas invulnerable, a cambio de
/// estamina) y beber de los frascos de brasa, que curan pero lo dejan
/// expuesto mientras bebe.
class Jugador extends PositionComponent with HasGameReference<UmbralJuego> {
  final String rutaSprite;
  final EstiloCombate estilo;

  Jugador({required this.rutaSprite, required this.estilo, required Vector2 pies})
      : super(position: pies, anchor: Anchor.bottomCenter);

  double get radio => 5;
  static const _anchoPies = 8.0;
  static const _altoPies = 3.0;
  static const _invulnerabilidad = 0.45;
  static const _duracionGolpeado = 0.2;
  static const _duracionAturdido = 0.2;
  static const _duracionCaida = 0.35;

  static const costoRodar = 22.0;
  static const _duracionRodar = 0.45;
  static const _rapidezRodar = 150.0;

  /// Mientras rueda es intocable, salvo al empezar y al levantarse.
  static const _inicioInmune = 0.04;
  static const _finInmune = 0.34;

  static const _duracionBeber = 1.0;
  static const _momentoCura = 0.6;

  /// Un frasco cura esta fracción de la vida máxima.
  static const curaFrasco = 0.45;

  late final ModeloAnimado _modelo;
  final Vector2 mirando = Vector2(1, 0);
  final Vector2 _dirRodar = Vector2(1, 0);
  double _recarga = 0;
  double _invulnerable = 0;
  double _lento = 0;
  double _paso = 0;
  double _golpeado = 0;
  double _aturdido = 0;
  double _caida = 0;
  double _sonidoPaso = 0;
  bool _andando = false;

  /// Tiempo desde que empezó a rodar o a beber; negativo si no lo hace.
  double _rodar = -1;
  double _beber = -1;
  bool _curaPendiente = false;

  /// 1 si mira a la derecha, -1 si a la izquierda.
  double _lado = 1;

  /// Tiempo desde que empezó el ataque en curso; negativo si no hay ninguno.
  double _ataque = -1;
  bool _impactoPendiente = false;

  bool get vivo => game.vida.value > 0;
  bool get rodando => _rodar >= 0;
  bool get bebiendo => _beber >= 0;
  bool get _inmune =>
      _rodar >= _inicioInmune && _rodar <= _finInmune;

  /// Centro del cuerpo, para golpes y proyectiles.
  Vector2 get centro => position + Vector2(0, -8);

  bool get _dispara => estilo.dispara;
  bool get _hechizo => estilo.colorProyectil == Colores.alma;

  /// El arma pesada tarda más en caer: la animación dura según la recarga.
  double get _duracionAtaque => min(0.42, max(0.24, estilo.recarga * 0.9));

  /// Fracción de la animación en la que el arma golpea o se suelta el disparo.
  double get _momentoImpacto => _dispara ? 0.45 : 0.4;

  @override
  Future<void> onLoad() async {
    _modelo = ModeloAnimado(
      sprite: Sprite(game.images.fromCache(rutaSprite)),
      esqueleto: Esqueletos.de(rutaSprite),
      paint: Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    )..scale = Vector2.all(escalaSprites);
    add(_modelo);
  }

  @override
  void update(double dt) {
    priority = position.y.round();
    if (!vivo) {
      _caida = min(_duracionCaida, _caida + dt);
      _sonarPasos(false, dt);
      _animar();
      return;
    }

    _recarga = max(0, _recarga - dt);
    _invulnerable = max(0, _invulnerable - dt);
    _lento = max(0, _lento - dt);
    _golpeado = max(0, _golpeado - dt);
    _aturdido = max(0, _aturdido - dt);

    final entrada = game.direccionEntrada;
    final quiereMoverse = entrada.length2 > 0.01;

    if (game.consumirRodar()) _intentarRodar(entrada);
    if (game.consumirBeber()) _intentarBeber();

    if (rodando) {
      _rodar += dt;
      // Sale disparado y frena al levantarse.
      final k = _rodar / _duracionRodar;
      final rapidez = _rapidezRodar * (1 - k * k);
      _mover(_dirRodar.x * rapidez * dt, 0);
      _mover(0, _dirRodar.y * rapidez * dt);
      _paso = 0;
      if (_rodar >= _duracionRodar) _rodar = -1;
    } else if (_aturdido == 0 && quiereMoverse) {
      final dir = entrada.length > 1 ? entrada.normalized() : entrada;
      // Durante el golpe el personaje no se gira: el tajo sale hacia donde
      // apuntó al empezar.
      if (_ataque < 0) mirando.setFrom(dir.normalized());
      // Atacar frena: el peso del arma se siente. Beber, aún más.
      final rapidez = estilo.velocidad *
          (_lento > 0 ? 0.5 : 1) *
          (_ataque >= 0 ? 0.45 : 1) *
          (bebiendo ? 0.35 : 1);
      _mover(dir.x * rapidez * dt, 0);
      _mover(0, dir.y * rapidez * dt);
      _paso += dt * 12 * (bebiendo ? 0.5 : 1);
    } else {
      _paso = 0;
    }
    _sonarPasos(!rodando && _paso > 0, dt);
    if (mirando.x.abs() > 0.2) _lado = mirando.x < 0 ? -1 : 1;

    if (bebiendo) {
      _beber += dt;
      if (_curaPendiente && _beber >= _duracionBeber * _momentoCura) {
        _curaPendiente = false;
        game.curarConFrasco(curaFrasco);
        game.zona.add(Estallido(centro, const [Colores.brasa, Colores.hueso]));
      }
      if (_beber >= _duracionBeber) _beber = -1;
    }

    if (_ataque >= 0) {
      _ataque += dt;
      if (_impactoPendiente && _ataque >= _duracionAtaque * _momentoImpacto) {
        _impactoPendiente = false;
        _impactar();
      }
      if (_ataque >= _duracionAtaque) _ataque = -1;
    }

    if (game.atacando &&
        _recarga == 0 &&
        _ataque < 0 &&
        !rodando &&
        !bebiendo &&
        _aturdido == 0 &&
        game.gastarEstamina(estilo.costoEstamina)) {
      _empezarAtaque();
    }
    _animar();
  }

  /// Rueda hacia donde apunta la cruceta (o hacia donde mira). Se puede
  /// cortar la recuperación de un ataque, pero no la carga ni un trago.
  void _intentarRodar(Vector2 entrada) {
    if (rodando || bebiendo || _aturdido > 0) return;
    if (_ataque >= 0 && _impactoPendiente) return;
    if (!game.gastarEstamina(costoRodar)) return;
    _ataque = -1;
    _rodar = 0;
    _dirRodar.setFrom(entrada.length2 > 0.01 ? entrada.normalized() : mirando);
    if (_dirRodar.x.abs() > 0.2) _lado = _dirRodar.x < 0 ? -1 : 1;
    mirando.setFrom(_dirRodar);
  }

  void _intentarBeber() {
    if (rodando || bebiendo || _ataque >= 0 || _aturdido > 0) return;
    if (!game.gastarFrasco()) return;
    _beber = 0;
    _curaPendiente = true;
  }

  /// Pasto en el mundo, paso a paso; piedra en los interiores, en bucle.
  void _sonarPasos(bool andando, double dt) {
    final interior = game.zona.interior;
    if (andando != _andando || interior) {
      Sonido.bucle(Audios.pasosPiedra, sonando: andando && interior);
    }
    _andando = andando;
    if (!andando || interior) {
      _sonidoPaso = 0;
      return;
    }
    _sonidoPaso -= dt;
    if (_sonidoPaso <= 0) {
      _sonidoPaso = 0.36;
      Sonido.efecto(Audios.pasoPasto, volumen: 0.35);
    }
  }

  void _mover(double dx, double dy) {
    if (dx == 0 && dy == 0) return;
    final x = position.x + dx, y = position.y + dy;
    if (game.zona.libre(Rect.fromCenter(
        center: Offset(x, y - _altoPies / 2),
        width: _anchoPies,
        height: _altoPies))) {
      position.setValues(x, y);
    }
  }

  /// Postura de todo el cuerpo en este cuadro (desplazamiento, estiramiento e
  /// inclinación). Brazos, piernas y arma se mueven aparte, en el modelo.
  void _animar() {
    var dx = 0.0, dy = 0.0, sx = 1.0, sy = 1.0, giro = 0.0;

    if (!vivo) {
      // Cae de lado hacia atrás.
      final k = _caida / _duracionCaida;
      giro = -_lado * k * pi / 2;
      dy = k * 2;
    } else if (rodando) {
      // Voltereta hacia delante, hecho un ovillo.
      final k = (_rodar / _duracionRodar).clamp(0.0, 1.0);
      giro = _lado * 2 * pi * _suavizar(k);
      final ovillo = sin(k * pi);
      sx = 1 - 0.15 * ovillo;
      sy = 1 - 0.3 * ovillo;
      // El modelo gira sobre los pies: se compensa para que gire sobre el
      // centro del cuerpo.
      final medio = _modelo.size.y * escalaSprites * sy / 2;
      dx = -medio * sin(giro);
      dy = -medio + medio * cos(giro);
    } else if (_ataque >= 0) {
      final p = _ataque / _duracionAtaque;
      final m = _momentoImpacto;
      final d = mirando;
      if (p < m) {
        // Anticipación: se echa hacia atrás y se encoge.
        final k = p / m;
        dx = -d.x * 1 * k;
        dy = -d.y * 1 * k;
        sx = 1 + 0.06 * k;
        sy = 1 - 0.06 * k;
        if (_hechizo) dy -= 2 * k;
      } else {
        // Golpe y recuperación: se lanza hacia delante y vuelve.
        final k = (p - m) / (1 - m);
        final empuje = k < 0.35 ? k / 0.35 : 1 - (k - 0.35) / 0.65;
        final alcance = _dispara ? -1.0 : 2.5; // el arco y el libro retroceden
        dx = d.x * alcance * empuje;
        dy = d.y * alcance * empuje;
        sx = 1 - 0.05 * empuje;
        sy = 1 + 0.05 * empuje;
        giro = _lado * (_dispara ? -0.04 : 0.12) * empuje;
        if (_hechizo) dy -= 2 * (1 - k);
      }
    }

    if (_golpeado > 0) {
      final k = _golpeado / _duracionGolpeado;
      dx += ((_golpeado * 60).floor().isEven ? 0.5 : -0.5) * k;
      sx += 0.1 * k;
      sy -= 0.1 * k;
    }

    _modelo
      ..paso = _paso
      ..andar = _paso > 0 ? (bebiendo ? 0.4 : 1) : 0
      ..ataque = _ataque >= 0 ? _ataque / _duracionAtaque : -1
      ..impacto = _momentoImpacto
      ..bebiendo = bebiendo ? _beber / _duracionBeber : -1
      ..position.setValues(dx, dy)
      ..scale.setValues(_lado * escalaSprites * sx, escalaSprites * sy)
      ..angle = giro;
    _pintar();
  }

  static double _suavizar(double k) => k * k * (3 - 2 * k);

  void _pintar() {
    // Parpadeo mientras es invulnerable; tono podredumbre si está agarrado;
    // destello blanco al recibir el golpe, brillo de alma al conjurar y de
    // brasa al beber.
    final visible = !vivo ||
        _invulnerable == 0 ||
        (_invulnerable * 20).floor().isEven;
    _modelo.paint.color = visible
        ? Color.fromRGBO(255, 255, 255, vivo ? 1 : 1 - _caida * 1.2)
        : const Color(0x55FFFFFF);
    final conjurando = _hechizo &&
        _ataque >= 0 &&
        _ataque < _duracionAtaque * _momentoImpacto;
    _modelo.paint.colorFilter = _golpeado > _duracionGolpeado - 0.06
        ? const ColorFilter.mode(Colores.hueso, BlendMode.srcATop)
        : conjurando
            ? const ColorFilter.mode(Color(0x885AA0B8), BlendMode.srcATop)
            : bebiendo && !_curaPendiente
                ? const ColorFilter.mode(Color(0x66E08A2C), BlendMode.srcATop)
                : _lento > 0
                    ? const ColorFilter.mode(
                        Color(0x557F9E45), BlendMode.srcATop)
                    : null;
  }

  /// Orienta el ataque hacia el enemigo más cercano dentro del alcance.
  void _apuntar() {
    Enemigo? objetivo;
    var mejor = estilo.autoapuntado;
    for (final e in game.zona.enemigosVivos) {
      final d = e.centro.distanceTo(centro) - e.radio;
      if (d < mejor) {
        mejor = d;
        objetivo = e;
      }
    }
    if (objetivo != null) {
      mirando.setFrom((objetivo.centro - centro).normalized());
      if (mirando.x.abs() > 0.2) _lado = mirando.x < 0 ? -1 : 1;
    }
  }

  void _empezarAtaque() {
    _recarga = estilo.recarga;
    _ataque = 0;
    _impactoPendiente = true;
    _apuntar();
    Sonido.efecto(Audios.ataque(game.personaje.claseCodigo), volumen: 0.8);
  }

  /// El instante en que el arma toca o el disparo sale.
  void _impactar() {
    if (estilo.dispara) {
      final (dano, critico) = game.tirarDano();
      game.zona.add(Proyectil(
        origen: centro + mirando * 5,
        direccion: mirando.clone(),
        rapidez: estilo.velocidadProyectil,
        distanciaMaxima: estilo.distanciaProyectil,
        dano: dano,
        critico: critico,
        delJugador: true,
        tamano: estilo.tamanoProyectil,
        color: estilo.colorProyectil,
      ));
      return;
    }

    final angulo = atan2(mirando.y, mirando.x);
    game.zona.add(Tajo(centro.clone(),
        direccion: angulo, arco: estilo.arco, radio: estilo.alcance * 0.8));
    for (final e in game.zona.enemigosVivos.toList()) {
      final hacia = e.centro - centro;
      if (hacia.length > estilo.alcance + e.radio) continue;
      var diferencia = (atan2(hacia.y, hacia.x) - angulo).abs();
      if (diferencia > pi) diferencia = 2 * pi - diferencia;
      // Muy pegado al cuerpo siempre acierta, aunque quede detrás del arco.
      if (diferencia <= estilo.arco / 2 || hacia.length < e.radio + 3) {
        final (dano, critico) = game.tirarDano();
        e.recibirGolpe(dano, critico, hacia.normalized());
      }
    }
  }

  /// Un golpe de [desde]: quita vida, aturde un instante y empuja. Rodando a
  /// tiempo no hace nada; bebiendo, se pierde el trago.
  void recibirGolpe(int danoEnemigo, {double ralentiza = 0, Vector2? desde}) {
    if (!vivo || _invulnerable > 0 || _inmune) return;
    final dano = game.danoRecibido(danoEnemigo);
    game.vida.value = max(0, game.vida.value - dano);
    _invulnerable = _invulnerabilidad;
    _golpeado = _duracionGolpeado;
    _aturdido = _duracionAturdido;
    if (bebiendo && _curaPendiente) _beber = -1;
    if (ralentiza > 0) _lento = ralentiza;
    if (desde != null) {
      final empuje = position - desde;
      if (empuje.length2 > 0) {
        empuje.normalize();
        _mover(empuje.x * 6, 0);
        _mover(0, empuje.y * 6);
      }
    }
    Sonido.efecto(Audios.dano(game.personaje.apariencia));
    game.zona.add(TextoFlotante('-$dano', centro - Vector2(0, 8),
        color: Colores.sangre));
    if (game.vida.value == 0) {
      _ataque = -1;
      _rodar = -1;
      _beber = -1;
      _caida = 0;
      game.jugadorMuerto();
    }
  }

  /// Vuelve a un punto sin colisiones pendientes ni estados alterados.
  void reaparecer(Vector2 pies) {
    position.setFrom(pies);
    _invulnerable = _invulnerabilidad;
    _lento = 0;
    _recarga = 0;
    _golpeado = 0;
    _aturdido = 0;
    _caida = 0;
    _ataque = -1;
    _rodar = -1;
    _beber = -1;
  }
}
