import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';
import 'boton_umbral.dart';
import 'panel_umbral.dart';

/// Pregunta antes de algo irreversible. El botón seguro va a la izquierda;
/// el destructivo, a la derecha y con el verbo de la pregunta. Devuelve
/// `true` si se confirma.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String verbo,
  String cancelar = 'Volver',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: Colores.abismo.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(Espacios.paso4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: PanelUmbral(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(titulo, style: Textos.encabezado()),
              const SizedBox(height: Espacios.paso2),
              Text(texto, style: Textos.cuerpo(color: Colores.ceniza)),
              const SizedBox(height: Espacios.paso6),
              Row(
                children: [
                  Expanded(
                    child: BotonUmbral(
                      texto: cancelar,
                      estilo: EstiloBoton.secundario,
                      alPulsar: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: Espacios.paso4),
                  Expanded(
                    child: BotonUmbral(
                      texto: verbo,
                      estilo: EstiloBoton.peligro,
                      alPulsar: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}
