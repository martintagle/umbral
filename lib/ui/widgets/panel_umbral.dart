import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';

class PanelUmbral extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color colorBorde;

  const PanelUmbral({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Espacios.paso4),
    this.colorBorde = Colores.borde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colores.piedra,
        borderRadius: Radios.astilla,
        border: Border.all(color: colorBorde, width: 2),
        boxShadow: sombraDura,
      ),
      child: child,
    );
  }
}

/// Aviso de error: icono y texto, nunca solo color.
class AvisoError extends StatelessWidget {
  final String mensaje;

  const AvisoError(this.mensaje, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Espacios.paso2),
        decoration: const BoxDecoration(
          color: Colores.abismo,
          borderRadius: Radios.astilla,
          border: Border.fromBorderSide(
              BorderSide(color: Colores.sangre, width: 2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colores.brasa, size: 20),
            const SizedBox(width: Espacios.paso2),
            Expanded(child: Text(mensaje, style: Textos.cuerpo())),
          ],
        ),
      ),
    );
  }
}
