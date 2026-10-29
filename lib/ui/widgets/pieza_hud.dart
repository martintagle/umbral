import 'package:flutter/material.dart';

import '../../contrato/clase_codigo.dart';

/// Una pieza de `assets/hud/` (ver `hud.json`). Las que tienen varios estados
/// traen los cuadros en fila: el cuadro `i` está en `x = i · ancho`. Las
/// medidas están en píxeles de arte.
class PiezaHud {
  final String archivo;
  final int ancho;
  final int alto;
  final int cuadros;

  /// Lado del cuadrado tocable, mayor que el dibujo en los botones chicos.
  final int? areaTactil;

  const PiezaHud(
    this.archivo,
    this.ancho,
    this.alto, {
    this.cuadros = 1,
    this.areaTactil,
  });

  /// Las piezas se dibujan a escala entera 3x.
  static const escala = 3;

  /// Convierte píxeles de arte en píxeles lógicos.
  static double px(num arte) => arte * escala.toDouble();

  String get ruta => 'assets/hud/$archivo.png';

  static const vidaMarco = PiezaHud('vida-marco', 80, 11);
  static const vidaRelleno = PiezaHud('vida-relleno', 64, 5);
  static const vidaPerdida = PiezaHud('vida-perdida', 64, 5);
  static const estaminaMarco = PiezaHud('estamina-marco', 60, 9, cuadros: 2);
  static const estaminaRelleno = PiezaHud('estamina-relleno', 46, 3);
  static const jefeMarco = PiezaHud('jefe-marco', 120, 11);
  static const jefeRelleno = PiezaHud('jefe-relleno', 104, 5, cuadros: 2);
  static const iconoExp = PiezaHud('icono-exp', 9, 9);
  static const iconoOro = PiezaHud('icono-oro', 9, 9);
  static const rodar = PiezaHud(
    'boton-rodar',
    24,
    24,
    cuadros: 3,
    areaTactil: 30,
  );
  static const frasco = PiezaHud(
    'boton-frasco',
    16,
    20,
    cuadros: 3,
    areaTactil: 24,
  );
  static const menu = PiezaHud(
    'boton-menu',
    14,
    14,
    cuadros: 2,
    areaTactil: 18,
  );
  static const palancaBase = PiezaHud('palanca-base', 44, 44);
  static const palancaPerilla = PiezaHud('palanca-perilla', 16, 16, cuadros: 2);

  /// La perilla se aleja del centro de la base hasta esto, en píxeles de arte.
  static const recorridoPalanca = 14;

  static PiezaHud atacar(ClaseCodigo clase) => PiezaHud(
    'boton-atacar-${clase.name}',
    34,
    34,
    cuadros: 3,
    areaTactil: 40,
  );

  /// [accion]: `descansar`, `entrar`, `yunque`, `leer`, `abrir` o `hablar`.
  static PiezaHud accion(String accion) =>
      PiezaHud('boton-accion-$accion', 24, 24, cuadros: 2, areaTactil: 30);
}

/// Dibuja el cuadro [cuadro] de una [PiezaHud] a 3x y sin suavizado. Con
/// [recorte] menor que 1 solo se ve esa fracción, desde la izquierda y en
/// píxeles de arte enteros (así se rellenan las barras).
class CuadroHud extends StatelessWidget {
  final PiezaHud pieza;
  final int cuadro;
  final double recorte;

  const CuadroHud(this.pieza, {super.key, this.cuadro = 0, this.recorte = 1});

  @override
  Widget build(BuildContext context) {
    final ancho = PiezaHud.px(pieza.ancho);
    final alto = PiezaHud.px(pieza.alto);
    final visible = PiezaHud.px((pieza.ancho * recorte.clamp(0, 1)).round());
    return ClipRect(
      child: SizedBox(
        width: visible,
        height: alto,
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: ancho * pieza.cuadros,
          maxWidth: ancho * pieza.cuadros,
          child: Transform.translate(
            offset: Offset(-ancho * cuadro, 0),
            child: Image.asset(
              pieza.ruta,
              width: ancho * pieza.cuadros,
              height: alto,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.none,
              isAntiAlias: false,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra del HUD sin números: el marco y, dentro, el relleno recortado a
/// [valor] (de 0 a 1). [perdida], si se da, es el tramo recién perdido que va
/// detrás del relleno.
class BarraHud extends StatelessWidget {
  final PiezaHud marco;
  final int cuadroMarco;
  final PiezaHud relleno;
  final int cuadroRelleno;

  /// Posición del relleno dentro del marco, en píxeles de arte.
  final Offset origen;
  final double valor;
  final double? perdida;

  const BarraHud({
    super.key,
    required this.marco,
    this.cuadroMarco = 0,
    required this.relleno,
    this.cuadroRelleno = 0,
    required this.origen,
    required this.valor,
    this.perdida,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PiezaHud.px(marco.ancho),
      height: PiezaHud.px(marco.alto),
      child: Stack(
        children: [
          CuadroHud(marco, cuadro: cuadroMarco),
          Positioned(
            left: PiezaHud.px(origen.dx),
            top: PiezaHud.px(origen.dy),
            child: Stack(
              children: [
                if (perdida case final p? when p > valor)
                  CuadroHud(PiezaHud.vidaPerdida, recorte: p),
                CuadroHud(relleno, cuadro: cuadroRelleno, recorte: valor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón del HUD sin caja: actúa al tocarlo, sin esperar a soltar (en combate
/// cada décima cuenta). Mientras se toca muestra el cuadro 1 (presionado); si
/// no, [cuadro]. El área tocable es la de [PiezaHud.areaTactil].
class BotonHud extends StatefulWidget {
  final PiezaHud pieza;
  final String descripcion;
  final int cuadro;
  final VoidCallback? alPulsar;
  final VoidCallback? alSoltar;

  /// Se dibuja encima del emblema (por ejemplo, la cantidad de frascos).
  final Widget? encima;

  const BotonHud({
    super.key,
    required this.pieza,
    required this.descripcion,
    this.cuadro = 0,
    this.alPulsar,
    this.alSoltar,
    this.encima,
  });

  @override
  State<BotonHud> createState() => _BotonHudState();
}

class _BotonHudState extends State<BotonHud> {
  bool _presionado = false;

  void _soltar() {
    if (!_presionado) return;
    setState(() => _presionado = false);
    widget.alSoltar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final pieza = widget.pieza;
    final area = PiezaHud.px(pieza.areaTactil ?? pieza.ancho);
    return Semantics(
      button: true,
      label: widget.descripcion,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          setState(() => _presionado = true);
          widget.alPulsar?.call();
        },
        onPointerUp: (_) => _soltar(),
        onPointerCancel: (_) => _soltar(),
        child: SizedBox(
          width: area,
          height: area,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CuadroHud(pieza, cuadro: _presionado ? 1 : widget.cuadro),
              ?widget.encima,
            ],
          ),
        ),
      ),
    );
  }
}
