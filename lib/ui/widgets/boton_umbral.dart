import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';

enum EstiloBoton { principal, secundario, acento }

/// Botón con esquina astillada y sombra dura. Al pulsarlo se hunde un píxel de
/// arte, como si la sombra desapareciera.
class BotonUmbral extends StatefulWidget {
  final String texto;
  final VoidCallback? alPulsar;
  final EstiloBoton estilo;
  final bool cargando;
  final bool expandido;

  const BotonUmbral({
    super.key,
    required this.texto,
    required this.alPulsar,
    this.estilo = EstiloBoton.principal,
    this.cargando = false,
    this.expandido = true,
  });

  @override
  State<BotonUmbral> createState() => _BotonUmbralState();
}

class _BotonUmbralState extends State<BotonUmbral> {
  bool _pulsado = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.alPulsar != null && !widget.cargando;
    final (fondo, contorno, texto) = switch (widget.estilo) {
      EstiloBoton.principal => (Colores.sangre, Colores.abismo, Colores.hueso),
      EstiloBoton.secundario => (Colores.piedra, Colores.borde, Colores.hueso),
      EstiloBoton.acento => (Colores.piedra, Colores.brasa, Colores.brasa),
    };
    final hundido = _pulsado && activo;

    final boton = Semantics(
      button: true,
      enabled: activo,
      label: widget.texto,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: activo ? (_) => setState(() => _pulsado = true) : null,
        onTapCancel: () => setState(() => _pulsado = false),
        onTapUp: activo
            ? (_) {
                setState(() => _pulsado = false);
                widget.alPulsar!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 40),
          constraints: const BoxConstraints(minHeight: 48),
          transform: Matrix4.translationValues(
              hundido ? 4 : 0, hundido ? 4 : 0, 0),
          padding: const EdgeInsets.symmetric(
              horizontal: Espacios.paso4, vertical: Espacios.paso2),
          decoration: BoxDecoration(
            color: activo ? fondo : Colores.piedra,
            borderRadius: Radios.astilla,
            border: Border.all(
                color: activo ? contorno : Colores.borde, width: 2),
            boxShadow: hundido ? null : sombraDura,
          ),
          // Center con factor 1 se ajusta al texto: `alignment` haría que el
          // botón ocupara todo el espacio libre del padre.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              widget.cargando ? '${widget.texto}…' : widget.texto,
              textAlign: TextAlign.center,
              style: Textos.cuerpo(color: activo ? texto : Colores.ceniza)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );

    return widget.expandido
        ? SizedBox(width: double.infinity, child: boton)
        : boton;
  }
}
