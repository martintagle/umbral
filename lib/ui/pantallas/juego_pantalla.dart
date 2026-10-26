import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../servicio/modelos/partida_jugable.dart';
import '../../servicio/modelos/recompensa.dart';
import '../../servicio/partida_servicio.dart';
import '../clases_ui.dart';
import '../juego/umbral_juego.dart';
import '../sonido.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/confirmacion_umbral.dart';
import '../widgets/icono_umbral.dart';
import '../widgets/panel_umbral.dart';
import 'ajustes_pantalla.dart';
import 'estadisticas_pantalla.dart';
import 'herreria_pantalla.dart';

class JuegoPantalla extends StatefulWidget {
  final PartidaJugable partida;
  final Map<String, Recompensa> recompensas;

  const JuegoPantalla({
    super.key,
    required this.partida,
    required this.recompensas,
  });

  @override
  State<JuegoPantalla> createState() => _JuegoPantallaState();
}

class _JuegoPantallaState extends State<JuegoPantalla> {
  final _servicio = PartidaServicio();
  late final UmbralJuego _juego;
  bool _menu = false;
  bool _enOtraPantalla = false;
  bool _tituloZona = false;
  int _tituloId = 0;

  @override
  void initState() {
    super.initState();
    _juego =
        UmbralJuego(
            partida: widget.partida,
            recompensas: widget.recompensas,
            alGuardar: _servicio.registrarProgreso,
          )
          ..alPedirMenu = _abrirMenu
          ..alAbrirPantalla = _abrirPantalla;
    _juego.region.addListener(_anunciarRegion);
  }

  @override
  void dispose() {
    _juego.region.removeListener(_anunciarRegion);
    Sonido.silenciarJuego();
    super.dispose();
  }

  /// Muestra el nombre de la región durante 3 segundos al entrar en ella.
  void _anunciarRegion() {
    final id = ++_tituloId;
    setState(() => _tituloZona = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _tituloId == id) setState(() => _tituloZona = false);
    });
  }

  void _abrirMenu() {
    if (_menu || _juego.muerto.value) return;
    _juego
      ..soltarControles()
      ..pauseEngine();
    Sonido.silenciarJuego();
    setState(() => _menu = true);
  }

  Future<void> _abrirAjustes() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AjustesPantalla()),
  );

  void _cerrarMenu() {
    _juego.resumeEngine();
    setState(() => _menu = false);
  }

  /// Guarda antes de abrir (así el oro y los niveles ganados ya cuentan) y
  /// pausa el juego mientras la otra pantalla está encima.
  Future<void> _abrirPantalla(PantallaJuego pantalla) async {
    if (_menu || _enOtraPantalla || _juego.muerto.value) return;
    _enOtraPantalla = true;
    _juego
      ..soltarControles()
      ..pauseEngine();
    if (await _juego.guardar(silencioso: true) && mounted) {
      final partida = _juego.partidaGuardada;
      final id = partida.partida.partidaId;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => switch (pantalla) {
            PantallaJuego.estadisticas => EstadisticasPantalla(
              partida: partida,
              alSubir: (incrementos) =>
                  _aplicar(_servicio.subirAtributos(id, incrementos)),
            ),
            PantallaJuego.herreria => HerreriaPantalla(
              partida: partida,
              alMejorar: (pieza) =>
                  _aplicar(_servicio.mejorarEquipo(id, pieza)),
            ),
          },
        ),
      );
    }
    _juego.resumeEngine();
    _enOtraPantalla = false;
  }

  /// Lleva al juego la partida que devuelve el servidor tras un cambio.
  Future<PartidaJugable> _aplicar(Future<PartidaJugable> peticion) async {
    final nueva = await peticion;
    _juego.aplicarPartida(nueva);
    return nueva;
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

  Future<void> _salirSinGuardar() async {
    final ok = await confirmar(
      context,
      titulo: '¿Salir sin guardar?',
      texto:
          'Perderás la experiencia y el oro ganados desde el último guardado.',
      verbo: 'Salir',
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

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
            Positioned.fill(child: GameWidget(game: _juego, autofocus: true)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(Espacios.paso4),
                child: Stack(
                  children: [
                    Align(alignment: Alignment.topLeft, child: _Estado(_juego)),
                    Align(
                      alignment: Alignment.topRight,
                      child: BotonIcono(
                        icono: 'ajustes',
                        descripcion: 'Menú',
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
                      alignment: const Alignment(0, 0.3),
                      child: _Aviso(_juego),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _BarraJefe(_juego),
                    ),
                    Center(child: _Titular(_juego)),
                    if (_tituloZona)
                      Align(
                        alignment: const Alignment(0, -0.55),
                        child: IgnorePointer(
                          child: Text(
                            _juego.region.value,
                            textAlign: TextAlign.center,
                            style: Textos.tituloZona().copyWith(
                              shadows: const [
                                Shadow(
                                  color: Colores.abismo,
                                  offset: Offset(4, 4),
                                ),
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
                      titulo: 'HAS CAÍDO',
                      colorTitulo: Colores.sangre,
                      texto: (_juego.brasasPerdidas.value ?? '').isEmpty
                          ? 'Las brasas aún arden.'
                          : _juego.brasasPerdidas.value,
                      acciones: [
                        BotonUmbral(
                          texto: 'Despertar ${_juego.lugarDeDescanso}',
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
                    alPulsar: _cerrarMenu,
                  ),
                  const SizedBox(height: Espacios.paso4),
                  BotonUmbral(
                    texto: 'Ajustes',
                    icono: 'ajustes',
                    estilo: EstiloBoton.secundario,
                    alPulsar: _abrirAjustes,
                  ),
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
                    estilo: EstiloBoton.peligro,
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
                _BarraEstamina(juego),
                const SizedBox(height: Espacios.paso1),
                _Barra(
                  etiqueta:
                      'EXP ${juego.exp.value}/${juego.expSiguiente.value}',
                  valor: juego.exp.value / juego.expSiguiente.value,
                  color: Colores.borde,
                  alto: 12,
                ),
                const SizedBox(height: Espacios.paso1),
                Row(
                  children: [
                    const IconoUmbral('oro', escala: 1),
                    const SizedBox(width: Espacios.paso1),
                    Text(
                      '${juego.oro.value}',
                      style: Textos.etiqueta(color: Colores.brasa),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Se gasta al atacar y se recupera sola. Se redibuja aparte del resto del
/// panel porque cambia en cada cuadro. Si no alcanza para un ataque, el borde
/// se pone rojo.
class _BarraEstamina extends StatelessWidget {
  final UmbralJuego juego;

  const _BarraEstamina(this.juego);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([juego.estamina, juego.sinEstamina]),
      builder: (_, _) => _Barra(
        etiqueta: 'EST ${juego.estamina.value.floor()}',
        valor: juego.estamina.value / UmbralJuego.estaminaMaxima,
        color: Colores.podredumbre,
        alto: 12,
        colorBorde: juego.sinEstamina.value ? Colores.sangre : Colores.borde,
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final String etiqueta;
  final double valor;
  final Color color;
  final double alto;
  final Color colorBorde;

  const _Barra({
    required this.etiqueta,
    required this.valor,
    required this.color,
    required this.alto,
    this.colorBorde = Colores.borde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: alto + 4,
      decoration: BoxDecoration(
        color: Colores.abismo,
        border: Border.all(color: colorBorde, width: 2),
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
              child: Text(
                etiqueta,
                style: Textos.etiqueta().copyWith(
                  shadows: const [
                    Shadow(color: Colores.abismo, offset: Offset(1, 1)),
                  ],
                ),
              ),
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
    widget.juego.direccionJoystick.setValues(
      d.dx / _recorrido,
      d.dy / _recorrido,
    );
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

/// Lo que se puede hacer en el lugar (descansar, entrar, usar el yunque...)
/// y debajo los botones de combate: frasco y rodar a la izquierda del de
/// ataque, que se puede mantener pulsado.
class _Acciones extends StatelessWidget {
  final UmbralJuego juego;

  const _Acciones(this.juego);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([juego.acciones, juego.guardando]),
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final a in juego.acciones.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacios.paso2),
                  child: BotonUmbral(
                    texto: a.etiqueta,
                    icono: a.icono,
                    estilo: a.estilo,
                    expandido: false,
                    cargando: juego.guardando.value,
                    alPulsar: a.alPulsar,
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder(
                  valueListenable: juego.frascos,
                  builder: (_, quedan, _) => _BotonCombate(
                    etiqueta: 'Beber un frasco, quedan $quedan',
                    tamano: 56,
                    color: quedan > 0 ? Colores.piedra : Colores.abismo,
                    alPulsar: juego.pedirBeber,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const IconoUmbral('pocion-vida', escala: 1),
                        const SizedBox(width: 2),
                        Text(
                          '$quedan',
                          style: Textos.contador(
                            color: quedan > 0 ? Colores.brasa : Colores.ceniza,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: Espacios.paso2),
                _BotonCombate(
                  etiqueta: 'Rodar',
                  tamano: 68,
                  color: Colores.piedra,
                  alPulsar: juego.pedirRodar,
                  child: Text('RODAR', style: Textos.etiqueta()),
                ),
              ],
            ),
            const SizedBox(width: Espacios.paso2),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconoUmbral(claseUi(juego.personaje.clase).iconoArma),
                      const SizedBox(height: Espacios.paso1),
                      Text('ATACAR', style: Textos.etiqueta()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botón cuadrado que actúa al tocarlo, sin esperar a soltar: en combate
/// cada décima cuenta.
class _BotonCombate extends StatelessWidget {
  final String etiqueta;
  final double tamano;
  final Color color;
  final VoidCallback alPulsar;
  final Widget child;

  const _BotonCombate({
    required this.etiqueta,
    required this.tamano,
    required this.color,
    required this.alPulsar,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: etiqueta,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => alPulsar(),
        child: Container(
          width: tamano,
          height: tamano,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: Radios.astilla,
            border: Border.all(color: Colores.borde, width: 2),
            boxShadow: sombraDura,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Nombre y vida del jefe, abajo y a lo ancho, mientras dura el combate.
class _BarraJefe extends StatelessWidget {
  final UmbralJuego juego;

  const _BarraJefe(this.juego);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: Listenable.merge([juego.jefe, juego.vidaJefe]),
        builder: (context, _) {
          final jefe = juego.jefe.value;
          if (jefe == null) return const SizedBox.shrink();
          final ancho = MediaQuery.sizeOf(context).width * 0.4;
          return Padding(
            padding: const EdgeInsets.only(bottom: Espacios.paso2),
            child: SizedBox(
              width: ancho,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jefe.tipo.nombre,
                    style: Textos.cuerpo().copyWith(
                      shadows: const [
                        Shadow(color: Colores.abismo, offset: Offset(2, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: Espacios.paso1),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colores.abismo,
                      border: Border.all(color: Colores.borde, width: 2),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: juego.vidaJefe.value.clamp(0, 1),
                      child: Container(
                        color: jefe.furioso ? Colores.brasa : Colores.sangre,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Letrero grande al vencer a un jefe.
class _Titular extends StatelessWidget {
  final UmbralJuego juego;

  const _Titular(this.juego);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder(
        valueListenable: juego.titular,
        builder: (_, texto, _) => texto == null
            ? const SizedBox.shrink()
            : Semantics(
                liveRegion: true,
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: Textos.tituloJuego(color: Colores.brasa).copyWith(
                    shadows: const [
                      Shadow(color: Colores.abismo, offset: Offset(4, 4)),
                    ],
                  ),
                ),
              ),
      ),
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
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: PanelUmbral(
                    colorBorde: Colores.brasa,
                    padding: const EdgeInsets.all(Espacios.paso2),
                    child: Text(
                      aviso,
                      textAlign: TextAlign.center,
                      style: Textos.cuerpo(),
                    ),
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
  final Color? colorTitulo;

  const _Capa({
    required this.titulo,
    this.texto,
    required this.acciones,
    this.colorTitulo,
  });

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
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: colorTitulo == null
                        ? Textos.tituloZona()
                        : Textos.tituloJuego(color: colorTitulo!),
                  ),
                  if (texto != null) ...[
                    const SizedBox(height: Espacios.paso2),
                    Text(
                      texto!,
                      textAlign: TextAlign.center,
                      style: Textos.cuerpo(color: Colores.ceniza),
                    ),
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
