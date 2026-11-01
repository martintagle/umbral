import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tema/tema_umbral.dart';

/// Una escena de `assets/cinematicas/cinematicas.json`: sus cuadros de pixel
/// art (256×144) y los textos que se leen encima, de uno en uno.
class EscenaCinematica {
  final List<String> cuadros;

  /// Duración de cada cuadro en milisegundos.
  final int ms;

  /// Si los cuadros se repiten. Si no, se queda en el último.
  final bool bucle;
  final List<String> textos;

  /// Texto grande en el centro (el logo, «Fin», el nombre del personaje).
  final String? titulo;
  final String? subtitulo;

  /// El título aparece letra a letra y la escena pasa sola.
  final bool letraALetra;
  final bool fundido;
  final bool temblor;

  EscenaCinematica._(Map<String, dynamic> m)
    : cuadros = List<String>.from(m['cuadros'] as List),
      ms = m['ms'] as int,
      bucle = m['bucle'] as bool,
      textos = List<String>.from(m['textos'] as List),
      titulo = m['titulo'] as String?,
      subtitulo = m['subtitulo'] as String?,
      letraALetra = m['letraALetra'] as bool? ?? false,
      fundido = m['fundido'] as bool? ?? false,
      temblor = m['temblor'] as bool? ?? false;
}

/// Cinemática con cuadros de texto (`docs/cinematicas.md`): `inicio`,
/// `final-encender` o `final-romper`. Tocar completa la línea o pasa a la
/// siguiente; «Saltar» y el botón atrás la terminan. `{nombre}` se cambia por
/// [nombre].
class CinematicaPantalla extends StatefulWidget {
  final String id;
  final String nombre;
  final VoidCallback alTerminar;

  const CinematicaPantalla({
    super.key,
    required this.id,
    required this.nombre,
    required this.alTerminar,
  });

  static Future<List<EscenaCinematica>> cargar(String id) async {
    final datos =
        jsonDecode(
              await rootBundle.loadString('assets/cinematicas/cinematicas.json'),
            )
            as Map<String, dynamic>;
    final cinematica =
        (datos['cinematicas'] as Map<String, dynamic>)[id]
            as Map<String, dynamic>;
    return [
      for (final e in cinematica['escenas'] as List)
        EscenaCinematica._(e as Map<String, dynamic>),
    ];
  }

  @override
  State<CinematicaPantalla> createState() => _CinematicaPantallaState();
}

class _CinematicaPantallaState extends State<CinematicaPantalla> {
  static const _pasoLetra = Duration(milliseconds: 33);
  static const _pasoLetraTitulo = Duration(milliseconds: 180);

  List<EscenaCinematica>? _escenas;
  int _escena = -1;
  int _texto = 0;
  int _visibles = 0;
  int _letrasTitulo = 0;
  int _cuadro = 0;
  double _opacidad = 0;
  Offset _temblor = Offset.zero;
  bool _terminada = false;
  final _azar = Random();
  final List<Timer> _relojes = [];

  EscenaCinematica get _actual => _escenas![_escena];

  String _conNombre(String texto) => texto.replaceAll('{nombre}', widget.nombre);

  String get _linea => _conNombre(_actual.textos[_texto]);

  String get _titulo => _conNombre(_actual.titulo ?? '');

  @override
  void initState() {
    super.initState();
    CinematicaPantalla.cargar(widget.id).then((escenas) {
      if (!mounted) return;
      for (final e in escenas) {
        for (final c in e.cuadros) {
          precacheImage(AssetImage(c), context);
        }
      }
      _escenas = escenas;
      _siguienteEscena();
    }, onError: (Object _) {
      // Sin datos no hay nada que mostrar: se sigue como si se saltara.
      if (mounted) _terminar();
    });
  }

  @override
  void dispose() {
    _parar();
    super.dispose();
  }

  void _parar() {
    for (final r in _relojes) {
      r.cancel();
    }
    _relojes.clear();
  }

  void _despues(Duration espera, VoidCallback hacer) {
    _relojes.add(
      Timer(espera, () {
        if (mounted) hacer();
      }),
    );
  }

  void _cada(Duration paso, void Function(Timer) hacer) {
    _relojes.add(
      Timer.periodic(paso, (reloj) {
        if (mounted) {
          hacer(reloj);
        } else {
          reloj.cancel();
        }
      }),
    );
  }

  void _terminar() {
    if (_terminada) return;
    _terminada = true;
    _parar();
    widget.alTerminar();
  }

  void _siguienteEscena() {
    _parar();
    final escenas = _escenas!;
    if (_escena + 1 >= escenas.length) {
      _terminar();
      return;
    }
    final e = escenas[_escena + 1];
    setState(() {
      _escena++;
      _texto = 0;
      _visibles = 0;
      _letrasTitulo = 0;
      _cuadro = 0;
      _temblor = Offset.zero;
      _opacidad = e.fundido ? 0 : 1;
    });
    if (e.fundido) {
      _despues(
        const Duration(milliseconds: 60),
        () => setState(() => _opacidad = 1),
      );
    }
    // Los cuadros avanzan solos; sin textos ni título, la escena pasa sola
    // al terminar.
    final pasaSola = e.textos.isEmpty && e.titulo == null;
    if (e.cuadros.length > 1) {
      _cada(Duration(milliseconds: e.ms), (reloj) {
        if (_cuadro < e.cuadros.length - 1) {
          setState(() => _cuadro++);
        } else if (e.bucle) {
          setState(() => _cuadro = 0);
        } else {
          reloj.cancel();
          if (pasaSola) {
            _despues(const Duration(milliseconds: 900), _siguienteEscena);
          }
        }
      });
    } else if (pasaSola) {
      _despues(const Duration(milliseconds: 1500), _siguienteEscena);
    }
    if (e.temblor) {
      var veces = 0;
      _cada(const Duration(milliseconds: 60), (reloj) {
        veces++;
        setState(
          () => _temblor = veces < 10
              ? Offset(_azar.nextDouble() * 6 - 3, _azar.nextDouble() * 6 - 3)
              : Offset.zero,
        );
        if (veces >= 10) reloj.cancel();
      });
    }
    if (e.letraALetra && e.titulo != null) {
      _cada(_pasoLetraTitulo, (reloj) {
        setState(() => _letrasTitulo++);
        if (_letrasTitulo >= _titulo.length) {
          reloj.cancel();
          _despues(const Duration(milliseconds: 1800), _siguienteEscena);
        }
      });
    }
    if (e.textos.isNotEmpty) _escribir();
  }

  void _escribir() {
    _visibles = 0;
    _cada(_pasoLetra, (reloj) {
      setState(() => _visibles++);
      if (_visibles >= _linea.length) reloj.cancel();
    });
  }

  void _tocar() {
    if (_escenas == null || _escena < 0 || _terminada) return;
    final e = _actual;
    if (e.textos.isEmpty) {
      if (!e.letraALetra) _siguienteEscena();
      return;
    }
    if (_visibles < _linea.length) {
      setState(() => _visibles = _linea.length);
    } else if (_texto + 1 < e.textos.length) {
      setState(() => _texto++);
      _escribir();
    } else {
      _siguienteEscena();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listo = _escenas != null && _escena >= 0;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _terminar();
      },
      child: Scaffold(
        backgroundColor: Colores.abismo,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tocar,
          child: !listo
              ? const SizedBox.expand()
              : Stack(
                  children: [
                    Center(
                      child: AnimatedOpacity(
                        opacity: _opacidad,
                        duration: Duration(
                          milliseconds: _actual.fundido ? 700 : 0,
                        ),
                        child: Transform.translate(
                          offset: _temblor,
                          child: AspectRatio(
                            aspectRatio: 256 / 144,
                            child: _actual.cuadros.isEmpty
                                ? const ColoredBox(color: Colores.abismo)
                                : Image.asset(
                                    _actual.cuadros[_cuadro],
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.none,
                                    gaplessPlayback: true,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (_actual.titulo != null)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _actual.letraALetra
                                  ? _titulo.substring(
                                      0,
                                      min(_letrasTitulo, _titulo.length),
                                    )
                                  : _titulo,
                              textAlign: TextAlign.center,
                              style: Textos.tituloJuego().copyWith(
                                shadows: const [
                                  Shadow(
                                    color: Colores.abismo,
                                    offset: Offset(4, 4),
                                  ),
                                ],
                              ),
                            ),
                            if (_actual.subtitulo case final sub?) ...[
                              const SizedBox(height: Espacios.paso2),
                              Text(
                                sub,
                                style: Textos.etiqueta(color: Colores.ceniza),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (_actual.textos.isNotEmpty)
                      SafeArea(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(Espacios.paso4),
                            child: _CajaTexto(
                              texto: _linea.substring(
                                0,
                                min(_visibles, _linea.length),
                              ),
                              completa: _visibles >= _linea.length,
                            ),
                          ),
                        ),
                      ),
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _terminar,
                          child: Text(
                            'Saltar',
                            style: Textos.etiqueta(color: Colores.ceniza),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// El cuadro de texto de abajo, con una flecha cuando la línea está completa.
class _CajaTexto extends StatelessWidget {
  final String texto;
  final bool completa;

  const _CajaTexto({required this.texto, required this.completa});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, minHeight: 72),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colores.abismo.withValues(alpha: 0.88),
          border: Border.all(color: Colores.borde),
          borderRadius: Radios.astilla,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Espacios.paso4),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: Espacios.paso6),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(texto, style: Textos.cuerpo()),
                ),
              ),
              if (completa)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text('▾', style: Textos.cuerpo(color: Colores.brasa)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
