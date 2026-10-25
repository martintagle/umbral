import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../servicio/modelos/partida_jugable.dart';
import '../../servicio/modelos/recompensa.dart';
import '../../servicio/partida_servicio.dart';
import '../juego/umbral_juego.dart';
import '../juego/zona_claro.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/panel_umbral.dart';

class JuegoPantalla extends StatefulWidget {
  final PartidaJugable partida;
  final Map<String, Recompensa> recompensas;

  const JuegoPantalla(
      {super.key, required this.partida, required this.recompensas});

  @override
  State<JuegoPantalla> createState() => _JuegoPantallaState();
}

class _JuegoPantallaState extends State<JuegoPantalla> {
  final _servicio = PartidaServicio();
  late final UmbralJuego _juego;
  bool _menu = false;
  bool _tituloZona = true;

  @override
  void initState() {
    super.initState();
    _juego = UmbralJuego(
      partida: widget.partida,
      recompensas: widget.recompensas,
      alGuardar: _servicio.registrarProgreso,
    )..alPedirMenu = _abrirMenu;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _tituloZona = false);
    });
  }

  void _abrirMenu() {
    if (_menu || _juego.muerto.value) return;
    _juego.pauseEngine();
    setState(() => _menu = true);
  }

  void _cerrarMenu() {
    _juego.resumeEngine();
    setState(() => _menu = false);
  }

  Future<void> _guardarYSalir() async {
    final ok = await _juego.guardar();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      _cerrarMenu();
    }
  }

  void _salirSinGuardar() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _menu ? _cerrarMenu() : _abrirMenu();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GameWidget(game: _juego, autofocus: true),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Espacios.paso4),
                child: Stack(
                  children: [
                    Align(
                        alignment: Alignment.topLeft,
                        child: _Estado(_juego)),
                    Align(
                      alignment: Alignment.topRight,
                      child: BotonUmbral(
                        texto: 'Menú',
                        estilo: EstiloBoton.secundario,
                        expandido: false,
                        alPulsar: _abrirMenu,
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _Joystick(_juego),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _Acciones(_juego),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.45),
                      child: _Aviso(_juego),
                    ),
                    if (_tituloZona)
                      Align(
                        alignment: const Alignment(0, -0.55),
                        child: IgnorePointer(
                          child: Text(
                            ZonaClaro.nombre,
                            textAlign: TextAlign.center,
                            style: Textos.tituloZona().copyWith(
                              shadows: const [
                                Shadow(
                                    color: Colores.abismo,
                                    offset: Offset(4, 4)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _juego.muerto,
              builder: (_, muerto, _) => muerto
                  ? _Capa(
                      titulo: 'Has caído',
                      texto: 'Las brasas del altar aún arden.',
                      acciones: [
                        BotonUmbral(
                          texto: 'Despertar junto al altar',
                          alPulsar: _juego.revivir,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            if (_menu)
              _Capa(
                titulo: 'Pausa',
                acciones: [
                  BotonUmbral(
                      texto: 'Continuar',
                      estilo: EstiloBoton.secundario,
                      alPulsar: _cerrarMenu),
                  const SizedBox(height: Espacios.paso4),
                  ValueListenableBuilder(
                    valueListenable: _juego.guardando,
                    builder: (_, guardando, _) => BotonUmbral(
                      texto: 'Guardar y salir',
                      cargando: guardando,
                      alPulsar: _guardarYSalir,
                    ),
                  ),
                  const SizedBox(height: Espacios.paso4),
                  BotonUmbral(
                    texto: 'Salir sin guardar',
                    estilo: EstiloBoton.secundario,
                    alPulsar: _salirSinGuardar,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Nombre, nivel, barras de PV y EXP, y oro.
class _Estado extends StatelessWidget {
  final UmbralJuego juego;

  const _Estado(this.juego);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: PanelUmbral(
          padding: const EdgeInsets.all(Espacios.paso2),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              juego.vida,
              juego.vidaMaxima,
              juego.nivel,
              juego.exp,
              juego.expSiguiente,
              juego.oro,
            ]),
            builder: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${juego.personaje.nombre.toUpperCase()} · NV ${juego.nivel.value}',
                  overflow: TextOverflow.ellipsis,
                  style: Textos.etiqueta(),
                ),
                const SizedBox(height: Espacios.paso1),
                _Barra(
                  etiqueta: 'PV ${juego.vida.value}/${juego.vidaMaxima.value}',
                  valor: juego.vida.value / juego.vidaMaxima.value,
                  color: Colores.sangre,
                  alto: 16,
                ),
                const SizedBox(height: Espacios.paso1),
                _Barra(
                  etiqueta: 'EXP ${juego.exp.value}/${juego.expSiguiente.value}',
                  valor: juego.exp.value / juego.expSiguiente.value,
                  color: Colores.borde,
                  alto: 16,
                ),
                const SizedBox(height: Espacios.paso1),
                Text('ORO ${juego.oro.value}',
                    style: Textos.etiqueta(color: Colores.brasa)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final String etiqueta;
  final double valor;
  final Color color;
  final double alto;

  const _Barra({
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.alto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: alto + 4,
      decoration: BoxDecoration(
        color: Colores.abismo,
        border: Border.all(color: Colores.borde, width: 2),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: valor.clamp(0, 1),
            child: Container(color: color),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Espacios.paso1),
            child: Align(
              alignment: Alignment.centerLeft,
              // Sombra dura para que el número se lea sobre cualquier relleno.
              child: Text(etiqueta,
                  style: Textos.etiqueta().copyWith(shadows: const [
                    Shadow(color: Colores.abismo, offset: Offset(1, 1)),
                  ])),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cruceta táctil: la dirección es la distancia del dedo al centro.
class _Joystick extends StatefulWidget {
  final UmbralJuego juego;

  const _Joystick(this.juego);

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const _tamano = 136.0;
  static const _recorrido = 44.0;
  Offset _perilla = Offset.zero;

  void _mover(Offset local) {
    var d = local - const Offset(_tamano / 2, _tamano / 2);
    if (d.distance > _recorrido) d = d / d.distance * _recorrido;
    setState(() => _perilla = d);
    widget.juego.direccionJoystick.setValues(d.dx / _recorrido, d.dy / _recorrido);
  }

  void _soltar() {
    setState(() => _perilla = Offset.zero);
    widget.juego.direccionJoystick.setZero();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cruceta de movimiento',
      child: Listener(
        onPointerDown: (e) => _mover(e.localPosition),
        onPointerMove: (e) => _mover(e.localPosition),
        onPointerUp: (_) => _soltar(),
        onPointerCancel: (_) => _soltar(),
        child: Container(
          width: _tamano,
          height: _tamano,
          decoration: BoxDecoration(
            color: Colores.piedra.withValues(alpha: 0.7),
            borderRadius: Radios.astilla,
            border: Border.all(color: Colores.borde, width: 2),
          ),
          child: Center(
            child: Transform.translate(
              offset: _perilla,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colores.borde,
                  borderRadius: Radios.astilla,
                  boxShadow: sombraDura,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de ataque (se puede mantener pulsado) y, junto al altar, descansar.
class _Acciones extends StatelessWidget {
  final UmbralJuego juego;

  const _Acciones(this.juego);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ValueListenableBuilder(
          valueListenable: juego.enElAltar,
          builder: (_, enElAltar, _) => enElAltar
              ? Padding(
                  padding: const EdgeInsets.only(bottom: Espacios.paso4),
                  child: ValueListenableBuilder(
                    valueListenable: juego.guardando,
                    builder: (_, guardando, _) => BotonUmbral(
                      texto: 'Descansar',
                      estilo: EstiloBoton.acento,
                      expandido: false,
                      cargando: guardando,
                      alPulsar: juego.descansar,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        Semantics(
          button: true,
          label: 'Atacar',
          child: Listener(
            onPointerDown: (_) => juego.botonAtaque = true,
            onPointerUp: (_) => juego.botonAtaque = false,
            onPointerCancel: (_) => juego.botonAtaque = false,
            child: Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colores.sangre,
                borderRadius: Radios.astilla,
                border: Border.all(color: Colores.abismo, width: 2),
                boxShadow: sombraDura,
              ),
              child: Text('ATACAR', style: Textos.etiqueta()),
            ),
          ),
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  final UmbralJuego juego;

  const _Aviso(this.juego);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: juego.aviso,
        builder: (_, aviso, _) => aviso == null
            ? const SizedBox.shrink()
            : Semantics(
                liveRegion: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: PanelUmbral(
                    colorBorde: Colores.brasa,
                    padding: const EdgeInsets.all(Espacios.paso2),
                    child: Text(aviso,
                        textAlign: TextAlign.center, style: Textos.cuerpo()),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Capa a pantalla completa para la pausa y la muerte.
class _Capa extends StatelessWidget {
  final String titulo;
  final String? texto;
  final List<Widget> acciones;

  const _Capa({required this.titulo, this.texto, required this.acciones});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colores.abismo.withValues(alpha: 0.85),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Espacios.paso4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(titulo,
                      textAlign: TextAlign.center, style: Textos.tituloZona()),
                  if (texto != null) ...[
                    const SizedBox(height: Espacios.paso2),
                    Text(texto!,
                        textAlign: TextAlign.center,
                        style: Textos.cuerpo(color: Colores.ceniza)),
                  ],
                  const SizedBox(height: Espacios.paso6),
                  ...acciones,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
