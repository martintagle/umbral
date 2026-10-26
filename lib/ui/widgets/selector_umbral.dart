import 'dart:async';

import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';
import 'icono_umbral.dart';

/// Restar / valor / sumar. El valor se pinta en brasa si difiere del
/// guardado. Mantener pulsado repite cada 120 ms.
class SelectorUmbral extends StatelessWidget {
  final int valor;
  final bool cambiado;
  final String descripcion;

  /// `null` deshabilita el botón.
  final VoidCallback? alRestar;
  final VoidCallback? alSumar;

  const SelectorUmbral({
    super.key,
    required this.valor,
    required this.descripcion,
    required this.alRestar,
    required this.alSumar,
    this.cambiado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Paso(
          icono: 'menos',
          descripcion: 'Restar $descripcion',
          alPulsar: alRestar,
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: Textos.contador(
              color: cambiado ? Colores.brasa : Colores.hueso,
            ),
          ),
        ),
        _Paso(
          icono: 'mas',
          descripcion: 'Sumar $descripcion',
          alPulsar: alSumar,
        ),
      ],
    );
  }
}

class _Paso extends StatefulWidget {
  final String icono;
  final String descripcion;
  final VoidCallback? alPulsar;

  const _Paso({
    required this.icono,
    required this.descripcion,
    required this.alPulsar,
  });

  @override
  State<_Paso> createState() => _PasoState();
}

class _PasoState extends State<_Paso> {
  Timer? _repetir;

  void _soltar() {
    _repetir?.cancel();
    _repetir = null;
  }

  @override
  void didUpdateWidget(_Paso anterior) {
    super.didUpdateWidget(anterior);
    // Al llegar al tope el botón se deshabilita: deja de repetir.
    if (widget.alPulsar == null) _soltar();
  }

  @override
  void dispose() {
    _soltar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.alPulsar != null;
    return Semantics(
      button: true,
      enabled: activo,
      label: widget.descripcion,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.alPulsar,
        onLongPressStart: activo
            ? (_) => _repetir = Timer.periodic(
                const Duration(milliseconds: 120),
                (_) => widget.alPulsar?.call(),
              )
            : null,
        onLongPressEnd: (_) => _soltar(),
        onLongPressCancel: _soltar,
        // Área táctil de 48 px alrededor del botón de 36.
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          color: Colors.transparent,
          child: Opacity(
            opacity: activo ? 1 : 0.45,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colores.piedra,
                borderRadius: Radios.astilla,
                border: Border.all(color: Colores.borde, width: 2),
              ),
              child: IconoUmbral(widget.icono, escala: 1),
            ),
          ),
        ),
      ),
    );
  }
}
