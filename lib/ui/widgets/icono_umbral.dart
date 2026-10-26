import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Índice de `assets/iconos/iconos.json`. Se carga una vez al arrancar.
abstract final class Iconos {
  static const _carpeta = 'assets/iconos/';
  static String _hoja = '${_carpeta}iconos.png';
  static int _tamano = 16;
  static int _columnas = 8;
  static Map<String, int> _indice = const {};

  static Future<void> cargar() async {
    final m = jsonDecode(
      await rootBundle.loadString('${_carpeta}iconos.json'),
    ) as Map<String, dynamic>;
    _hoja = '$_carpeta${m['imagen']}';
    _tamano = m['tamano'] as int;
    _columnas = m['columnas'] as int;
    _indice = Map<String, int>.from(m['iconos'] as Map);
  }

  static int get _filas => (_indice.length + _columnas - 1) ~/ _columnas;
}

/// Un icono de 16×16 del set, a escala entera y sin suavizado. [escala] 1 da
/// 16 px (`chico`) y 2 da 32 px.
class IconoUmbral extends StatelessWidget {
  final String nombre;
  final int escala;

  /// Texto para lectores de pantalla; sin él, el icono es decorativo.
  final String? descripcion;

  const IconoUmbral(
    this.nombre, {
    super.key,
    this.escala = 2,
    this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final lado = (Iconos._tamano * escala).toDouble();
    final i = Iconos._indice[nombre];
    if (i == null) return SizedBox.square(dimension: lado);
    final icono = SizedBox.square(
      dimension: lado,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: 0,
          minHeight: 0,
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: Transform.translate(
            offset: Offset(
              -(i % Iconos._columnas) * lado,
              -(i ~/ Iconos._columnas) * lado,
            ),
            child: Image.asset(
              Iconos._hoja,
              width: Iconos._columnas * lado,
              height: Iconos._filas * lado,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
    return descripcion == null
        ? ExcludeSemantics(child: icono)
        : Semantics(label: descripcion, image: true, child: icono);
  }
}
