import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

enum _Estado { deambular, perseguir, preparar, embestir, recuperar, volver }

class Enemigo extends PositionComponent with HasGameReference<UmbralJuego> {
  final TipoEnemigo tipo;
  final Vector2 hogar;

  Enemigo(this.tipo, Vector2 pies)
      : hogar = pies.clone(),
        super(position: pies.clone());

  static const _distanciaMaximaDelHogar = 200.0;
  static final _azar = Random();

  late final SpriteComponent _sprite;
  late double vida = tipo.vida.toDouble();
  _Estado _estado = _Estado.deambular;
  double _temporizador = 0;
  double _sinDano = 10;
  double _destello = 0;
  double _t = _azar.nextDouble() * 10;
  final Vector2 _destino = Vector2.zero();
  final Vector2 _direccionEmbestida = Vector2.zero();
  bool _embestidaAcerto = false;

  bool get vivo => vida > 0;
  double get radio => 9;

  /// Las criaturas voladoras flotan más arriba que las que caminan.
  Vector2 get centro => position + Vector2(0, tipo.vuela ? -18 : -12);

  @override
  Future<void> onLoad() async {
    _sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(tipo.sprite)),
      anchor: Anchor.bottomCenter,
      paint: Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    add(_sprite);
    _nuevoDestino();
  }

  @override
  void update(double dt) {
    priority = position.y.round();
    if (!vivo) return;
    _t += dt;
    _sinDano += dt;
    _destello = max(0, _destello - dt);

    if (tipo.regeneracion > 0 && _sinDano > 2 && vida < tipo.vida) {
      vida = min(tipo.vida.toDouble(), vida + tipo.regeneracion * dt);
    }

    final jugador = game.jugador;
    final hacia = jugador.centro - centro;
    final distancia = hacia.length;
    final alcanceReal = tipo.alcance + jugador.radio;

    switch (_estado) {
      case _Estado.deambular:
        _temporizador -= dt;
        if (_temporizador <= 0) _nuevoDestino();
        _moverHacia(_destino, tipo.velocidad * 0.35, dt);
        if (jugador.vivo && distancia < tipo.deteccion) {
          _estado = _Estado.perseguir;
        }
      case _Estado.perseguir:
        if (!jugador.vivo ||
            position.distanceTo(hogar) > _distanciaMaximaDelHogar) {
          _estado = _Estado.volver;
        } else if (tipo.ataque == Ataque.distancia && distancia < tipo.alcance * 0.45) {
          // Los que atacan de lejos se apartan si los acorralas.
          _moverHacia(position - hacia, tipo.velocidad, dt);
        } else if (distancia <= alcanceReal) {
          _estado = _Estado.preparar;
          _temporizador = tipo.preparacion;
        } else {
          _moverHacia(position + hacia, tipo.velocidad, dt);
        }
      case _Estado.preparar:
        _temporizador -= dt;
        if (_temporizador <= 0) _atacar(hacia);
      case _Estado.embestir:
        _temporizador -= dt;
        _intentarMover(_direccionEmbestida * tipo.embestida * dt);
        if (!_embestidaAcerto &&
            jugador.centro.distanceTo(centro) <= radio + jugador.radio + 2) {
          _embestidaAcerto = true;
          jugador.recibirGolpe(tipo.dano);
        }
        if (_temporizador <= 0) _recuperar();
      case _Estado.recuperar:
        _temporizador -= dt;
        if (_temporizador <= 0) _estado = _Estado.perseguir;
      case _Estado.volver:
        _moverHacia(hogar, tipo.velocidad, dt);
        if (position.distanceTo(hogar) < 4) {
          vida = tipo.vida.toDouble();
          _estado = _Estado.deambular;
        } else if (jugador.vivo &&
            distancia < tipo.deteccion * 0.6 &&
            position.distanceTo(hogar) < _distanciaMaximaDelHogar * 0.7) {
          _estado = _Estado.perseguir;
        }
    }

    _separarDeOtros(dt);
    _pintar();
  }

  void _atacar(Vector2 hacia) {
    final jugador = game.jugador;
    if (tipo.ataque == Ataque.distancia) {
      game.zona.add(Proyectil(
        origen: centro.clone(),
        direccion: hacia.clone(),
        rapidez: tipo.id == 'larva-cirio' ? 80 : 110,
        distanciaMaxima: tipo.alcance * 1.4,
        dano: tipo.dano,
        delJugador: false,
        tamano: tipo.id == 'larva-cirio' ? 3 : 2,
        color: tipo.colorProyectil,
      ));
      _recuperar();
    } else if (tipo.embestida > 0) {
      _direccionEmbestida.setFrom(hacia.normalized());
      _embestidaAcerto = false;
      _estado = _Estado.embestir;
      _temporizador = (tipo.alcance + 6) / tipo.embestida;
    } else {
      // Si el jugador se apartó durante el aviso, el golpe falla.
      if (hacia.length <= tipo.alcance + jugador.radio + 3) {
        jugador.recibirGolpe(tipo.dano, ralentiza: tipo.ralentiza);
      }
      _recuperar();
    }
  }

  void _recuperar() {
    _estado = _Estado.recuperar;
    _temporizador = tipo.recarga;
  }

  void _nuevoDestino() {
    final a = _azar.nextDouble() * pi * 2;
    final r = _azar.nextDouble() * 40;
    _destino.setValues(hogar.x + cos(a) * r, hogar.y + sin(a) * r);
    _temporizador = 2 + _azar.nextDouble() * 2;
  }

  void _moverHacia(Vector2 objetivo, double rapidez, double dt) {
    final hacia = objetivo - position;
    if (hacia.length < 1) return;
    final dir = hacia.normalized();
    if (tipo.erratico > 0) {
      // Zigzag perpendicular a la dirección de avance.
      final lado = Vector2(-dir.y, dir.x) * (sin(_t * 6) * tipo.erratico);
      dir.add(lado);
    }
    _intentarMover(dir * rapidez * dt);
    if (dir.x.abs() > 0.2) _sprite.scale.x = dir.x < 0 ? -1 : 1;
  }

  void _intentarMover(Vector2 paso) {
    if (tipo.vuela) {
      position.add(paso);
      game.zona.limitar(position);
      return;
    }
    for (final (dx, dy) in [(paso.x, 0.0), (0.0, paso.y)]) {
      final x = position.x + dx, y = position.y + dy;
      if (game.zona.libre(
          Rect.fromCenter(center: Offset(x, y - 3), width: 14, height: 6))) {
        position.setValues(x, y);
      }
    }
  }

  /// Evita que varios enemigos se apilen en el mismo punto.
  void _separarDeOtros(double dt) {
    for (final otro in game.zona.enemigosVivos) {
      if (identical(otro, this)) continue;
      final d = position - otro.position;
      final l = d.length;
      if (l > 0 && l < 16) _intentarMover(d / l * (16 - l) * dt * 6);
    }
  }

  void _pintar() {
    final avisando = _estado == _Estado.preparar && (_t * 16).floor().isEven;
    _sprite.paint.colorFilter = _destello > 0
        ? const ColorFilter.mode(Colores.hueso, BlendMode.srcATop)
        : avisando
            ? const ColorFilter.mode(Color(0xAAE08A2C), BlendMode.srcATop)
            : null;
    _sprite.position.y = tipo.vuela ? (sin(_t * 4) * 2).roundToDouble() - 4 : 0;
  }

  void recibirGolpe(int dano, bool critico, Vector2 empuje) {
    if (!vivo) return;
    vida -= dano;
    _sinDano = 0;
    _destello = 0.08;
    game.zona.add(TextoFlotante(
        critico ? '$dano!' : '$dano', centro - Vector2(0, 10),
        color: critico ? Colores.brasa : Colores.hueso));
    if (_estado == _Estado.deambular || _estado == _Estado.volver) {
      _estado = _Estado.perseguir;
    }
    if (_estado != _Estado.embestir) _intentarMover(empuje * 5);
    if (vida <= 0) {
      vida = 0;
      game.enemigoDerrotado(this);
      game.zona.add(Estallido(centro, const [
        Colores.sangre,
        Colores.hueso,
        Colores.ceniza,
        Colores.abismo,
      ]));
      removeFromParent();
    }
  }
}
