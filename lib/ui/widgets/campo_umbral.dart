import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';

class CampoUmbral extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controlador;
  final String? Function(String?)? validador;
  final bool oculto;
  final TextInputType teclado;
  final TextInputAction accion;
  final Iterable<String>? autocompletar;
  final ValueChanged<String>? alEnviar;
  final int? maximo;

  const CampoUmbral({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.validador,
    this.oculto = false,
    this.teclado = TextInputType.text,
    this.accion = TextInputAction.next,
    this.autocompletar,
    this.alEnviar,
    this.maximo,
  });

  static const _bordeNormal = OutlineInputBorder(
    borderRadius: Radios.astilla,
    borderSide: BorderSide(color: Colores.borde, width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      validator: validador,
      obscureText: oculto,
      keyboardType: teclado,
      textInputAction: accion,
      autofillHints: autocompletar,
      onFieldSubmitted: alEnviar,
      maxLength: maximo,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Textos.cuerpo(),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: Textos.cuerpo(color: Colores.ceniza),
        floatingLabelStyle: Textos.etiqueta(color: Colores.brasa),
        errorStyle: Textos.etiqueta(color: Colores.brasa),
        errorMaxLines: 3,
        counterStyle: Textos.etiqueta(color: Colores.ceniza),
        filled: true,
        fillColor: Colores.abismo,
        border: _bordeNormal,
        enabledBorder: _bordeNormal,
        focusedBorder: const OutlineInputBorder(
          borderRadius: Radios.astilla,
          borderSide: BorderSide(color: Colores.brasa, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: Radios.astilla,
          borderSide: BorderSide(color: Colores.sangre, width: 2),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: Radios.astilla,
          borderSide: BorderSide(color: Colores.brasa, width: 2),
        ),
        prefixIcon: null,
      ),
    );
  }
}
