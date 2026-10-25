import 'package:flutter/material.dart';

/// Dibuja un sprite a escala entera y sin suavizado, como pide el diseño.
class SpriteUmbral extends StatelessWidget {
  final String ruta;
  final int ancho;
  final int alto;
  final int escala;
  final String? descripcion;

  const SpriteUmbral({
    super.key,
    required this.ruta,
    required this.ancho,
    required this.alto,
    this.escala = 4,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ruta,
      width: (ancho * escala).toDouble(),
      height: (alto * escala).toDouble(),
      // Sin `fill`, Image no agranda por encima del tamaño real del PNG.
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      semanticLabel: descripcion,
      excludeFromSemantics: descripcion == null,
    );
  }
}
