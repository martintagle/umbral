import 'dart:math';

import 'package:flutter/material.dart';

import '../../dto/atributos_dto.dart';
import '../../servicio/modelos/partida_jugable.dart';
import '../../servicio/servicio_excepcion.dart';
import '../clases_ui.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/confirmacion_umbral.dart';
import '../widgets/icono_umbral.dart';
import '../widgets/panel_umbral.dart';
import '../widgets/selector_umbral.dart';
import '../widgets/sprite_umbral.dart';

/// Altar de brasas: se gasta experiencia para subir atributos, como las
/// runas de Elden Ring. Cada punto sube un nivel y cada nivel cuesta más que
/// el anterior; los costos los da el servidor en `Combate.costoNiveles`.
/// Nada se aplica hasta Confirmar; el servidor cobra, valida y devuelve la
/// partida actualizada.
class EstadisticasPantalla extends StatefulWidget {
  final PartidaJugable partida;

  /// Envía los puntos de cada atributo y devuelve la partida resultante.
  final Future<PartidaJugable> Function(AtributosDto incrementos) alSubir;

  const EstadisticasPantalla(
      {super.key, required this.partida, required this.alSubir});

  @override
  State<EstadisticasPantalla> createState() => _EstadisticasPantallaState();
}

typedef _Atributo = ({String id, String nombre, String icono, String efecto});

const _atributos = <_Atributo>[
  (id: 'vida', nombre: 'Vigor', icono: 'vigor', efecto: 'Vida máxima.'),
  (id: 'fuerza', nombre: 'Fuerza', icono: 'fuerza', efecto: 'Golpes con armas pesadas.'),
  (
    id: 'destreza',
    nombre: 'Destreza',
    icono: 'destreza',
    efecto: 'Golpes críticos; katanas, arcos y dagas.'
  ),
  (
    id: 'inteligencia',
    nombre: 'Intelecto',
    icono: 'intelecto',
    efecto: 'Daño de los hechizos.'
  ),
];

class _EstadisticasPantallaState extends State<EstadisticasPantalla> {
  static const _maximo = 50;

  late PartidaJugable _partida = widget.partida;
  final Map<String, int> _sumados = {for (final a in _atributos) a.id: 0};
  bool _cargando = false;
  String? _error;
  String? _hecho;

  /// Puntos elegidos en total.
  int get _elegidos => _sumados.values.fold(0, (a, b) => a + b);

  /// Puntos de la regla anterior sin repartir: no cuestan ni suben el nivel.
  int get _libres => _partida.partida.personaje.puntosLibres;

  /// Niveles que se pagan con experiencia si se eligen [puntos].
  int _niveles(int puntos) => puntos - min(_libres, puntos);

  /// Experiencia que cuestan los [niveles] siguientes, o null si el servidor
  /// no informó tantos.
  int? _costo(int niveles) {
    final costos = _partida.combate.costoNiveles;
    if (niveles > costos.length) return null;
    return costos.take(niveles).fold<int>(0, (a, b) => a + b);
  }

  bool get _alcanzaOtro {
    final costo = _costo(_niveles(_elegidos + 1));
    return costo != null && costo <= _partida.partida.personaje.exp;
  }

  int _guardado(String id) {
    final a = _partida.partida.personaje.atributos;
    return switch (id) {
      'vida' => a.vida,
      'fuerza' => a.fuerza,
      'destreza' => a.destreza,
      _ => a.inteligencia,
    };
  }

  void _cambiar(String id, int paso) => setState(() {
        _sumados[id] = _sumados[id]! + paso;
        _hecho = null;
      });

  void _restablecer() => setState(() {
        _sumados.updateAll((_, _) => 0);
        _hecho = null;
      });

  Future<void> _confirmar() async {
    if (_cargando || _elegidos == 0) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final nueva = await widget.alSubir(AtributosDto(
        vida: _sumados['vida']!,
        fuerza: _sumados['fuerza']!,
        destreza: _sumados['destreza']!,
        inteligencia: _sumados['inteligencia']!,
      ));
      if (!mounted) return;
      setState(() {
        _partida = nueva;
        _sumados.updateAll((_, _) => 0);
        _hecho = 'Las brasas aceptan tu ofrenda. '
            'Ahora eres nivel ${nueva.partida.personaje.nivel}.';
      });
    } on ServicioExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _volver() async {
    if (_elegidos > 0 &&
        !await confirmar(context,
            titulo: '¿Salir sin subir de nivel?',
            texto: 'Los $_elegidos puntos que elegiste no se aplicarán.',
            verbo: 'Salir')) {
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final personaje = _partida.partida.personaje;
    final clase = claseUi(personaje.clase);
    final combate = _partida.combate;
    final niveles = _niveles(_elegidos);
    final costo = _costo(niveles) ?? 0;
    final alcanzaOtro = _alcanzaOtro && !_cargando;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _volver();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Espacios.paso4),
                    child: Row(
                      children: [
                        BotonIcono(
                            icono: 'atras',
                            descripcion: 'Volver',
                            alPulsar: _volver),
                        const SizedBox(width: Espacios.paso4),
                        Expanded(
                          child: Text('Altar de brasas',
                              style: Textos.tituloZona()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Espacios.paso4),
                      children: [
                        PanelUmbral(
                          child: Row(
                            children: [
                              SpriteUmbral(
                                ruta: clase.sprite(personaje.apariencia),
                                ancho: 32,
                                alto: 40,
                                escala: 2,
                                descripcion: clase.nombre,
                              ),
                              const SizedBox(width: Espacios.paso4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(personaje.nombre,
                                        style: Textos.encabezado()),
                                    Text(
                                      niveles > 0
                                          ? '${clase.nombre.toUpperCase()} · NV ${personaje.nivel} ▶ ${personaje.nivel + niveles}'
                                          : '${clase.nombre.toUpperCase()} · NV ${personaje.nivel}',
                                      style: Textos.etiqueta(
                                          color: niveles > 0
                                              ? Colores.brasa
                                              : Colores.ceniza),
                                    ),
                                    const SizedBox(height: Espacios.paso2),
                                    Text('EXP ${personaje.exp}',
                                        style: Textos.contador()),
                                    Text(
                                      _elegidos == 0
                                          ? 'Siguiente nivel: ${combate.expSiguiente} EXP'
                                          : 'Gastas $costo · quedan ${personaje.exp - costo}',
                                      style: Textos.cuerpo(
                                          color: _elegidos == 0
                                              ? Colores.ceniza
                                              : Colores.brasa),
                                    ),
                                    if (_libres > 0)
                                      Text('$_libres puntos sin costo de antes',
                                          style: Textos.cuerpo(
                                              color: Colores.ceniza)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Espacios.paso2),
                        Text(
                          'Cada punto sube un nivel y cuesta más experiencia '
                          'que el anterior. Las criaturas sueltan experiencia '
                          'al caer.',
                          style: Textos.cuerpo(color: Colores.ceniza),
                        ),
                        const SizedBox(height: Espacios.paso4),
                        for (final a in _atributos)
                          _FilaAtributo(
                            atributo: a,
                            delArma: clase.atributoArma == a.id,
                            valor: _guardado(a.id) + _sumados[a.id]!,
                            cambiado: _sumados[a.id]! > 0,
                            alRestar: _sumados[a.id]! > 0 && !_cargando
                                ? () => _cambiar(a.id, -1)
                                : null,
                            alSumar: alcanzaOtro &&
                                    _guardado(a.id) + _sumados[a.id]! < _maximo
                                ? () => _cambiar(a.id, 1)
                                : null,
                          ),
                        const SizedBox(height: Espacios.paso4),
                        Text('VALORES ACTUALES',
                            style: Textos.etiqueta(color: Colores.ceniza)),
                        const SizedBox(height: Espacios.paso2),
                        PanelUmbral(
                          padding: const EdgeInsets.all(Espacios.paso2),
                          child: Column(
                            children: [
                              _Valor('PV máximos', '${combate.vidaMaxima}'),
                              _Valor('Daño', '${combate.dano}'),
                              _Valor('Defensa', '${combate.defensa}'),
                              _Valor('Crítico',
                                  '${(combate.probabilidadCritico * 100).toStringAsFixed(1)} %'),
                            ],
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: Espacios.paso4),
                          AvisoError(_error!),
                        ],
                        if (_hecho != null) ...[
                          const SizedBox(height: Espacios.paso4),
                          Semantics(
                            liveRegion: true,
                            child: Text(_hecho!,
                                textAlign: TextAlign.center,
                                style: Textos.cuerpo(color: Colores.brasa)),
                          ),
                        ],
                        const SizedBox(height: Espacios.paso4),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(Espacios.paso4),
                    decoration: const BoxDecoration(
                      color: Colores.piedra,
                      border: Border(
                          top: BorderSide(color: Colores.borde, width: 2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: BotonUmbral(
                            texto: 'Restablecer',
                            estilo: EstiloBoton.secundario,
                            alPulsar: _elegidos > 0 && !_cargando
                                ? _restablecer
                                : null,
                          ),
                        ),
                        const SizedBox(width: Espacios.paso4),
                        Expanded(
                          child: BotonUmbral(
                            texto: 'Confirmar',
                            estilo: EstiloBoton.acento,
                            costo: _elegidos > 0 ? '$costo EXP' : null,
                            cargando: _cargando,
                            alPulsar: _elegidos > 0 ? _confirmar : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaAtributo extends StatelessWidget {
  final _Atributo atributo;
  final bool delArma;
  final int valor;
  final bool cambiado;
  final VoidCallback? alRestar;
  final VoidCallback? alSumar;

  const _FilaAtributo({
    required this.atributo,
    required this.delArma,
    required this.valor,
    required this.cambiado,
    required this.alRestar,
    required this.alSumar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacios.paso2),
      child: Row(
        children: [
          IconoUmbral(atributo.icono),
          const SizedBox(width: Espacios.paso2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(atributo.nombre.toUpperCase(), style: Textos.etiqueta()),
                Text(
                  delArma
                      ? '${atributo.efecto} Sube el daño de tu arma.'
                      : atributo.efecto,
                  style: Textos.cuerpo(color: Colores.ceniza)
                      .copyWith(fontSize: 14, height: 20 / 14),
                ),
              ],
            ),
          ),
          SelectorUmbral(
            valor: valor,
            cambiado: cambiado,
            descripcion: atributo.nombre,
            alRestar: alRestar,
            alSumar: alSumar,
          ),
        ],
      ),
    );
  }
}

class _Valor extends StatelessWidget {
  final String nombre;
  final String valor;

  const _Valor(this.nombre, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(nombre, style: Textos.cuerpo())),
          Text(valor, style: Textos.contador()),
        ],
      ),
    );
  }
}
