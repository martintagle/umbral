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
/// se dibuja encima con el ancla de su [hoja] en los pies, a [escalaSprites].
///
/// Además de atacar puede rodar (unas décimas invulnerable, a cambio de
/// estamina) y beber de los frascos de brasa, que curan pero lo dejan
/// expuesto mientras bebe.
class Jugador extends PositionComponent with HasGameReference<UmbralJuego> {
  final Hoja hoja;
  final EstiloCombate estilo;

  Jugador({required this.hoja, required this.estilo, required Vector2 pies})
      : super(position: pies, anchor: Anchor.bottomCenter);

  double get radio => 5;
  static const _anchoPies = 8.0;
  static const _altoPies = 3.0;
  static const _invulnerabilidad = 0.45;
  static const _duracionGolpeado = 0.2;
  static const _duracionAturdido = 0.2;

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

  /// El arma pesada tarda más en caer: la animación dura según la recarga.
  double get _duracionAtaque => min(0.42, max(0.24, estilo.recarga * 0.9));

  /// Fracción de la animación en la que el arma golpea o se suelta el disparo.
  double get _momentoImpacto => _dispara ? 0.45 : 0.4;

  @override
  Future<void> onLoad() async {
    _modelo = ModeloAnimado(hoja, paint: pinturaSprites())
      ..scale = Vector2.all(escalaSprites);
    add(_modelo);
  }

  @override
  void update(double dt) {
    priority = position.y.round();
    if (!vivo) {
      _caida += dt;
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

  /// Elige el cuadro de la hoja según lo que hace. Las acciones duran lo que
  /// dice el juego, no la hoja: sus cuadros se reparten para que el golpe, el
  /// disparo o la cura se vean justo cuando ocurren.
  void _animar() {
    if (!vivo) {
      _modelo.tramo('morir', _caida / hoja['morir'].duracion);
    } else if (rodando) {
      _modelo.tramo('rodar', _rodar / _duracionRodar);
    } else if (_ataque >= 0) {
      final p = _ataque / _duracionAtaque, m = _momentoImpacto;
      if (!_dispara) {
        _tramoConEvento('atacar', p, 'impacto', m);
      } else if (p < m) {
        // Tensa el arco o junta el hechizo; al soltar, sigue el disparo.
        _modelo.tramo('atacar', p / m);
      } else {
        _modelo.tramo('disparo', (p - m) / (1 - m));
      }
    } else if (_golpeado > 0) {
      _modelo.tramo('golpe', 1 - _golpeado / _duracionGolpeado);
    } else if (bebiendo) {
      _tramoConEvento('beber', _beber / _duracionBeber, 'cura', _momentoCura);
    } else if (_paso > 0) {
      _modelo.reproducir('caminar', velocidad: _lento > 0 ? 0.5 : 1);
    } else {
      _modelo.reproducir('quieto');
    }
    _modelo.scale.setValues(_lado * escalaSprites, escalaSprites);
    _pintar();
  }

  /// Muestra [nombre] al [progreso] de la acción, con el cuadro de su
  /// [evento] justo en [momento] (la fracción de la acción en que ocurre).
  void _tramoConEvento(
      String nombre, double progreso, String evento, double momento) {
    final cuadro = hoja[nombre].eventos[evento]!;
    if (progreso < momento) {
      _modelo.tramo(nombre, progreso / momento, hasta: cuadro);
    } else {
      _modelo.tramo(nombre, (progreso - momento) / (1 - momento),
          desde: cuadro);
    }
  }

  void _pintar() {
    // Parpadeo mientras es invulnerable y tono podredumbre si está agarrado.
    // Un golpe recibido en mitad de un ataque no cambia la animación: lo
    // marca un destello blanco.
    final visible = !vivo ||
        _invulnerable == 0 ||
        (_invulnerable * 20).floor().isEven;
    _modelo.paint.color =
        visible ? const Color(0xFFFFFFFF) : const Color(0x55FFFFFF);
    _modelo.paint.colorFilter =
        _ataque >= 0 && _golpeado > _duracionGolpeado - 0.06
            ? const ColorFilter.mode(Colores.hueso, BlendMode.srcATop)
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
        efecto: estilo.efectoProyectil,
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
