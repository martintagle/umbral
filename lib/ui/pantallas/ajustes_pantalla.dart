import 'package:flutter/material.dart';

import '../../contrato/clase_codigo.dart';
import '../sonido.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/panel_umbral.dart';

/// Volumen de la música y de los efectos. Se aplica al mover el control y se
/// guarda en el teléfono (y en la cuenta, si hay sesión) al volver.
class AjustesPantalla extends StatefulWidget {
  const AjustesPantalla({super.key});

  @override
  State<AjustesPantalla> createState() => _AjustesPantallaState();
}

class _AjustesPantallaState extends State<AjustesPantalla> {
  @override
  void dispose() {
    Sonido.guardarAjustes();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Espacios.paso4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      BotonIcono(
                        icono: 'atras',
                        descripcion: 'Volver',
                        alPulsar: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: Espacios.paso4),
                      Text('Ajustes', style: Textos.tituloZona()),
                    ],
                  ),
                  const SizedBox(height: Espacios.paso4),
                  PanelUmbral(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SONIDO',
                          style: Textos.etiqueta(color: Colores.ceniza),
                        ),
                        const SizedBox(height: Espacios.paso2),
                        _Volumen(nombre: 'Música', valor: Sonido.musica),
                        const SizedBox(height: Espacios.paso2),
                        _Volumen(
                          nombre: 'Efectos',
                          valor: Sonido.efectos,
                          // Un golpe de muestra al soltar el control.
                          alSoltar: () => Sonido.efecto(
                            Audios.ataque(ClaseCodigo.guerrero),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Espacios.paso4),
                  Text(
                    'Los ajustes se guardan en este teléfono y en tu cuenta.',
                    textAlign: TextAlign.center,
                    style: Textos.cuerpo(color: Colores.ceniza),
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

class _Volumen extends StatelessWidget {
  final String nombre;
  final ValueNotifier<double> valor;
  final VoidCallback? alSoltar;

  const _Volumen({required this.nombre, required this.valor, this.alSoltar});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: valor,
      builder: (_, v, _) => Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(nombre.toUpperCase(), style: Textos.etiqueta()),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colores.brasa,
                inactiveTrackColor: Colores.abismo,
                thumbColor: Colores.hueso,
                overlayColor: Colores.brasa.withValues(alpha: 0.2),
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10,
                  elevation: 0,
                  pressedElevation: 0,
                ),
                trackShape: const RectangularSliderTrackShape(),
              ),
              child: Slider(
                value: v,
                divisions: 20,
                semanticFormatterCallback: (v) =>
                    '$nombre ${(v * 100).round()} %',
                onChanged: (nuevo) => valor.value = nuevo,
                onChangeEnd: (_) => alSoltar?.call(),
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              v == 0 ? 'NO' : '${(v * 100).round()}%',
              textAlign: TextAlign.right,
              style: Textos.contador(
                color: v == 0 ? Colores.ceniza : Colores.hueso,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
