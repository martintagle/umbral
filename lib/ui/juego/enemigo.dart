import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../sonido.dart';
import '../tema/tema_umbral.dart';
import 'animacion.dart';
import 'efectos.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

enum _Estado {
  deambular,
  perseguir,
  preparar,
  embestir,
  recuperar,
  volver,
  aturdido,
  enfurecerse,
}

/// Qué golpe se está preparando. Las criaturas comunes tienen uno; el Rey
/// Hueco elige según la distancia.
enum _Golpe { cuerpo, embestida, disparo, barrido, lluvia }

class Enemigo extends PositionComponent with HasGameReference<UmbralJuego> {
  final TipoEnemigo tipo;
  final Vector2 hogar;

  /// Multiplica la vida de [tipo]; el daño crece algo menos. Lo da
  /// [UmbralJuego.fuerzaEnemigos] según el nivel del jugador.
  final double fuerza;

  Enemigo(this.tipo, Vector2 pies, {this.fuerza = 1})
      : hogar = pies.clone(),
        super(position: pies.clone());

  static const _distanciaMaximaDelHogar = 260.0;
  static const _duracionGolpe = 0.28;
  static const _duracionDisparo = 0.3;
  static const _duracionHerido = 0.16;
  static const _duracionAturdido = 0.35;
  static final _azar = Random();

  late final Hoja _hoja = Hojas.de(tipo.hoja);
  late final ModeloAnimado _modelo;

  /// Animación al desplazarse: las voladoras vuelan o aletean.
  late final String _animacionMover = ['volar', 'aletear', 'caminar']
      .firstWhere(_hoja.tiene, orElse: () => 'quieto');
  late double vida = vidaMaxima;
  _Estado _estado = _Estado.deambular;
  _Golpe _golpeElegido = _Golpe.cuerpo;
  double _temporizador = 0;
  double _preparacionTotal = 1;
  double _sinDano = 10;
  double _destello = 0;
  double _t = _azar.nextDouble() * 10;
  final Vector2 _destino = Vector2.zero();
  final Vector2 _direccionEmbestida = Vector2.zero();
  final Vector2 _antes = Vector2.zero();
  bool _embestidaAcerto = false;
  double _embestidaTotal = 1;
  int _comboRestante = 0;

  /// Qué golpe del combo se avisa ahora y cuál acaba de impactar (1, 2...),
  /// para mostrar su tramo de la animación.
  int _numeroGolpe = 1;
  int _numeroImpacto = 1;

  /// Se aparta del jugador (los que atacan de lejos).
  bool _huyendo = false;

  /// El jefe ya hizo su transición a media vida.
  bool _enfurecido = false;

  /// Retrocesos recientes: tras varios seguidos la criatura deja de
  /// inmutarse un momento, para que no se la pueda encadenar sin fin.
  double _retrocesos = 0;

  /// 1 si mira a la derecha, -1 si a la izquierda.
  double _lado = 1;

  /// Hacia el jugador al atacar, para lanzar el cuerpo en esa dirección.
  final Vector2 _haciaAtaque = Vector2.zero();

  // Tiempo restante de cada animación; 0 si no está en curso.
  double _golpe = 0;
  double _disparo = 0;
  double _herido = 0;

  /// El final del salto del rey: se levanta tras aplastar.
  double _aterrizaje = 0;

  bool get vivo => vida > 0;
  double get radio => tipo.radio;
  double get vidaMaxima => tipo.vida * fuerza;
  int get dano => (tipo.dano * (1 + (fuerza - 1) * 0.6)).round();

  /// Ya vio al jugador y pelea (para el jefe: la niebla y la barra de vida).
  bool get despierto =>
      vivo && _estado != _Estado.deambular && _estado != _Estado.volver;

  /// Un jefe a media vida: más rápido y con más golpes.
  bool get furioso => tipo.jefe && vida < vidaMaxima / 2;

  double get _velocidad => tipo.velocidad * (furioso ? 1.35 : 1);
  double get _preparacion => tipo.preparacion * (furioso ? 0.75 : 1);

  /// Las criaturas voladoras flotan más arriba que las que caminan.
  Vector2 get centro => position + Vector2(0, -tipo.alturaCentro);

  bool get _regenerando =>
      tipo.regeneracion > 0 && _sinDano > 2 && vida < vidaMaxima;

  /// El salto del rey trae en una sola fila el aviso, el vuelo y la caída
  /// (eventos `despega` y `aterriza`); la fauce tiene filas separadas.
  bool get _saltoCompleto =>
      _hoja.tiene('salto') && _hoja['salto'].eventos.containsKey('despega');

  /// Fila del cuerpo lanzado en una embestida: el salto de la fauce o del
  /// sapo; las que no saltan (gusano, gárgola, caballo) usan su ataque.
  String get _animacionEmbestida =>
      _hoja.tiene('salto') ? 'salto' : tipo.animacionAtaque;

  /// Fila con el golpe o el disparo que se está usando.
  String get _animacionAtaque =>
      _golpeElegido == _Golpe.lluvia ? 'lluvia' : tipo.animacionAtaque;

  @override
  Future<void> onLoad() async {
    _modelo = ModeloAnimado(_hoja, paint: pinturaSprites())
      ..scale = Vector2.all(escalaSprites);
    add(_modelo);
    _nuevoDestino();
  }

  @override
  void update(double dt) {
    priority = position.y.round();
    if (!vivo) return;
    _antes.setFrom(position);
    _t += dt;
    _sinDano += dt;
    _destello = max(0, _destello - dt);
    _golpe = max(0, _golpe - dt);
    _disparo = max(0, _disparo - dt);
    _herido = max(0, _herido - dt);
    _aterrizaje = max(0, _aterrizaje - dt);
    _retrocesos = max(0, _retrocesos - dt * 0.8);
    _huyendo = false;

    if (_regenerando) {
      vida = min(vidaMaxima, vida + tipo.regeneracion * dt);
    }

    final jugador = game.jugador;
    final hacia = jugador.centro - centro;
    final distancia = hacia.length;

    // A media vida el jefe se detiene a enfurecerse antes de seguir.
    if (furioso &&
        !_enfurecido &&
        _hoja.tiene('enfurecerse') &&
        (_estado == _Estado.perseguir || _estado == _Estado.recuperar)) {
      _enfurecido = true;
      _estado = _Estado.enfurecerse;
      _temporizador = _hoja['enfurecerse'].duracion;
    }

    switch (_estado) {
      case _Estado.deambular:
        _temporizador -= dt;
        if (_temporizador <= 0) _nuevoDestino();
        _moverHacia(_destino, _velocidad * 0.35, dt);
        if (jugador.vivo && distancia < tipo.deteccion) _despertar();
      case _Estado.perseguir:
        if (!jugador.vivo ||
            (!tipo.jefe &&
                position.distanceTo(hogar) > _distanciaMaximaDelHogar)) {
          _estado = _Estado.volver;
        } else {
          _perseguir(hacia, distancia, dt);
        }
      case _Estado.preparar:
        _temporizador -= dt;
        _mirarA(hacia);
        // Mientras carga se acerca despacio: no basta con quedarse quieto.
        if (_golpeElegido == _Golpe.cuerpo || _golpeElegido == _Golpe.barrido) {
          if (distancia > tipo.alcance * 0.6) {
            _moverHacia(position + hacia, _velocidad * 0.3, dt);
          }
        }
        if (_temporizador <= 0) _atacar(hacia);
      case _Estado.embestir:
        _temporizador -= dt;
        _intentarMover(_direccionEmbestida * tipo.embestida * dt);
        if (!_embestidaAcerto &&
            jugador.centro.distanceTo(centro) <= radio + jugador.radio + 2) {
          _embestidaAcerto = true;
          _morder();
          jugador.recibirGolpe(dano, desde: centro);
          // La fauce muerde en pleno salto; el rey aplasta con el salto.
          if (!_saltoCompleto) {
            _golpe = _duracionGolpe;
            _numeroImpacto = 1;
          }
        }
        if (_temporizador <= 0) {
          if (furioso) _ondaExpansiva();
          if (_saltoCompleto) {
            final salto = _hoja['salto'];
            _aterrizaje = salto.duracionTramo(
                salto.eventos['aterriza']!, salto.cuadros);
          }
          _recuperar();
        }
      case _Estado.recuperar:
        _temporizador -= dt;
        if (_temporizador <= 0) _estado = _Estado.perseguir;
      case _Estado.enfurecerse:
        _temporizador -= dt;
        if (_temporizador <= 0) _estado = _Estado.perseguir;
      case _Estado.aturdido:
        _temporizador -= dt;
        if (_temporizador <= 0) _estado = _Estado.perseguir;
      case _Estado.volver:
        _moverHacia(hogar, _velocidad, dt);
        if (position.distanceTo(hogar) < 4) {
          vida = vidaMaxima;
          _estado = _Estado.deambular;
        } else if (jugador.vivo &&
            distancia < tipo.deteccion * 0.6 &&
            position.distanceTo(hogar) < _distanciaMaximaDelHogar * 0.7) {
          _estado = _Estado.perseguir;
        }
    }

    _separarDeOtros(dt);
    _animar(dt);
  }

  void _despertar() {
    _estado = _Estado.perseguir;
    if (tipo.jefe) {
      game.jefeDespierta(this);
    } else {
      Sonido.efecto(Audios.grunido,
          volumen: 0.45, espera: const Duration(milliseconds: 1800));
    }
  }

  void _perseguir(Vector2 hacia, double distancia, double dt) {
    final alcanceReal = tipo.alcance + game.jugador.radio;
    if (tipo.jefe) {
      // El rey elige: barrido si estás cerca, salto o lluvia de ojos si no.
      if (distancia <= alcanceReal + 6) {
        _prepararGolpe(_Golpe.barrido, hacia);
      } else if (distancia < 120 && _azar.nextDouble() < dt * 1.6) {
        _prepararGolpe(
            _azar.nextBool() ? _Golpe.embestida : _Golpe.lluvia, hacia);
      } else {
        _moverHacia(position + hacia, _velocidad, dt);
      }
      return;
    }
    if (tipo.ataque == Ataque.distancia && distancia < tipo.alcance * 0.45) {
      // Los que atacan de lejos se apartan si los acorralas.
      _moverHacia(position - hacia, _velocidad, dt);
      _huyendo = true;
    } else if (distancia <= alcanceReal) {
      _comboRestante = tipo.combo;
      _prepararGolpe(
          tipo.ataque == Ataque.distancia
              ? _Golpe.disparo
              : tipo.embestida > 0
                  ? _Golpe.embestida
                  : _Golpe.cuerpo,
          hacia);
    } else {
      _moverHacia(position + hacia, _velocidad, dt);
    }
  }

  void _prepararGolpe(_Golpe golpe, Vector2 hacia, {double factor = 1}) {
    _golpeElegido = golpe;
    _numeroGolpe = 1;
    _estado = _Estado.preparar;
    _preparacionTotal = _preparacion *
        factor *
        switch (golpe) {
          _Golpe.lluvia => 1.2,
          _Golpe.embestida when tipo.jefe => 1.15,
          _ => 1,
        };
    _temporizador = _preparacionTotal;
    _mirarA(hacia);
  }

  void _mirarA(Vector2 hacia) {
    if (hacia.x.abs() > 0.5) _lado = hacia.x < 0 ? -1 : 1;
  }

  void _atacar(Vector2 hacia) {
    final jugador = game.jugador;
    _haciaAtaque.setFrom(hacia.normalized());
    switch (_golpeElegido) {
      case _Golpe.disparo:
        _abanico(tipo.proyectiles, 0.32, tipo.alcance * 1.15);
        _disparo = _duracionDisparo;
        _recuperar();
      case _Golpe.lluvia:
        _abanico(furioso ? 9 : 7, 0.2, 170);
        _disparo = _duracionDisparo;
        _recuperar();
      case _Golpe.embestida:
        _direccionEmbestida.setFrom(_haciaAtaque);
        _embestidaAcerto = false;
        _estado = _Estado.embestir;
        final largo = tipo.jefe ? hacia.length + 10 : tipo.alcance + 6;
        _temporizador = largo / tipo.embestida;
        _embestidaTotal = _temporizador;
      case _Golpe.barrido:
        _golpe = _duracionGolpe;
        _numeroImpacto = _numeroGolpe;
        final angulo = atan2(hacia.y, hacia.x);
        game.zona.add(Tajo(centro.clone(),
            direccion: angulo, arco: pi * 1.1, radio: tipo.alcance + 6));
        if (hacia.length <= tipo.alcance + jugador.radio + 8) {
          _morder();
          jugador.recibirGolpe(dano, desde: centro);
        }
        _siguienteDelCombo(hacia, furioso ? 2 : 1);
      case _Golpe.cuerpo:
        _golpe = _duracionGolpe;
        _numeroImpacto = _numeroGolpe;
        // Si el jugador se apartó durante el aviso, el golpe falla.
        if (hacia.length <= tipo.alcance + jugador.radio + 3) {
          _morder();
          jugador.recibirGolpe(dano,
              ralentiza: tipo.ralentiza, desde: centro);
        }
        _siguienteDelCombo(hacia, _comboRestante);
    }
  }

  /// Encadena otro golpe con un aviso más corto, o descansa.
  void _siguienteDelCombo(Vector2 hacia, int quedan) {
    if (quedan > 1 && game.jugador.vivo) {
      _comboRestante = quedan - 1;
      final siguiente = _numeroGolpe + 1;
      _prepararGolpe(_golpeElegido, hacia, factor: 0.55);
      _numeroGolpe = siguiente;
    } else {
      _comboRestante = 0;
      _recuperar();
    }
  }

  /// [n] proyectiles abiertos [separacion] radianes entre sí, hacia el
  /// jugador.
  void _abanico(int n, double separacion, double distancia) {
    final base = atan2(_haciaAtaque.y, _haciaAtaque.x);
    for (var i = 0; i < n; i++) {
      final a = base + (i - (n - 1) / 2) * separacion;
      game.zona.add(Proyectil(
        origen: centro.clone(),
        direccion: Vector2(cos(a), sin(a)),
        rapidez: tipo.velocidadProyectil,
        distanciaMaxima: distancia,
        dano: (dano * (tipo.jefe ? 0.6 : 1)).round(),
        delJugador: false,
        tamano: tipo.tamanoProyectil,
        color: tipo.colorProyectil,
        efecto: tipo.efectoProyectil,
      ));
    }
  }

  /// Al caer de un salto, el rey furioso suelta un anillo de ojos.
  void _ondaExpansiva() {
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      game.zona.add(Proyectil(
        origen: position + Vector2(0, -4),
        direccion: Vector2(cos(a), sin(a)),
        rapidez: 90,
        distanciaMaxima: 110,
        dano: dano ~/ 2,
        delJugador: false,
        tamano: 3,
        color: Colores.alma,
        efecto: tipo.efectoProyectil,
      ));
    }
    game.zona.add(Efecto(Hojas.ondaExpansiva, 'onda', position.clone()));
  }

  /// Marca de garras o dientes sobre el jugador.
  void _morder() {
    final jugador = game.jugador;
    if (!jugador.vivo) return;
    game.zona.add(Zarpazo(jugador.centro.clone(), haciaLaDerecha: _lado > 0));
  }

  void _recuperar() {
    _estado = _Estado.recuperar;
    _temporizador = tipo.recarga * (furioso ? 0.7 : 1);
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

  /// Elige el cuadro de la hoja según el estado. El aviso, el golpe y el
  /// disparo duran lo que dice [tipo], no la hoja: sus cuadros se reparten
  /// para que el impacto se vea justo cuando el juego lo cuenta.
  void _animar(double dt) {
    final andando = dt > 0 && position.distanceTo(_antes) > _velocidad * dt * 0.2;
    // Entre dos golpes de un combo, el aviso del siguiente espera a que se vea
    // el impacto del anterior.
    final golpeando = _golpe > 0 &&
        (_estado != _Estado.preparar || _duracionGolpe - _golpe < 0.1);

    if (_estado == _Estado.enfurecerse) {
      _modelo.tramo('enfurecerse',
          1 - _temporizador / _hoja['enfurecerse'].duracion);
    } else if (golpeando) {
      final c = _tramoCombo(_numeroImpacto);
      _modelo.tramo(_animacionAtaque, 1 - _golpe / _duracionGolpe,
          desde: c.impacto, hasta: c.fin);
    } else if (_disparo > 0) {
      _modelo.tramo(_animacionAtaque, 1 - _disparo / _duracionDisparo,
          desde: _hoja[_animacionAtaque].eventos['disparo']!);
    } else if (_aterrizaje > 0) {
      final salto = _hoja['salto'];
      final desde = salto.eventos['aterriza']!;
      _modelo.tramo(
          'salto', 1 - _aterrizaje / salto.duracionTramo(desde, salto.cuadros),
          desde: desde);
    } else if (_estado == _Estado.preparar) {
      _animarAviso((1 - _temporizador / _preparacionTotal).clamp(0.0, 1.0));
    } else if (_estado == _Estado.embestir) {
      final p = 1 - _temporizador / _embestidaTotal;
      if (_saltoCompleto) {
        final salto = _hoja['salto'];
        _modelo.tramo('salto', p,
            desde: salto.eventos['despega']!,
            hasta: salto.eventos['aterriza']!);
      } else {
        final nombre = _animacionEmbestida;
        _modelo.tramo(nombre, p,
            hasta: nombre == 'salto' ? null : _hoja[nombre].golpes.first + 1);
      }
    } else if (_herido > 0 && _hoja.tiene('herido')) {
      // El rey no tiene `herido`: le basta el destello.
      _modelo.tramo('herido', 1 - _herido / _duracionHerido);
    } else if (_estado == _Estado.aturdido && _hoja.tiene('aturdido')) {
      _modelo.reproducir('aturdido');
    } else if (_huyendo && _hoja.tiene('retroceder')) {
      _modelo.reproducir('retroceder');
    } else if (andando) {
      _modelo.reproducir(_variante(_animacionMover));
    } else if (_regenerando && _hoja.tiene('curarse')) {
      _modelo.reproducir('curarse');
    } else {
      _modelo.reproducir(_variante('quieto'));
    }

    _modelo
      ..visible = game.camera.visibleWorldRect
          .inflate(64)
          .contains(Offset(position.x, position.y))
      ..scale.setValues(_lado * escalaSprites, escalaSprites);

    // Destello al recibir daño y parpadeo de brasa mientras avisa del golpe.
    final avisando = _estado == _Estado.preparar && (_t * 16).floor().isEven;
    _modelo.paint.colorFilter = _destello > 0
        ? const ColorFilter.mode(Colores.hueso, BlendMode.srcATop)
        : avisando
            ? const ColorFilter.mode(Color(0xAAE08A2C), BlendMode.srcATop)
            : null;
  }

  /// El aviso, de 0 a 1, del golpe que se prepara.
  void _animarAviso(double k) {
    switch (_golpeElegido) {
      case _Golpe.cuerpo || _Golpe.barrido:
        final c = _tramoCombo(_numeroGolpe);
        _modelo.tramo(_animacionAtaque, k, desde: c.aviso, hasta: c.impacto);
      case _Golpe.disparo || _Golpe.lluvia:
        _modelo.tramo(_animacionAtaque, k,
            hasta: _hoja[_animacionAtaque].eventos['disparo']!);
      case _Golpe.embestida when _saltoCompleto:
        _modelo.tramo('salto', k, hasta: _hoja['salto'].eventos['despega']!);
      case _Golpe.embestida when _hoja.tiene('agazaparse'):
        _modelo.tramo('agazaparse', k);
      case _Golpe.embestida:
        final nombre = _animacionEmbestida;
        _modelo.tramo(nombre, k, hasta: _hoja[nombre].golpes.firstOrNull);
    }
  }

  /// Cuadros del golpe [numero] del combo en la animación de ataque: el aviso
  /// va de [aviso] a [impacto] y el golpe de [impacto] a [fin]. Si el combo
  /// tiene más golpes que la animación, se repite el último.
  ({int aviso, int impacto, int fin}) _tramoCombo(int numero) {
    final a = _hoja[_animacionAtaque];
    final golpes = a.golpes;
    final i = (numero - 1).clamp(0, golpes.length - 1);
    return (
      aviso: i == 0 ? 0 : golpes[i - 1] + 1,
      impacto: golpes[i],
      fin: i == golpes.length - 1 ? a.cuadros : golpes[i] + 1,
    );
  }

  /// El rey furioso tiene su propio `quieto` y `caminar`.
  String _variante(String nombre) =>
      furioso && _hoja.tiene('$nombre-furioso') ? '$nombre-furioso' : nombre;

  @override
  void render(Canvas canvas) {
    // Barra de vida sobre la cabeza de las criaturas heridas (el jefe la
    // tiene en el HUD).
    if (!vivo || tipo.jefe || _sinDano > 4 || !_modelo.visible) return;
    const ancho = 14.0;
    final y = -tipo.alturaCentro - 15;
    canvas.drawRect(Rect.fromLTWH(-ancho / 2 - 0.5, y - 0.5, ancho + 1, 2),
        _fondoBarra);
    canvas.drawRect(
        Rect.fromLTWH(-ancho / 2, y, ancho * (vida / vidaMaxima), 1),
        _rellenoBarra);
  }

  static final _fondoBarra = Paint()..color = Colores.abismo;
  static final _rellenoBarra = Paint()..color = Colores.sangre;

  void recibirGolpe(int dano, bool critico, Vector2 empuje) {
    if (!vivo) return;
    vida -= dano;
    _sinDano = 0;
    _destello = 0.08;
    _herido = _duracionHerido;
    game.zona
      ..add(Efecto(Hojas.efectos, 'impacto', centro))
      ..add(TextoFlotante(
          critico ? '$dano!' : '$dano', centro - Vector2(0, 7),
          color: critico ? Colores.brasa : Colores.hueso));
    if (_estado == _Estado.deambular || _estado == _Estado.volver) {
      _despertar();
    }
    // Las criaturas pequeñas se tambalean y pierden el ataque que cargaban,
    // pero tras varios golpes seguidos aguantan el siguiente.
    if (!tipo.firme && _estado != _Estado.embestir && _retrocesos < 2) {
      _retrocesos += 1;
      _estado = _Estado.aturdido;
      _temporizador = _duracionAturdido;
      _intentarMover(empuje * 5);
    } else if (_estado != _Estado.embestir) {
      _intentarMover(empuje * (tipo.firme ? 1 : 3));
    }
    if (vida <= 0) {
      vida = 0;
      Sonido.efecto(Audios.muerteEnemigo, volumen: tipo.jefe ? 1 : 0.7);
      game.enemigoDerrotado(this);
      game.zona
        ..add(Desvanecer(_hoja, position.clone(), _lado))
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
