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
  static const _duracionGolpe = 0.28;
  static const _duracionDisparo = 0.3;
  static const _duracionHerido = 0.16;
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

  /// 1 si mira a la derecha, -1 si a la izquierda.
  double _lado = 1;

  /// Hacia el jugador al atacar, para lanzar el cuerpo en esa dirección.
  final Vector2 _haciaAtaque = Vector2.zero();

  // Tiempo restante de cada animación; 0 si no está en curso.
  double _golpe = 0;
  double _disparo = 0;
  double _herido = 0;
  final Vector2 _empuje = Vector2.zero();

  bool get vivo => vida > 0;
  double get radio => tipo.radio;

  /// Las criaturas voladoras flotan más arriba que las que caminan.
  Vector2 get centro => position + Vector2(0, -tipo.alturaCentro);

  @override
  Future<void> onLoad() async {
    _sprite = SpriteComponent(
      sprite: Sprite(game.images.fromCache(tipo.sprite)),
      anchor: Anchor.bottomCenter,
      scale: Vector2.all(escalaSprites),
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
    _golpe = max(0, _golpe - dt);
    _disparo = max(0, _disparo - dt);
    _herido = max(0, _herido - dt);

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
          _mirarA(hacia);
        } else {
          _moverHacia(position + hacia, tipo.velocidad, dt);
        }
      case _Estado.preparar:
        _temporizador -= dt;
        _mirarA(hacia);
        if (_temporizador <= 0) _atacar(hacia);
      case _Estado.embestir:
        _temporizador -= dt;
        _intentarMover(_direccionEmbestida * tipo.embestida * dt);
        if (!_embestidaAcerto &&
            jugador.centro.distanceTo(centro) <= radio + jugador.radio + 2) {
          _embestidaAcerto = true;
          _morder();
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
    _animar();
  }

  void _mirarA(Vector2 hacia) {
    if (hacia.x.abs() > 0.5) _lado = hacia.x < 0 ? -1 : 1;
  }

  void _atacar(Vector2 hacia) {
    final jugador = game.jugador;
    _haciaAtaque.setFrom(hacia.normalized());
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
      _disparo = _duracionDisparo;
      _recuperar();
    } else if (tipo.embestida > 0) {
      _direccionEmbestida.setFrom(_haciaAtaque);
      _embestidaAcerto = false;
      _estado = _Estado.embestir;
      _temporizador = (tipo.alcance + 6) / tipo.embestida;
    } else {
      _golpe = _duracionGolpe;
      // Si el jugador se apartó durante el aviso, el golpe falla.
      if (hacia.length <= tipo.alcance + jugador.radio + 3) {
        _morder();
        jugador.recibirGolpe(tipo.dano, ralentiza: tipo.ralentiza);
      }
      _recuperar();
    }
  }

  /// Marca de garras o dientes sobre el jugador.
  void _morder() {
    final jugador = game.jugador;
    if (!jugador.vivo) return;
    game.zona.add(Zarpazo(jugador.centro.clone(), haciaLaDerecha: _lado > 0));
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
    if (dir.x.abs() > 0.2) _lado = dir.x < 0 ? -1 : 1;
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
          Rect.fromCenter(
              center: Offset(x, y - 2), width: radio * 1.5, height: 4),
          enemigo: true)) {
        position.setValues(x, y);
      }
    }
  }

  /// Evita que varios enemigos se apilen en el mismo punto.
  void _separarDeOtros(double dt) {
    for (final otro in game.zona.enemigosVivos) {
      if (identical(otro, this)) continue;
      final minimo = radio + otro.radio;
      final d = position - otro.position;
      final l = d.length;
      if (l > 0 && l < minimo) _intentarMover(d / l * (minimo - l) * dt * 6);
    }
  }

  /// Postura del sprite según el estado: se agazapa y tiembla antes de
  /// atacar, se estira al embestir, se lanza al golpear, retrocede al
  /// disparar y se aplasta al recibir daño.
  void _animar() {
    var dx = 0.0, dy = 0.0, sx = 1.0, sy = 1.0, giro = 0.0;
    if (tipo.vuela) dy = (sin(_t * 4) * 1.5).roundToDouble() - 2;
    final d = _haciaAtaque;

    switch (_estado) {
      case _Estado.preparar:
        final k = (1 - _temporizador / tipo.preparacion).clamp(0.0, 1.0);
        sx = 1 + 0.16 * k;
        sy = 1 - 0.2 * k;
        dx = -_lado * 1.5 * k + ((_t * 30).floor().isEven ? 0.5 : -0.5) * k;
        giro = -_lado * 0.12 * k;
      case _Estado.embestir:
        sx = 1.25;
        sy = 0.85;
        giro = _lado * 0.18;
      default:
        break;
    }

    if (_golpe > 0) {
      final p = 1 - _golpe / _duracionGolpe;
      final k = p < 0.3 ? p / 0.3 : 1 - (p - 0.3) / 0.7;
      dx += d.x * 4 * k;
      dy += d.y * 3 * k;
      sx += 0.18 * k;
      sy -= 0.08 * k;
      giro += _lado * 0.2 * k;
    }
    if (_disparo > 0) {
      final k = _disparo / _duracionDisparo;
      dx -= d.x * 2 * k;
      dy -= d.y * 2 * k;
      sx += 0.18 * k;
      sy += 0.18 * k;
    }
    if (_herido > 0) {
      final k = _herido / _duracionHerido;
      dx += _empuje.x * 2 * k;
      sx += 0.18 * k;
      sy -= 0.18 * k;
    }

    final avisando = _estado == _Estado.preparar && (_t * 16).floor().isEven;
    _sprite
      ..position.setValues(dx, dy)
      ..scale.setValues(_lado * escalaSprites * sx, escalaSprites * sy)
      ..angle = giro;
    _sprite.paint.colorFilter = _destello > 0
        ? const ColorFilter.mode(Colores.hueso, BlendMode.srcATop)
        : avisando
            ? const ColorFilter.mode(Color(0xAAE08A2C), BlendMode.srcATop)
            : null;
  }

  void recibirGolpe(int dano, bool critico, Vector2 empuje) {
    if (!vivo) return;
    vida -= dano;
    _sinDano = 0;
    _destello = 0.08;
    _herido = _duracionHerido;
    _empuje.setFrom(empuje);
    game.zona.add(TextoFlotante(
        critico ? '$dano!' : '$dano', centro - Vector2(0, 7),
        color: critico ? Colores.brasa : Colores.hueso));
    if (_estado == _Estado.deambular || _estado == _Estado.volver) {
      _estado = _Estado.perseguir;
    }
    if (_estado != _Estado.embestir) _intentarMover(empuje * 4);
    if (vida <= 0) {
      vida = 0;
      game.enemigoDerrotado(this);
      game.zona
        ..add(Desvanecer(_sprite.sprite!, position.clone(), _lado))
        ..add(Estallido(centro, const [
          Colores.sangre,
          Colores.hueso,
          Colores.ceniza,
          Colores.abismo,
        ]));
      removeFromParent();
    }
  }
}
