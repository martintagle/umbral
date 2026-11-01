import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../contrato/partida_jugable.dart';
import '../../contrato/recompensa.dart';
import '../../contrato/rol_usuario.dart';
import '../../api/partida_api.dart';
import '../../api/sesion.dart';
import '../juego/oreste.dart';
import '../juego/umbral_juego.dart';
import '../sonido.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/confirmacion_umbral.dart';
import '../widgets/panel_umbral.dart';
import '../widgets/pieza_hud.dart';
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
  final _api = PartidaApi();
  late final UmbralJuego _juego;
  bool _menu = false;
  bool _enOtraPantalla = false;
  bool _tituloZona = false;
  int _tituloId = 0;

  /// El final: primero la elección y después lo que pasa.
  _Final? _final;

  @override
  void initState() {
    super.initState();
    _juego =
        UmbralJuego(
            partida: widget.partida,
            recompensas: widget.recompensas,
            alGuardar: _api.registrarProgreso,
            admin: Sesion.usuario?.rol == RolUsuario.admin,
          )
          ..alPedirMenu = _abrirMenu
          ..alAbrirPantalla = _abrirPantalla
          ..alFinal = _llegarAlFinal;
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
                  _aplicar(_api.subirAtributos(id, incrementos)),
            ),
            PantallaJuego.herreria => HerreriaPantalla(
              partida: partida,
              alMejorar: (pieza) =>
                  _aplicar(_api.mejorarEquipo(id, pieza)),
            ),
          },
        ),
      );
    }
    _juego.resumeEngine();
    _enOtraPantalla = false;
  }

  /// Con El Que Mira vencido, el Altar Mayor espera la última decisión.
  void _llegarAlFinal() {
    _juego
      ..soltarControles()
      ..pauseEngine();
    setState(() => _final = _Final.eleccion);
  }

  void _elegirFinal(_Final elegido) {
    Sonido.pista(elegido == _Final.encender ? Audios.musicaTitulo : null);
    setState(() => _final = elegido);
  }

  /// Aún no: se vuelve a la arena.
  void _aplazarFinal() {
    _juego
      ..seguirTrasElFinal()
      ..resumeEngine();
    setState(() => _final = null);
  }

  /// La elección ante el Altar Mayor y sus dos finales (`docs/guion.md`).
  /// Romper la Brasa solo se puede con la astilla de nada.
  Widget _capaFinal(_Final f) {
    void volver() => Navigator.of(context).pop();
    final astilla = _juego.cofreAbierto(DatosOreste.cofreAstilla);
    return switch (f) {
      _Final.eleccion => _Capa(
        titulo: 'El Altar Mayor',
        texto: astilla
            ? 'Las seis ascuas arden en tus manos. En tu bolsillo, la astilla '
                  'de nada no pesa.'
            : 'Las seis ascuas arden en tus manos. La Brasa Primera espera, '
                  'apagada.',
        acciones: [
          BotonUmbral(
            texto: 'Encender la Brasa',
            alPulsar: () => _elegirFinal(_Final.encender),
          ),
          if (astilla) ...[
            const SizedBox(height: Espacios.paso4),
            BotonUmbral(
              texto: 'Romper la Brasa',
              estilo: EstiloBoton.peligro,
              alPulsar: () => _elegirFinal(_Final.romper),
            ),
          ],
          const SizedBox(height: Espacios.paso4),
          BotonUmbral(
            texto: 'Todavía no',
            estilo: EstiloBoton.secundario,
            alPulsar: _aplazarFinal,
          ),
        ],
      ),
      _Final.encender => _Capa(
        titulo: 'El Umbral se cierra',
        colorTitulo: Colores.brasa,
        texto:
            'Enciendes la Brasa y el Umbral se cierra. Te sientas junto al '
            'Altar. Primero olvidas el camino, luego las caras, luego la '
            'palabra "yo".\n\nEn la aldea Cenizal, las chozas vuelven a tener '
            'luz. Junto al altar hay una estatua nueva. No tiene rostro.',
        acciones: [BotonUmbral(texto: 'Volver a las partidas', alPulsar: volver)],
      ),
      _Final.romper => _Capa(
        titulo: 'El Umbral se abre',
        colorTitulo: Colores.sangre,
        texto:
            'Clavas la astilla en la llama. La Brasa no se apaga: se agrieta, '
            'sin ruido, como hielo. Por todo el mundo, los altares se apagan '
            'uno a uno, y los que se levantaban se sientan y se quedan '
            'quietos. Al borde, Oreste apaga la última vela y dice su nombre '
            'en voz alta.\n\nEntras en el Hueco.',
        acciones: [
          BotonUmbral(
            texto: 'Continuar',
            estilo: EstiloBoton.peligro,
            alPulsar: () => setState(() => _final = _Final.nombre),
          ),
        ],
      ),
      _Final.nombre => _CapaNombre(
        nombre: _juego.personaje.nombre,
        alVolver: volver,
      ),
    };
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
        if (didPop) return;
        // Atrás cierra el diálogo sin darlo por leído, y el mapa.
        if (_juego.dialogo.value != null) {
          _juego.cerrarDialogo(leido: false);
        } else if (_juego.menuFogata.value != null) {
          _juego.cerrarMenuFogata();
        } else if (_juego.mapaAbierto.value != null) {
          _juego.cerrarMapa();
        } else {
          _menu ? _cerrarMenu() : _abrirMenu();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _juego, autofocus: true)),
            SafeArea(
              child: Padding(
                // Márgenes de 6 píxeles de arte, además del área segura.
                padding: EdgeInsets.all(PiezaHud.px(6)),
                child: Stack(
                  children: [
                    // Arriba: el estado, la vida del jefe en el espacio libre
                    // del centro y el menú en la esquina.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Estado(_juego),
                        Expanded(child: Center(child: _BarraJefe(_juego))),
                        BotonHud(
                          pieza: PiezaHud.menu,
                          descripcion: 'Menú',
                          alPulsar: _abrirMenu,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: _Palanca(_juego),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: _Acciones(_juego),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.3),
                      child: _Aviso(_juego),
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
            ValueListenableBuilder(
              valueListenable: _juego.dialogo,
              builder: (_, dialogo, _) => dialogo == null
                  ? const SizedBox.shrink()
                  : _CapaDialogo(_juego, dialogo),
            ),
            // El menú de la fogata: lo que antes eran varios botones sobre el
            // de atacar. Mientras se guarda el descanso, las opciones esperan.
            ListenableBuilder(
              listenable: Listenable.merge([_juego.menuFogata, _juego.guardando]),
              builder: (_, _) {
                final opciones = _juego.menuFogata.value;
                if (opciones == null) return const SizedBox.shrink();
                final guardando = _juego.guardando.value;
                return _Capa(
                  titulo: 'Junto a las brasas',
                  texto: guardando
                      ? 'Descansas. Guardando la partida…'
                      : 'Descansas. Las criaturas vuelven a sus sitios.',
                  acciones: [
                    for (final a in opciones) ...[
                      BotonUmbral(
                        texto: a.etiqueta,
                        estilo: a.resaltada
                            ? EstiloBoton.acento
                            : EstiloBoton.secundario,
                        alPulsar: guardando
                            ? null
                            : () => _juego.cerrarMenuFogata(a),
                      ),
                      const SizedBox(height: Espacios.paso4),
                    ],
                    BotonUmbral(
                      texto: 'Levantarse',
                      alPulsar: _juego.cerrarMenuFogata,
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: _juego.mapaAbierto,
              builder: (_, vista, _) => vista == null
                  ? const SizedBox.shrink()
                  : _CapaMapa(vista, alCerrar: _juego.cerrarMapa),
            ),
            if (_final case final f?) _capaFinal(f),
            if (_menu)
              _Capa(
                titulo: 'Pausa',
                texto:
                    '${_juego.personaje.nombre} · Nivel ${_juego.nivel.value}',
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

/// [nombre] es la pantalla negra con el nombre del personaje, tras romper la
/// Brasa.
enum _Final { eleccion, encender, romper, nombre }

/// El mapa de la zona, abierto desde una fogata: las fogatas encendidas como
/// llamas de brasa y el jugador como un punto de hueso. Tocar o el botón lo
/// cierra.
class _CapaMapa extends StatelessWidget {
  final VistaMapa vista;
  final VoidCallback alCerrar;

  const _CapaMapa(this.vista, {required this.alCerrar});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: alCerrar,
        child: ColoredBox(
          color: Colores.abismo.withValues(alpha: 0.9),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Espacios.paso4),
              child: Column(
                children: [
                  Text(
                    vista.nombre,
                    textAlign: TextAlign.center,
                    style: Textos.tituloZona(),
                  ),
                  const SizedBox(height: Espacios.paso2),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: vista.ancho / vista.alto,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colores.borde),
                            color: Colores.abismo,
                          ),
                          child: LayoutBuilder(
                            builder: (_, caja) => Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.asset(
                                    vista.ruta,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.none,
                                  ),
                                ),
                                for (final f in vista.fogatas)
                                  _marca(caja, f, 10, Colores.brasa),
                                _marca(caja, vista.jugador, 6, Colores.hueso),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Espacios.paso2),
                  Text(
                    vista.fogatas.isEmpty
                        ? 'Aún no has encendido fogatas en esta zona.'
                        : 'Fogatas encendidas: ${vista.fogatas.length}',
                    textAlign: TextAlign.center,
                    style: Textos.cuerpo(color: Colores.ceniza),
                  ),
                  const SizedBox(height: Espacios.paso4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: BotonUmbral(
                      texto: 'Cerrar',
                      estilo: EstiloBoton.secundario,
                      alPulsar: alCerrar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Un cuadrado de [lado] px centrado en la celda [c].
  Widget _marca(BoxConstraints caja, (int, int) c, double lado, Color color) =>
      Positioned(
        left: (c.$1 + 0.5) / vista.ancho * caja.maxWidth - lado / 2,
        top: (c.$2 + 0.5) / vista.alto * caja.maxHeight - lado / 2,
        child: SizedBox.square(
          dimension: lado,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colores.abismo),
            ),
          ),
        ),
      );
}

/// Lo que dice Oreste: un panel abajo con su retrato, su nombre y una línea
/// cada vez, letra a letra. Tocar completa la línea o pasa a la siguiente;
/// tras la última se cierra y el diálogo queda leído.
class _CapaDialogo extends StatefulWidget {
  final UmbralJuego juego;
  final ({String nombre, String retrato, List<String> lineas, String? id})
  dialogo;

  const _CapaDialogo(this.juego, this.dialogo);

  @override
  State<_CapaDialogo> createState() => _CapaDialogoState();
}

class _CapaDialogoState extends State<_CapaDialogo> {
  /// Unos 30 caracteres por segundo.
  static const _paso = Duration(milliseconds: 33);

  int _linea = 0;
  int _letras = 0;
  Timer? _reloj;

  String get _texto => widget.dialogo.lineas[_linea];
  bool get _completa => _letras >= _texto.length;

  @override
  void initState() {
    super.initState();
    widget.juego.alAvanzarDialogo = _avanzar;
    _escribir();
  }

  @override
  void didUpdateWidget(_CapaDialogo anterior) {
    super.didUpdateWidget(anterior);
    if (!identical(anterior.dialogo, widget.dialogo)) {
      _linea = 0;
      _escribir();
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    if (widget.juego.alAvanzarDialogo == _avanzar) {
      widget.juego.alAvanzarDialogo = null;
    }
    super.dispose();
  }

  void _escribir() {
    _reloj?.cancel();
    _letras = 0;
    _reloj = Timer.periodic(_paso, (reloj) {
      if (!mounted) return reloj.cancel();
      setState(() => _letras++);
      if (_completa) reloj.cancel();
    });
  }

  void _avanzar() {
    if (!_completa) {
      _reloj?.cancel();
      setState(() => _letras = _texto.length);
    } else if (_linea + 1 < widget.dialogo.lineas.length) {
      setState(() => _linea++);
      _escribir();
    } else {
      widget.juego.cerrarDialogo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dialogo;
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _avanzar,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(Espacios.paso4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: PanelUmbral(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // El retrato de 32 px, a ×3.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colores.borde),
                        ),
                        child: Image.asset(
                          d.retrato,
                          width: 96,
                          height: 96,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                      const SizedBox(width: Espacios.paso4),
                      Expanded(
                        child: SizedBox(
                          height: 96,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.nombre,
                                style: Textos.etiqueta(color: Colores.brasa),
                              ),
                              const SizedBox(height: Espacios.paso2),
                              Expanded(
                                child: Text(
                                  _texto.substring(
                                    0,
                                    min(_letras, _texto.length),
                                  ),
                                  style: Textos.cuerpo(),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _completa ? '▼' : '',
                                  style: Textos.etiqueta(color: Colores.ceniza),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tras romper la Brasa: en negro, el nombre del personaje letra a letra.
class _CapaNombre extends StatefulWidget {
  final String nombre;
  final VoidCallback alVolver;

  const _CapaNombre({required this.nombre, required this.alVolver});

  @override
  State<_CapaNombre> createState() => _CapaNombreState();
}

class _CapaNombreState extends State<_CapaNombre> {
  int _letras = 0;
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(milliseconds: 220), (reloj) {
      if (!mounted) return reloj.cancel();
      setState(() => _letras++);
      if (_letras >= widget.nombre.length) reloj.cancel();
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completo = _letras >= widget.nombre.length;
    return Positioned.fill(
      child: ColoredBox(
        color: Colores.abismo,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Espacios.paso4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.nombre.substring(
                    0,
                    min(_letras, widget.nombre.length),
                  ),
                  textAlign: TextAlign.center,
                  style: Textos.tituloJuego(),
                ),
                const SizedBox(height: Espacios.paso6),
                AnimatedOpacity(
                  opacity: completo ? 1 : 0,
                  duration: const Duration(milliseconds: 800),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: BotonUmbral(
                      texto: 'Volver a las partidas',
                      estilo: EstiloBoton.secundario,
                      alPulsar: completo ? widget.alVolver : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Texto del HUD: va sobre el juego, sin panel, con sombra dura.
TextStyle _textoHud(TextStyle estilo) => estilo.copyWith(
  shadows: const [Shadow(color: Colores.abismo, offset: Offset(1, 1))],
);

/// Miles con punto: 1.240.
String _miles(int n) => n.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => '.',
);

/// Arriba a la izquierda, sin panel: vida, estamina y, debajo, EXP y oro. El
/// nombre y el nivel están en la pausa.
class _Estado extends StatelessWidget {
  final UmbralJuego juego;

  const _Estado(this.juego);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // La cuenta admin no pierde vida ni estamina: no hay nada que ver.
          if (!juego.admin) ...[
            _BarraVida(juego),
            SizedBox(height: PiezaHud.px(1)),
            _BarraEstamina(juego),
            SizedBox(height: PiezaHud.px(2)),
          ],
          ListenableBuilder(
            listenable: Listenable.merge([juego.exp, juego.oro]),
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Contador(
                  icono: PiezaHud.iconoExp,
                  valor: juego.exp.value,
                  color: Colores.hueso,
                  descripcion: 'Experiencia',
                ),
                SizedBox(width: PiezaHud.px(4)),
                _Contador(
                  icono: PiezaHud.iconoOro,
                  valor: juego.oro.value,
                  color: Colores.brasa,
                  descripcion: 'Oro',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  final PiezaHud icono;
  final int valor;
  final Color color;
  final String descripcion;

  const _Contador({
    required this.icono,
    required this.valor,
    required this.color,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$descripcion $valor',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CuadroHud(icono),
          SizedBox(width: PiezaHud.px(1)),
          Text(_miles(valor), style: _textoHud(Textos.etiqueta(color: color))),
        ],
      ),
    );
  }
}

/// Vida sin números. Al recibir daño, el tramo perdido queda visible detrás
/// del relleno y se encoge hasta la vida real en medio segundo.
class _BarraVida extends StatefulWidget {
  final UmbralJuego juego;

  const _BarraVida(this.juego);

  @override
  State<_BarraVida> createState() => _BarraVidaState();
}

class _BarraVidaState extends State<_BarraVida>
    with SingleTickerProviderStateMixin {
  late final _encoger = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// Fracción de vida desde la que se encoge el tramo perdido.
  double _desde = 1;
  late double _anterior = _valor;

  double get _valor =>
      (widget.juego.vida.value / widget.juego.vidaMaxima.value).clamp(0, 1);

  double get _perdida => _encoger.isAnimating
      ? _desde + (_valor - _desde) * Curves.easeIn.transform(_encoger.value)
      : _valor;

  @override
  void initState() {
    super.initState();
    widget.juego.vida.addListener(_cambio);
    widget.juego.vidaMaxima.addListener(_cambio);
  }

  @override
  void dispose() {
    widget.juego.vida.removeListener(_cambio);
    widget.juego.vidaMaxima.removeListener(_cambio);
    _encoger.dispose();
    super.dispose();
  }

  void _cambio() {
    final valor = _valor;
    if (valor < _anterior) {
      // Si ya se estaba encogiendo, sigue desde donde iba.
      _desde = max(_perdida, _anterior);
      _encoger.forward(from: 0);
    }
    _anterior = valor;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Vida ${widget.juego.vida.value} de ${widget.juego.vidaMaxima.value}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _encoger,
        builder: (_, _) => BarraHud(
          marco: PiezaHud.vidaMarco,
          relleno: PiezaHud.vidaRelleno,
          origen: const Offset(12, 3),
          valor: _valor,
          perdida: _perdida,
        ),
      ),
    );
  }
}

/// Se gasta al atacar y se recupera sola. Si no alcanza para un ataque, el
/// filo del marco se pone rojo.
class _BarraEstamina extends StatelessWidget {
  final UmbralJuego juego;

  const _BarraEstamina(this.juego);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([juego.estamina, juego.sinEstamina]),
      builder: (_, _) => BarraHud(
        marco: PiezaHud.estaminaMarco,
        cuadroMarco: juego.sinEstamina.value ? 1 : 0,
        relleno: PiezaHud.estaminaRelleno,
        origen: const Offset(10, 3),
        valor: juego.estamina.value / UmbralJuego.estaminaMaxima,
      ),
    );
  }
}

/// Palanca táctil: la dirección es la distancia del dedo al centro.
class _Palanca extends StatefulWidget {
  final UmbralJuego juego;

  const _Palanca(this.juego);

  @override
  State<_Palanca> createState() => _PalancaState();
}

class _PalancaState extends State<_Palanca> {
  static final _tamano = PiezaHud.px(PiezaHud.palancaBase.ancho);
  static final _recorrido = PiezaHud.px(PiezaHud.recorridoPalanca);
  Offset _perilla = Offset.zero;
  bool _arrastrando = false;

  void _mover(Offset local) {
    var d = local - Offset(_tamano / 2, _tamano / 2);
    if (d.distance > _recorrido) d = d / d.distance * _recorrido;
    setState(() {
      _perilla = d;
      _arrastrando = true;
    });
    widget.juego.direccionJoystick.setValues(
      d.dx / _recorrido,
      d.dy / _recorrido,
    );
  }

  void _soltar() {
    setState(() {
      _perilla = Offset.zero;
      _arrastrando = false;
    });
    widget.juego.direccionJoystick.setZero();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Palanca de movimiento',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (e) => _mover(e.localPosition),
        onPointerMove: (e) => _mover(e.localPosition),
        onPointerUp: (_) => _soltar(),
        onPointerCancel: (_) => _soltar(),
        child: SizedBox(
          width: _tamano,
          height: _tamano,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const CuadroHud(PiezaHud.palancaBase),
              Transform.translate(
                offset: _perilla,
                child: CuadroHud(
                  PiezaHud.palancaPerilla,
                  cuadro: _arrastrando ? 1 : 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Abajo a la derecha: atacar en la esquina, rodar a su izquierda con el
/// frasco encima, y las acciones del lugar sobre atacar, con su texto a la
/// izquierda.
class _Acciones extends StatelessWidget {
  final UmbralJuego juego;

  const _Acciones(this.juego);

  @override
  Widget build(BuildContext context) {
    final atacar = PiezaHud.atacar(juego.personaje.claseCodigo);
    final accion = PiezaHud.accion('entrar');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([juego.acciones, juego.guardando]),
          builder: (_, _) => Padding(
            // Centra los emblemas sobre el botón de atacar.
            padding: EdgeInsets.only(
              right: PiezaHud.px(atacar.areaTactil! - accion.areaTactil!) / 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final a in juego.acciones.value)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.etiqueta.toUpperCase(),
                        style: _textoHud(
                          Textos.etiqueta(
                            color: juego.guardando.value
                                ? Colores.ceniza
                                : a.resaltada
                                ? Colores.brasa
                                : Colores.hueso,
                          ),
                        ),
                      ),
                      // Se apilan a la altura del dibujo: en los altares hay
                      // dos y el área tocable completa no cabría.
                      SizedBox(
                        width: PiezaHud.px(accion.areaTactil!),
                        height: PiezaHud.px(accion.alto),
                        child: OverflowBox(
                          maxHeight: PiezaHud.px(accion.areaTactil!),
                          child: BotonHud(
                            pieza: PiezaHud.accion(a.boton),
                            descripcion: a.etiqueta,
                            alPulsar: juego.guardando.value
                                ? null
                                : a.alPulsar,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: juego.sinEstamina,
          builder: (_, sinEstamina, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder(
                    valueListenable: juego.frascos,
                    builder: (_, quedan, _) => BotonHud(
                      pieza: PiezaHud.frasco,
                      descripcion: 'Beber un frasco, quedan $quedan',
                      cuadro: quedan > 0 ? 0 : 2,
                      alPulsar: juego.pedirBeber,
                      encima: Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '$quedan',
                          style: _textoHud(
                            Textos.etiqueta(
                              color: quedan > 0 ? Colores.brasa : Colores.ceniza,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  BotonHud(
                    pieza: PiezaHud.rodar,
                    descripcion: 'Rodar',
                    cuadro: sinEstamina ? 2 : 0,
                    alPulsar: juego.pedirRodar,
                  ),
                ],
              ),
              BotonHud(
                pieza: atacar,
                descripcion: 'Atacar',
                cuadro: sinEstamina ? 2 : 0,
                alPulsar: () => juego.botonAtaque = true,
                alSoltar: () => juego.botonAtaque = false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Vida del jefe mientras dura el combate, con su nombre debajo, sin panel.
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
          return Semantics(
            liveRegion: true,
            label: jefe.tipo.nombre,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BarraHud(
                  marco: PiezaHud.jefeMarco,
                  relleno: PiezaHud.jefeRelleno,
                  cuadroRelleno: jefe.furioso ? 1 : 0,
                  origen: const Offset(12, 3),
                  valor: juego.vidaJefe.value,
                ),
                SizedBox(height: PiezaHud.px(1)),
                Text(
                  jefe.tipo.nombre.toUpperCase(),
                  style: _textoHud(Textos.contador()),
                ),
              ],
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
