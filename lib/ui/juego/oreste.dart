import 'dart:convert';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'animacion.dart';
import 'efectos.dart';
import 'umbral_juego.dart';

/// Lo que miran los requisitos de Oreste. Lo implementa [UmbralJuego]; las
/// pruebas usan un estado falso.
abstract interface class EstadoMundo {
  /// Si hay algún altar de brasas encendido en [zonaId].
  bool fogataEncendidaEn(String zonaId);
  bool cofreAbierto(String id);
  Set<String> get jefesDerrotados;
  Set<String> get dialogosLeidos;
}

/// Un diálogo de `assets/datos/npc-oreste.json`.
class DialogoOreste {
  const DialogoOreste({
    required this.id,
    required this.zona,
    required this.orden,
    required this.requiere,
    required this.lineas,
  });

  final String id;

  /// Número de la zona (1 a 6).
  final int zona;
  final int orden;

  /// Todos deben cumplirse: `llegada`, `fogata:<zonaId>`,
  /// `cofre:<zonaId>/<cofreId>`, `jefe:<id>`, `leido:<id>` o `todos`.
  final List<String> requiere;
  final List<String> lineas;
}

/// Oreste, el Apagador (`docs/npc-oreste.md`): sus diálogos, la frase de
/// espera de cada zona y dónde espera.
class DatosOreste {
  DatosOreste._(Map<String, dynamic> m)
    : dialogos = [
        for (final d in m['dialogos'] as List)
          DialogoOreste(
            id: d['id'] as String,
            zona: d['zona'] as int,
            orden: d['orden'] as int,
            requiere: List<String>.from(d['requiere'] as List),
            lineas: List<String>.from(d['lineas'] as List),
          ),
      ]..sort((a, b) => (a.zona * 100 + a.orden) - (b.zona * 100 + b.orden)),
      espera = {
        for (final MapEntry(:key, :value)
            in (m['espera'] as Map<String, dynamic>).entries)
          int.parse(key): value as String,
      },
      trasAstilla = List<String>.from(m['trasAstilla'] as List),
      refugios = {
        for (final MapEntry(:key, :value)
            in (m['posiciones'] as Map<String, dynamic>).entries)
          if (value['interior'] case final Map<String, dynamic> i)
            int.parse(key): (
              sala: i['sala'] as String,
              x: i['x'] as int,
              y: i['y'] as int,
            ),
      };

  static const nombre = 'Oreste';
  static const hoja = 'npcs/oreste';
  static const retrato = 'assets/sprites/animaciones/npcs/oreste-retrato.png';

  /// El cofre que guarda la astilla de nada: abrirlo es tenerla.
  static const cofreAstilla = 'umbral/cofre-secreto-astilla';

  final List<DialogoOreste> dialogos;

  /// Lo que dice cuando no hay nada nuevo, por número de zona.
  final Map<int, String> espera;

  /// Lo que dice en la zona 6 cuando el jugador ya tiene la astilla.
  final List<String> trasAstilla;

  /// Dónde espera, por número de zona: bajo techo, en la sala [sala] (su
  /// slug) y en su celda (x, y).
  final Map<int, ({String sala, int x, int y})> refugios;

  static Future<DatosOreste> cargar() async => DatosOreste.desdeJson(
    await rootBundle.loadString('assets/datos/npc-oreste.json'),
  );

  factory DatosOreste.desdeJson(String json) =>
      DatosOreste._(jsonDecode(json) as Map<String, dynamic>);

  /// Si se cumple el requisito [r] del diálogo [id].
  bool cumple(String r, EstadoMundo estado, String id) {
    final leidos = estado.dialogosLeidos;
    if (r == 'llegada') return true;
    if (r == 'todos') {
      return dialogos.every((d) => d.id == id || leidos.contains(d.id));
    }
    final [tipo, valor] = r.split(':');
    return switch (tipo) {
      'fogata' => estado.fogataEncendidaEn(valor),
      'cofre' => estado.cofreAbierto(valor),
      'jefe' => estado.jefesDerrotados.contains(valor),
      'leido' => leidos.contains(valor),
      _ => false,
    };
  }

  /// El primer diálogo de la [zona] sin leer cuyos requisitos se cumplen.
  DialogoOreste? siguiente(int zona, EstadoMundo estado) {
    final leidos = estado.dialogosLeidos;
    for (final d in dialogos) {
      if (d.zona != zona || leidos.contains(d.id)) continue;
      if (d.requiere.every((r) => cumple(r, estado, d.id))) return d;
    }
    return null;
  }

  /// Si queda algún diálogo sin leer en la [zona], se pueda leer ya o no.
  bool tienePendientes(int zona, EstadoMundo estado) => dialogos.any(
    (d) => d.zona == zona && !estado.dialogosLeidos.contains(d.id),
  );

  /// La única zona en la que está Oreste: la del primer diálogo sin leer, en
  /// el orden del recorrido. No se mueve de ahí hasta que se leen. Con todos
  /// leídos se queda en la 6.
  int zonaDe(EstadoMundo estado) {
    final leidos = estado.dialogosLeidos;
    return dialogos.where((d) => !leidos.contains(d.id)).firstOrNull?.zona ??
        6;
  }

  /// Si Oreste espera a la puerta de la mazmorra de la [zona] en vez de en su
  /// refugio: desde la zona 2, cuando se sigue su misión (está en esa zona)
  /// y lo que toca es el diálogo del jefe, ya vencido.
  bool anteLaMazmorra(int zona, EstadoMundo estado) =>
      zona >= 2 &&
      zonaDe(estado) == zona &&
      (siguiente(zona, estado)?.requiere.any((r) => r.startsWith('jefe:')) ??
          false);

  /// Si Oreste espera en su refugio de la [zona].
  bool enRefugio(int zona, EstadoMundo estado) =>
      zonaDe(estado) == zona && !anteLaMazmorra(zona, estado);
}

/// Oreste en su refugio: la choza o la capilla más cercana al primer altar de
/// la zona; o, vencido el jefe, a la puerta de su mazmorra. No es un enemigo: no se le golpea, no bloquea el paso y los
/// enemigos no lo ven. Su `position` son los pies.
///
/// Se sienta cuando el jugador está lejos y se levanta cuando se acerca.
class Oreste extends PositionComponent with HasGameReference<UmbralJuego> {
  Oreste(Vector2 pies)
    : super(position: pies.clone(), priority: pies.y.round());

  static const _cerca = 48.0;

  /// Segundos con el jugador lejos antes de volver a sentarse.
  static const _esperaParaSentarse = 8.0;
  static final _azar = Random();

  late final ModeloAnimado _modelo;
  late final Hoja _hoja = Hojas.de(DatosOreste.hoja);

  /// Lo que hace cuando no hay ninguna acción de una vuelta en curso.
  String _bucle = 'sentado';

  /// Acción de una vuelta (`mirar`, `levantarse`...) y lo que lleva; al
  /// acabar se pasa a [_despues].
  String? _accion;
  double _t = 0;
  String _despues = 'quieto';
  bool _quitarAlAcabar = false;

  double _proximaMirada = 0;
  double _proximaVela = 0;
  double _lejos = 0;
  int _lado = 1;

  bool get desvaneciendose => _quitarAlAcabar;

  @override
  Future<void> onLoad() async {
    _modelo = ModeloAnimado(_hoja, paint: pinturaSprites())
      ..scale = Vector2.all(escalaSprites);
    add(_modelo);
    _esperarMirada();
    _esperarVela();
    // Se forma de la ceniza y se sienta a esperar.
    _hacer('aparecer', despues: 'sentado');
    _animar();
  }

  void _esperarMirada() => _proximaMirada = 6 + _azar.nextDouble() * 4;
  void _esperarVela() => _proximaVela = 14 + _azar.nextDouble() * 10;

  /// Reproduce [nombre] una vez y sigue con [despues].
  void _hacer(String nombre, {String despues = 'quieto'}) {
    _accion = nombre;
    _t = 0;
    _despues = despues;
  }

  /// Se deshace en ceniza y se va.
  void desvanecerse() {
    if (_quitarAlAcabar) return;
    _quitarAlAcabar = true;
    _hacer('desvanecerse');
  }

  @override
  void update(double dt) {
    super.update(dt);
    final jugador = game.jugador;
    final hacia = jugador.position - position;
    final cerca = hacia.length < _cerca;
    final hablando = game.dialogo.value != null && cerca;

    if (cerca && hacia.x.abs() > 1) _lado = hacia.x < 0 ? -1 : 1;
    _lejos = cerca ? 0 : _lejos + dt;

    if (_accion case final accion?) {
      _t += dt;
      if (_t >= _hoja[accion].duracion) {
        _accion = null;
        if (_quitarAlAcabar) {
          removeFromParent();
          return;
        }
        _bucle = _despues;
      }
    } else if (hablando) {
      _bucle = 'hablar';
    } else if (_bucle == 'hablar') {
      _bucle = 'quieto';
    } else if (_bucle == 'sentado') {
      // Se levanta para recibir a quien se acerca.
      if (cerca) _hacer('levantarse');
    } else if (_bucle == 'quieto') {
      _proximaMirada -= dt;
      _proximaVela -= dt;
      if (_lejos > _esperaParaSentarse) {
        _hacer('sentarse', despues: 'sentado');
      } else if (_proximaVela <= 0 && !cerca) {
        _esperarVela();
        _hacer('apagar-vela');
      } else if (_proximaMirada <= 0) {
        _esperarMirada();
        _hacer('mirar');
      }
    }
    _animar();
  }

  void _animar() {
    final accion = _accion;
    if (accion != null) {
      // `mirar` es un bucle en la hoja: aquí se da una sola vuelta.
      _modelo.tramo(accion, _t / _hoja[accion].duracion);
    } else {
      _modelo.reproducir(_bucle);
    }
    _modelo.scale.setValues(_lado * escalaSprites, escalaSprites);
  }
}
