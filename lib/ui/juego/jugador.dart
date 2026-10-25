import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'estilo_combate.dart';
import 'umbral_juego.dart';

/// El personaje del jugador. Su `position` son los pies; el sprite se dibuja
/// encima con el ancla abajo al centro, a [escalaSprites].
class Jugador extends PositionComponent with HasGameReference<UmbralJuego> {
  final String rutaSprite;
  final EstiloCombate estilo;

  Jugador({required this.rutaSprite, required this.estilo, required Vector2 pies})
      : super(position: pies, anchor: Anchor.bottomCenter);

  double get radio => 5;
  static const _anchoPies = 8.0;
  static const _altoPies = 3.0;
  static const _invulnerabilidad = 0.7;
  static const _duracionGolpeado = 0.2;
  static const _duracionCaida = 0.35;

  late final SpriteComponent _sprite;
  final Vector2 mirando = Vector2(1, 0);
  double _recarga = 0;
  double _invulnerable = 0;
  double _lento = 0;
  double _paso = 0;
  double _golpeado = 0;
  double _caida = 0;

  /// 1 si mira a la derecha, -1 si a la izquierda.
  double _lado = 1;

  /// Tiempo desde que empezó el ataque en curso; negativo si no hay ninguno.
  double _ataque = -1;
  bool _impactoPendiente = false;

  bool get vivo => game.vida.value > 0;

  /// Centro del cuerpo, para golpes y proyectiles.
  Vector2 get centro => position + Vector2(0, -8);

  bool get _dispara => estilo.dispara;
  bool get _hechizo => estilo.colorProyectil == Colores.alma;

  /// Dura menos que la recarga para que se pueda encadenar el siguiente.
  double get _duracionAtaque => min(0.32, estilo.recarga * 0.9);

  /// Fracción de la animación en la que el arma golpea o se suelta el disparo.
  double get _momentoImpacto => _dispara ? 0.4 : 0.3;

  @override
  Future<void> onLoad() async {
    _sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(rutaSprite)),
      anchor: Anchor.bottomCenter,
      scale: Vector2.all(escalaSprites),
      paint: Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    add(_sprite);
  }

  @override
  void update(double dt) {
    priority = position.y.round();
    if (!vivo) {
      _caida = min(_duracionCaida, _caida + dt);
      _animar();
      return;
    }

    _recarga = max(0, _recarga - dt);
    _invulnerable = max(0, _invulnerable - dt);
    _lento = max(0, _lento - dt);
    _golpeado = max(0, _golpeado - dt);

    final entrada = game.direccionEntrada;
    if (entrada.length2 > 0.01) {
      final dir = entrada.length > 1 ? entrada.normalized() : entrada;
      // Durante el golpe el personaje no se gira: el tajo sale hacia donde
      // apuntó al empezar.
      if (_ataque < 0) mirando.setFrom(dir.normalized());
      // Atacar frena: el peso del arma se siente.
      final rapidez = estilo.velocidad *
          (_lento > 0 ? 0.5 : 1) *
          (_ataque >= 0 ? 0.45 : 1);
      _mover(dir.x * rapidez * dt, 0);
      _mover(0, dir.y * rapidez * dt);
      _paso += dt * 12;
    } else {
      _paso = 0;
    }
    if (mirando.x.abs() > 0.2) _lado = mirando.x < 0 ? -1 : 1;

    if (_ataque >= 0) {
      _ataque += dt;
      if (_impactoPendiente && _ataque >= _duracionAtaque * _momentoImpacto) {
        _impactoPendiente = false;
        _impactar();
      }
      if (_ataque >= _duracionAtaque) _ataque = -1;
    }

    if (game.atacando && _recarga == 0 && _ataque < 0 &&
        game.gastarEstamina(estilo.costoEstamina)) {
      _empezarAtaque();
    }
    _animar();
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

  /// Postura del sprite en este cuadro: desplazamiento, estiramiento e
  /// inclinación según lo que esté haciendo. Todo se calcula a partir de los
  /// temporizadores, sin estado propio.
  void _animar() {
    var dx = 0.0, dy = 0.0, sx = 1.0, sy = 1.0, giro = 0.0;

    if (!vivo) {
      // Cae de lado hacia atrás.
      final k = _caida / _duracionCaida;
      giro = -_lado * k * pi / 2;
      dy = k * 2;
    } else if (_ataque >= 0) {
      final p = _ataque / _duracionAtaque;
      final m = _momentoImpacto;
      final d = mirando;
      if (p < m) {
        // Anticipación: se echa hacia atrás y se encoge.
        final k = p / m;
        dx = -d.x * 1.5 * k;
        dy = -d.y * 1.5 * k;
        sx = 1 + 0.12 * k;
        sy = 1 - 0.12 * k;
        giro = -_lado * 0.22 * k;
        if (_hechizo) dy -= 2 * k;
      } else {
        // Golpe y recuperación: se lanza hacia delante y vuelve.
        final k = (p - m) / (1 - m);
        final empuje = k < 0.35 ? k / 0.35 : 1 - (k - 0.35) / 0.65;
        final alcance = _dispara ? -1.5 : 3.5; // el arco y el libro retroceden
        dx = d.x * alcance * empuje;
        dy = d.y * alcance * empuje;
        sx = 1 - 0.1 * empuje;
        sy = 1 + 0.1 * empuje;
        giro = _lado * (_dispara ? -0.08 : 0.26) * empuje;
        if (_hechizo) dy -= 2 * (1 - k);
      }
    } else if (_paso > 0) {
      // Balanceo de un píxel al caminar.
      if (sin(_paso) > 0.3) dy = -1;
      giro = sin(_paso * 0.5) * 0.06;
    }

    if (_golpeado > 0) {
      final k = _golpeado / _duracionGolpeado;
      dx += ((_golpeado * 60).floor().isEven ? 0.5 : -0.5) * k;
      sx += 0.1 * k;
      sy -= 0.1 * k;
    }

    _sprite
      ..position.setValues(dx, dy)
      ..scale.setValues(_lado * escalaSprites * sx, escalaSprites * sy)
      ..angle = giro;
    _pintar();
  }

  void _pintar() {
    // Parpadeo mientras es invulnerable; tono podredumbre si está agarrado;
    // destello blanco al recibir el golpe y brillo de alma al conjurar.
    final visible = !vivo ||
        _invulnerable == 0 ||
        (_invulnerable * 20).floor().isEven;
    _sprite.paint.color = visible
        ? Color.fromRGBO(255, 255, 255, vivo ? 1 : 1 - _caida * 1.2)
        : const Color(0x55FFFFFF);
    final conjurando = _hechizo &&
        _ataque >= 0 &&
        _ataque < _duracionAtaque * _momentoImpacto;
    _sprite.paint.colorFilter = _golpeado > _duracionGolpeado - 0.06
        ? const ColorFilter.mode(Colores.hueso, BlendMode.srcATop)
        : conjurando
            ? const ColorFilter.mode(Color(0x885AA0B8), BlendMode.srcATop)
            : _lento > 0
                ? const ColorFilter.mode(Color(0x557F9E45), BlendMode.srcATop)
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

  void recibirGolpe(int danoEnemigo, {double ralentiza = 0}) {
    if (!vivo || _invulnerable > 0) return;
    final dano = game.danoRecibido(danoEnemigo);
    game.vida.value = max(0, game.vida.value - dano);
    _invulnerable = _invulnerabilidad;
    _golpeado = _duracionGolpeado;
    if (ralentiza > 0) _lento = ralentiza;
    game.zona.add(TextoFlotante('-$dano', centro - Vector2(0, 8),
        color: Colores.hueso));
    if (game.vida.value == 0) {
      _ataque = -1;
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
    _caida = 0;
    _ataque = -1;
  }
}
