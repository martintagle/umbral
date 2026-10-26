import 'package:flutter/material.dart';

import '../../servicio/modelos/combate.dart';
import '../../servicio/modelos/partida_jugable.dart';
import '../../servicio/servicio_excepcion.dart';
import '../clases_ui.dart';
import '../sonido.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/icono_umbral.dart';
import '../widgets/panel_umbral.dart';

/// El yunque de la Herrería abandonada: sube de nivel el arma o la armadura
/// a cambio de oro. El costo y lo que da cada mejora los calcula el servidor.
class HerreriaPantalla extends StatefulWidget {
  final PartidaJugable partida;

  /// Mejora la pieza (`arma` o `armadura`) y devuelve la partida resultante.
  final Future<PartidaJugable> Function(String pieza) alMejorar;

  const HerreriaPantalla({
    super.key,
    required this.partida,
    required this.alMejorar,
  });

  @override
  State<HerreriaPantalla> createState() => _HerreriaPantallaState();
}

class _HerreriaPantallaState extends State<HerreriaPantalla> {
  static const _nivelMaximo = 10;

  late PartidaJugable _partida = widget.partida;
  String _pieza = 'arma';
  bool _cargando = false;
  String? _error;
  String? _hecho;

  Future<void> _mejorar() async {
    if (_cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
      _hecho = null;
    });
    try {
      final nueva = await widget.alMejorar(_pieza);
      Sonido.efecto(Audios.oro);
      if (!mounted) return;
      final equipo = nueva.partida.personaje.equipo;
      final nivel = _pieza == 'arma' ? equipo.nivelArma : equipo.nivelArmadura;
      setState(() {
        _partida = nueva;
        _hecho = 'Saltan chispas del yunque. Ahora es nivel $nivel.';
      });
    } on ServicioExcepcion catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final personaje = _partida.partida.personaje;
    final clase = claseUi(personaje.clase);
    final combate = _partida.combate;
    final esArma = _pieza == 'arma';
    final nivel = esArma
        ? personaje.equipo.nivelArma
        : personaje.equipo.nivelArmadura;
    final Mejora? mejora = esArma ? combate.mejoraArma : combate.mejoraArmadura;
    final valor = esArma ? combate.dano : combate.defensa;
    final falta = mejora == null ? 0 : mejora.costo - personaje.oro;

    // En horizontal: a la izquierda la pieza y su nivel; a la derecha lo que
    // cambia, el costo y el botón.
    final pieza = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Pestanas(
          elegida: _pieza,
          alElegir: (p) => setState(() {
            _pieza = p;
            _error = null;
            _hecho = null;
          }),
        ),
        const SizedBox(height: Espacios.paso4),
        Row(
          children: [
            _Ranura(icono: esArma ? clase.iconoArma : 'armadura', nivel: nivel),
            const SizedBox(width: Espacios.paso4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esArma ? clase.arma : clase.armadura,
                    style: Textos.encabezado(),
                  ),
                  Text(
                    mejora == null
                        ? 'NIVEL $nivel · MÁXIMO'
                        : 'NIVEL $nivel ▶ ${nivel + 1}',
                    style: Textos.etiqueta(color: Colores.brasa),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Espacios.paso4),
        _Pips(nivel: nivel, maximo: _nivelMaximo),
      ],
    );

    final detalle = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelUmbral(
          padding: const EdgeInsets.all(Espacios.paso2),
          child: Column(
            children: [
              _Cambio(
                esArma ? 'Daño' : 'Defensa',
                '$valor',
                mejora == null ? null : '${mejora.valorSiguiente}',
              ),
              if (mejora != null)
                _Material(
                  icono: 'oro',
                  nombre: 'Oro',
                  tengo: personaje.oro,
                  necesito: mejora.costo,
                ),
            ],
          ),
        ),
        if (mejora != null && falta > 0) ...[
          const SizedBox(height: Espacios.paso4),
          AvisoError(
            'Te faltan $falta de oro. Las criaturas lo sueltan al caer.',
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: Espacios.paso4),
          AvisoError(_error!),
        ],
        if (_hecho != null) ...[
          const SizedBox(height: Espacios.paso4),
          Semantics(
            liveRegion: true,
            child: Text(
              _hecho!,
              textAlign: TextAlign.center,
              style: Textos.cuerpo(color: Colores.brasa),
            ),
          ),
        ],
        const SizedBox(height: Espacios.paso4),
        BotonUmbral(
          texto: mejora == null ? 'Nivel máximo' : 'Mejorar',
          icono: 'yunque',
          estilo: EstiloBoton.acento,
          costo: mejora == null ? null : '${mejora.costo} ORO',
          cargando: _cargando,
          alPulsar: mejora != null && falta <= 0 ? _mejorar : null,
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Espacios.paso4,
                    Espacios.paso2,
                    Espacios.paso4,
                    Espacios.paso2,
                  ),
                  child: Row(
                    children: [
                      BotonIcono(
                        icono: 'atras',
                        descripcion: 'Volver',
                        alPulsar: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: Espacios.paso4),
                      Expanded(
                        child: Text('Herrería', style: Textos.tituloZona()),
                      ),
                      const IconoUmbral('oro', escala: 1),
                      const SizedBox(width: Espacios.paso1),
                      Text(
                        '${personaje.oro}',
                        style: Textos.contador(color: Colores.brasa),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(Espacios.paso4),
                          child: pieza,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(Espacios.paso4),
                          child: detalle,
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
    );
  }
}

class _Pestanas extends StatelessWidget {
  final String elegida;
  final ValueChanged<String> alElegir;

  const _Pestanas({required this.elegida, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    Widget pestana(String id, String texto, String icono) {
      final activa = id == elegida;
      return Expanded(
        child: Semantics(
          selected: activa,
          button: true,
          label: texto,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => alElegir(id),
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activa ? Colores.piedra : Colores.abismo,
                border: Border.all(color: Colores.borde, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconoUmbral(icono, escala: 1),
                  const SizedBox(width: Espacios.paso2),
                  Text(
                    texto.toUpperCase(),
                    style: Textos.etiqueta(
                      color: activa ? Colores.brasa : Colores.ceniza,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pestana('arma', 'Armas', 'espada'),
        pestana('armadura', 'Armaduras', 'armadura'),
      ],
    );
  }
}

/// Casilla de la pieza equipada: nivel arriba a la izquierda y el cuadrado
/// brasa de "equipada" arriba a la derecha.
class _Ranura extends StatelessWidget {
  final String icono;
  final int nivel;

  const _Ranura({required this.icono, required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colores.abismo,
        border: Border.all(color: Colores.brasa, width: 2),
      ),
      child: Stack(
        children: [
          Center(child: IconoUmbral(icono)),
          Positioned(
            left: 4,
            top: 2,
            child: Text(
              '+$nivel',
              style: Textos.etiqueta(color: Colores.brasa),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: Container(width: 6, height: 6, color: Colores.brasa),
          ),
        ],
      ),
    );
  }
}

/// Diez pips: los alcanzados en brasa y el siguiente en hueso.
class _Pips extends StatelessWidget {
  final int nivel;
  final int maximo;

  const _Pips({required this.nivel, required this.maximo});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nivel $nivel de $maximo',
      child: Row(
        children: [
          for (var i = 1; i <= maximo; i++)
            Expanded(
              child: Container(
                height: 12,
                margin: const EdgeInsets.only(right: Espacios.paso1),
                decoration: BoxDecoration(
                  color: i <= nivel ? Colores.brasa : Colores.abismo,
                  border: Border.all(
                    color: i == nivel + 1 ? Colores.hueso : Colores.borde,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cambio extends StatelessWidget {
  final String nombre;
  final String antes;
  final String? despues;

  const _Cambio(this.nombre, this.antes, this.despues);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(nombre, style: Textos.cuerpo())),
          Text(antes, style: Textos.contador()),
          if (despues != null) ...[
            Text('  ▶  ', style: Textos.contador(color: Colores.ceniza)),
            Text(despues!, style: Textos.contador(color: Colores.brasa)),
          ],
        ],
      ),
    );
  }
}

class _Material extends StatelessWidget {
  final String icono;
  final String nombre;
  final int tengo;
  final int necesito;

  const _Material({
    required this.icono,
    required this.nombre,
    required this.tengo,
    required this.necesito,
  });

  @override
  Widget build(BuildContext context) {
    final alcanza = tengo >= necesito;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          IconoUmbral(icono, escala: 1),
          const SizedBox(width: Espacios.paso2),
          Expanded(child: Text(nombre, style: Textos.cuerpo())),
          if (!alcanza) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Espacios.paso1),
              color: Colores.sangre,
              child: Text('FALTA', style: Textos.etiqueta()),
            ),
            const SizedBox(width: Espacios.paso2),
          ],
          Text(
            '$tengo/$necesito',
            style: Textos.contador(
              color: alcanza ? Colores.podredumbre : Colores.hueso,
            ),
          ),
        ],
      ),
    );
  }
}
