import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';

/// Campo de texto del juego. Si es [oculto] (una contraseña), trae un botón
/// para mostrar u ocultar lo escrito.
class CampoUmbral extends StatefulWidget {
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
  State<CampoUmbral> createState() => _CampoUmbralState();
}

class _CampoUmbralState extends State<CampoUmbral> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controlador,
      validator: widget.validador,
      obscureText: widget.oculto && !_visible,
      keyboardType: widget.oculto && _visible
          ? TextInputType.visiblePassword
          : widget.teclado,
      textInputAction: widget.accion,
      autofillHints: widget.autocompletar,
      onFieldSubmitted: widget.alEnviar,
      maxLength: widget.maximo,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: Textos.cuerpo(),
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        labelStyle: Textos.cuerpo(color: Colores.ceniza),
        floatingLabelStyle: Textos.etiqueta(color: Colores.brasa),
        errorStyle: Textos.etiqueta(color: Colores.brasa),
        errorMaxLines: 3,
        counterStyle: Textos.etiqueta(color: Colores.ceniza),
        filled: true,
        fillColor: Colores.abismo,
        border: CampoUmbral._bordeNormal,
        enabledBorder: CampoUmbral._bordeNormal,
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
        suffixIcon: widget.oculto
            ? IconButton(
                tooltip: _visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
                icon: Icon(
                  _visible ? Icons.visibility_off : Icons.visibility,
                  color: Colores.ceniza,
                ),
                onPressed: () => setState(() => _visible = !_visible),
              )
            : null,
      ),
    );
  }
}
