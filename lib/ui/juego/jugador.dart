import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'estilo_combate.dart';
import 'umbral_juego.dart';

/// El personaje del jugador. Su `position` son los pies; el sprite se dibuja
/// encima con el ancla abajo al centro.
class Jugador extends PositionComponent with HasGameReference<UmbralJuego> {
  final String rutaSprite;
  final EstiloCombate estilo;

  Jugador({required this.rutaSprite, required this.estilo, required Vector2 pies})
      : super(position: pies, anchor: Anchor.bottomCenter);

  double get radio => 7;
  static const _anchoPies = 12.0;
  static const _altoPies = 5.0;
  static const _invulnerabilidad = 0.7;

  late final SpriteComponent _sprite;
  final Vector2 mirando = Vector2(1, 0);
  double _recarga = 0;
  double _invulnerable = 0;
  double _lento = 0;
  double _paso = 0;

  bool get vivo => game.vida.value > 0;

  /// Centro del cuerpo, para golpes y proyectiles.
  Vector2 get centro => position + Vector2(0, -14);

  @override
  Future<void> onLoad() async {
    _sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(rutaSprite)),
      anchor: Anchor.bottomCenter,
      paint: Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    add(_sprite);
  }

  @override
  void update(double dt) {
    priority = position.y.round();
    if (!vivo) return;

    _recarga = max(0, _recarga - dt);
    _invulnerable = max(0, _invulnerable - dt);
    _lento = max(0, _lento - dt);

    final entrada = game.direccionEntrada;
    if (entrada.length2 > 0.01) {
      final dir = entrada.length > 1 ? entrada.normalized() : entrada;
      mirando.setFrom(dir.normalized());
      final rapidez = estilo.velocidad * (_lento > 0 ? 0.5 : 1);
      _mover(dir.x * rapidez * dt, 0);
      _mover(0, dir.y * rapidez * dt);
      _paso += dt * 12;
    } else {
      _paso = 0;
    }

    // Balanceo de un píxel al caminar y giro según hacia dónde mira.
    _sprite.position.y = (sin(_paso) > 0.3) ? -1 : 0;
    if (mirando.x.abs() > 0.2) _sprite.scale.x = mirando.x < 0 ? -1 : 1;

    // Parpadeo mientras es invulnerable; tono podredumbre si está agarrado.
    final visible = _invulnerable == 0 || (_invulnerable * 20).floor().isEven;
    _sprite.paint.color = visible
        ? const Color(0xFFFFFFFF)
        : const Color(0x55FFFFFF);
    _sprite.paint.colorFilter = _lento > 0
        ? const ColorFilter.mode(Color(0x557F9E45), BlendMode.srcATop)
        : null;

    if (game.atacando && _recarga == 0) _atacar();
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
      if (mirando.x.abs() > 0.2) _sprite.scale.x = mirando.x < 0 ? -1 : 1;
    }
  }

  void _atacar() {
    _recarga = estilo.recarga;
    _apuntar();

    if (estilo.dispara) {
      final (dano, critico) = game.tirarDano();
      game.zona.add(Proyectil(
        origen: centro + mirando * 8,
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
      if (diferencia <= estilo.arco / 2 || hacia.length < e.radio + 4) {
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
    if (ralentiza > 0) _lento = ralentiza;
    game.zona.add(TextoFlotante('-$dano', centro - Vector2(0, 12),
        color: Colores.hueso));
    if (game.vida.value == 0) game.jugadorMuerto();
  }

  /// Vuelve a un punto sin colisiones pendientes ni estados alterados.
  void reaparecer(Vector2 pies) {
    position.setFrom(pies);
    _invulnerable = _invulnerabilidad;
    _lento = 0;
    _recarga = 0;
  }
}
