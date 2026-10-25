import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';
import 'icono_umbral.dart';

/// Variantes de `docs/diseno/interfaz/componentes.md`: una sola principal
/// por pantalla; acento para gastar oro o puntos; peligro para lo
/// irreversible.
enum EstiloBoton { principal, secundario, acento, peligro }

/// Botón con esquina astillada y sombra dura. Al pulsarlo se hunde un píxel de
/// arte, como si la sombra desapareciera.
class BotonUmbral extends StatefulWidget {
  final String texto;
  final VoidCallback? alPulsar;
  final EstiloBoton estilo;
  final bool cargando;
  final bool expandido;

  /// Icono a la izquierda, por nombre del set.
  final String? icono;

  /// Costo a la derecha (por ejemplo, el oro de una mejora).
  final String? costo;

  const BotonUmbral({
    super.key,
    required this.texto,
    required this.alPulsar,
    this.estilo = EstiloBoton.principal,
    this.cargando = false,
    this.expandido = true,
    this.icono,
    this.costo,
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
      EstiloBoton.acento => (Colores.brasa, Colores.abismo, Colores.abismo),
      EstiloBoton.peligro => (Colores.piedra, Colores.sangre, Colores.hueso),
    };
    final hundido = _pulsado && activo;
    final estiloTexto = Textos.cuerpo(color: activo ? texto : Colores.ceniza)
        .copyWith(fontWeight: FontWeight.w600);

    final boton = Semantics(
      button: true,
      enabled: activo,
      label: widget.costo == null
          ? widget.texto
          : '${widget.texto}, ${widget.costo}',
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
            boxShadow: hundido || !activo ? null : sombraDura,
          ),
          // Center con factor 1 se ajusta al contenido: `alignment` haría que
          // el botón ocupara todo el espacio libre del padre.
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icono != null) ...[
                  IconoUmbral(widget.icono!, escala: 1),
                  const SizedBox(width: Espacios.paso2),
                ],
                Flexible(
                  child: Text(
                    widget.cargando ? '${widget.texto}…' : widget.texto,
                    textAlign: TextAlign.center,
                    style: estiloTexto,
                  ),
                ),
                if (widget.costo != null) ...[
                  const SizedBox(width: Espacios.paso4),
                  Text(widget.costo!,
                      style: Textos.contador(
                          color: activo ? texto : Colores.ceniza)),
                ],
              ],
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

/// Botón cuadrado solo con icono (barra superior, cerrar, volver).
class BotonIcono extends StatefulWidget {
  final String icono;

  /// El icono solo no se lee: esta es su etiqueta.
  final String descripcion;
  final VoidCallback? alPulsar;

  /// Número pendiente (por ejemplo, puntos sin repartir).
  final int insignia;

  const BotonIcono({
    super.key,
    required this.icono,
    required this.descripcion,
    required this.alPulsar,
    this.insignia = 0,
  });

  @override
  State<BotonIcono> createState() => _BotonIconoState();
}

class _BotonIconoState extends State<BotonIcono> {
  bool _pulsado = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.alPulsar != null;
    final hundido = _pulsado && activo;
    return Semantics(
      button: true,
      enabled: activo,
      label: widget.descripcion,
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
        child: Opacity(
          opacity: activo ? 1 : 0.45,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                transform: Matrix4.translationValues(
                    hundido ? 4 : 0, hundido ? 4 : 0, 0),
                decoration: BoxDecoration(
                  color: Colores.piedra,
                  borderRadius: Radios.astilla,
                  border: Border.all(color: Colores.borde, width: 2),
                  boxShadow: hundido || !activo ? null : sombraDura,
                ),
                child: IconoUmbral(widget.icono),
              ),
              if (widget.insignia > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Espacios.paso1, vertical: 2),
                    color: Colores.sangre,
                    child: Text('${widget.insignia}',
                        style: Textos.etiqueta()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
