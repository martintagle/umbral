import 'package:flutter/material.dart';

import '../../dto/clase_dto.dart';
import '../../servicio/clase_servicio.dart';
import '../../servicio/partida_servicio.dart';
import '../../servicio/servicio_excepcion.dart';
import '../clases_ui.dart';
import '../tema/tema_umbral.dart';
import '../validaciones/validaciones.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/campo_umbral.dart';
import '../widgets/panel_umbral.dart';
import '../widgets/sprite_umbral.dart';

/// Elige clase, apariencia y nombre. Devuelve la partida creada al cerrarse.
class NuevoPersonajePantalla extends StatefulWidget {
  const NuevoPersonajePantalla({super.key});

  @override
  State<NuevoPersonajePantalla> createState() => _NuevoPersonajePantallaState();
}

class _NuevoPersonajePantallaState extends State<NuevoPersonajePantalla> {
  final _clases = ClaseServicio();
  final _partidas = PartidaServicio();
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();

  CatalogoClasesDto? _catalogo;
  ClaseDto? _clase;
  String _apariencia = 'hombre';
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    setState(() => _error = null);
    try {
      final catalogo = await _clases.catalogo();
      if (!mounted) return;
      setState(() {
        _catalogo = catalogo;
        _clase = catalogo.clases.first;
        _apariencia = catalogo.apariencias.first;
      });
    } on ServicioExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  Future<void> _comenzar() async {
    if (_cargando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final partida = await _partidas.crearPartida(
          nombre: _nombre.text.trim(), clase: _clase!.id, apariencia: _apariencia);
      if (mounted) Navigator.of(context).pop(partida);
    } on ServicioExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = _catalogo;
    final elegida = _clase;
    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo personaje', style: Textos.encabezado()),
      ),
      body: SafeArea(
        child: catalogo == null || elegida == null
            ? _sinCatalogo()
            : _formularioPersonaje(catalogo, elegida),
      ),
    );
  }

  Widget _sinCatalogo() {
    final error = _error;
    if (error == null) {
      return const Center(child: CircularProgressIndicator(color: Colores.brasa));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Espacios.paso4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvisoError(error),
            const SizedBox(height: Espacios.paso4),
            BotonUmbral(
                texto: 'Reintentar',
                estilo: EstiloBoton.secundario,
                alPulsar: _cargarCatalogo),
          ],
        ),
      ),
    );
  }

  Widget _formularioPersonaje(CatalogoClasesDto catalogo, ClaseDto elegida) {
    final clase = claseUi(elegida.id);
    final a = elegida.atributos;
    final combate = elegida.combate;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Espacios.paso4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('CLASE', style: Textos.etiqueta(color: Colores.ceniza)),
                const SizedBox(height: Espacios.paso2),
                LayoutBuilder(
                  // Tres tarjetas por fila que se reparten el ancho.
                  builder: (_, limites) => Wrap(
                    spacing: Espacios.paso2,
                    runSpacing: Espacios.paso2,
                    children: [
                      for (final c in catalogo.clases)
                        _OpcionClase(
                          clase: claseUi(c.id),
                          apariencia: _apariencia,
                          elegida: c.id == elegida.id,
                          ancho: ((limites.maxWidth - Espacios.paso2 * 2) / 3)
                              .floorToDouble(),
                          alElegir: () => setState(() => _clase = c),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Espacios.paso4),
                Text('APARIENCIA', style: Textos.etiqueta(color: Colores.ceniza)),
                const SizedBox(height: Espacios.paso2),
                Row(
                  children: [
                    for (final ap in catalogo.apariencias) ...[
                      Expanded(
                        child: BotonUmbral(
                          texto: ap == 'hombre' ? 'Hombre' : 'Mujer',
                          estilo: ap == _apariencia
                              ? EstiloBoton.acento
                              : EstiloBoton.secundario,
                          alPulsar: () => setState(() => _apariencia = ap),
                        ),
                      ),
                      if (ap != catalogo.apariencias.last)
                        const SizedBox(width: Espacios.paso4),
                    ],
                  ],
                ),
                const SizedBox(height: Espacios.paso6),
                PanelUmbral(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SpriteUmbral(
                          ruta: clase.sprite(_apariencia),
                          ancho: 32,
                          alto: 40,
                          descripcion: '${clase.nombre}, $_apariencia',
                        ),
                      ),
                      const SizedBox(height: Espacios.paso4),
                      Text(clase.nombre,
                          textAlign: TextAlign.center, style: Textos.tituloZona()),
                      Text(clase.arma.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: Textos.etiqueta(color: Colores.brasa)),
                      const SizedBox(height: Espacios.paso2),
                      Text(clase.descripcion,
                          textAlign: TextAlign.center,
                          style: Textos.cuerpo(color: Colores.ceniza)),
                      const SizedBox(height: Espacios.paso4),
                      _Estadistica('Vida', a.vida),
                      _Estadistica('Fuerza', a.fuerza),
                      _Estadistica('Destreza', a.destreza),
                      _Estadistica('Inteligencia', a.inteligencia),
                      const SizedBox(height: Espacios.paso2),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        spacing: Espacios.paso4,
                        children: [
                          Text('PV ${combate.vidaMaxima}', style: Textos.etiqueta()),
                          Text('DAÑO ${combate.dano}', style: Textos.etiqueta()),
                          Text('DEFENSA ${combate.defensa}', style: Textos.etiqueta()),
                          Text('ORO ${elegida.oroInicial}',
                              style: Textos.etiqueta(color: Colores.brasa)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Espacios.paso6),
                CampoUmbral(
                  etiqueta: 'Nombre del personaje',
                  controlador: _nombre,
                  validador: Validaciones.nombrePersonaje,
                  accion: TextInputAction.done,
                  maximo: 16,
                  alEnviar: (_) => _comenzar(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: Espacios.paso4),
                  AvisoError(_error!),
                ],
                const SizedBox(height: Espacios.paso4),
                BotonUmbral(
                  texto: 'Cruzar el umbral',
                  cargando: _cargando,
                  alPulsar: _comenzar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionClase extends StatelessWidget {
  final ClaseUi clase;
  final String apariencia;
  final bool elegida;
  final double ancho;
  final VoidCallback alElegir;

  const _OpcionClase({
    required this.clase,
    required this.apariencia,
    required this.elegida,
    required this.ancho,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegida,
      label: clase.nombre,
      excludeSemantics: true,
      child: InkWell(
        onTap: alElegir,
        borderRadius: Radios.astilla,
        child: Container(
          width: ancho,
          padding: const EdgeInsets.all(Espacios.paso2),
          decoration: BoxDecoration(
            color: Colores.piedra,
            borderRadius: Radios.astilla,
            border: Border.all(
                color: elegida ? Colores.brasa : Colores.borde, width: 2),
          ),
          child: Column(
            children: [
              SpriteUmbral(
                  ruta: clase.sprite(apariencia), ancho: 32, alto: 40, escala: 2),
              const SizedBox(height: Espacios.paso1),
              // En pantallas estrechas se reduce un poco antes que partirse.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(clase.nombre.toUpperCase(),
                    maxLines: 1,
                    style: Textos.etiqueta(
                        color: elegida ? Colores.brasa : Colores.hueso)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Estadistica extends StatelessWidget {
  final String nombre;
  final int valor;

  const _Estadistica(this.nombre, this.valor);

  static const _maximo = 20;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacios.paso1),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text(nombre.toUpperCase(), style: Textos.etiqueta())),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colores.abismo,
                border: Border.all(color: Colores.borde, width: 2),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (valor / _maximo).clamp(0, 1),
                child: Container(color: Colores.hueso),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('$valor',
                textAlign: TextAlign.right, style: Textos.etiqueta()),
          ),
        ],
      ),
    );
  }
}
