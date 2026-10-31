import 'package:flutter/material.dart';

import '../../contrato/partida.dart';
import '../../api/clase_api.dart';
import '../../api/enemigo_api.dart';
import '../../contrato/partida_jugable.dart';
import '../../contrato/recompensa.dart';
import '../../api/partida_api.dart';
import '../../api/api_excepcion.dart';
import '../../api/sesion.dart';
import '../../api/sincronizacion.dart';
import '../../api/usuario_api.dart';
import '../clases_ui.dart';
import '../sonido.dart';
import '../tema/tema_umbral.dart';
import '../widgets/aviso_actualizacion.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/panel_umbral.dart';
import '../widgets/sprite_umbral.dart';
import 'ajustes_pantalla.dart';
import 'juego_pantalla.dart';
import 'login_pantalla.dart';
import 'nuevo_personaje_pantalla.dart';
import 'titulo_pantalla.dart';

class PartidasPantalla extends StatefulWidget {
  const PartidasPantalla({super.key});

  @override
  State<PartidasPantalla> createState() => _PartidasPantallaState();
}

class _PartidasPantallaState extends State<PartidasPantalla> {
  final _api = PartidaApi();
  List<PartidaJugable>? _partidas;
  String? _error;
  final _enemigos = EnemigoApi();
  bool _usuarioAlDia = false;

  /// Las clases de `api/` mantienen la sesión al día al cambiar la partida activa.
  String? get _partidaActiva => Sesion.usuario?.partidaActiva;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Cada carga lleva un número: si llega tarde la respuesta de una anterior,
  /// no pisa a la más reciente.
  int _carga = 0;

  Future<void> _cargar() async {
    final carga = ++_carga;
    setState(() => _error = null);
    // Mientras llega la del servidor, la lista guardada en el teléfono: tiene
    // lo último que devolvió el servidor (niveles, oro, equipo).
    final guardadas = await _api.partidasGuardadas();
    if (guardadas != null && carga == _carga && mounted) {
      setState(() => _partidas = _ordenadas(guardadas));
    }
    try {
      // Las tres peticiones van a la vez: con la API recién despertada, en
      // serie sumaban varias esperas.
      final resultados = await Future.wait([
        _refrescarUsuario(),
        // Las tarjetas muestran el nombre de la clase de cada personaje. Suele
        // estar ya en caché: se pide al abrir la app.
        ClaseApi().catalogo(),
        _api.listarPartidas(),
      ]);
      final partidas = resultados[2] as List<PartidaJugable>;
      if (carga == _carga && mounted) {
        setState(() => _partidas = _ordenadas(partidas));
      }
    } on ApiExcepcion catch (e) {
      if (carga == _carga) _mostrarError(e);
    }
  }

  /// Con la sesión recordada se refresca el usuario (y se comprueba que el
  /// token sigue valiendo). Sin conexión se sigue con el del teléfono.
  Future<void> _refrescarUsuario() async {
    if (_usuarioAlDia) return;
    try {
      await UsuarioApi().obtenerYo();
      _usuarioAlDia = true;
    } on ApiExcepcion catch (e) {
      if (!e.sinConexion) rethrow;
    }
  }

  static List<PartidaJugable> _ordenadas(List<PartidaJugable> partidas) =>
      partidas..sort(
        (a, b) =>
            b.partida.ultimaVezJugada.compareTo(a.partida.ultimaVezJugada),
      );

  void _mostrarError(ApiExcepcion e) {
    if (!mounted) return;
    if (e.sesionCaducada) {
      UsuarioApi().cerrarSesion();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPantalla()),
      );
      return;
    }
    setState(() => _error = e.mensaje);
  }

  Future<void> _jugar(PartidaJugable partida) async {
    final Map<String, Recompensa> recompensas;
    try {
      recompensas = await _enemigos.recompensas();
    } on ApiExcepcion catch (e) {
      _mostrarError(e);
      return;
    }
    try {
      await _api.seleccionarPartidaActiva(partida.partida.partidaId);
    } on ApiExcepcion {
      // No impide jugar: solo marca la partida en la lista.
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JuegoPantalla(partida: partida, recompensas: recompensas),
      ),
    );
    Sonido.pista(Audios.musicaTitulo);
    _cargar();
  }

  Future<void> _nueva() async {
    final creada = await Navigator.of(context).push<PartidaJugable>(
      MaterialPageRoute(builder: (_) => const NuevoPersonajePantalla()),
    );
    if (creada != null) {
      await _jugar(creada);
    } else {
      _cargar();
    }
  }

  Future<void> _borrar(PartidaJugable jugable) async {
    final partida = jugable.partida;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '¿Borrar a ${partida.personaje.nombre}?',
          style: Textos.encabezado(),
        ),
        content: Text(
          'La partida se pierde para siempre.',
          style: Textos.cuerpo(color: Colores.ceniza),
        ),
        actionsPadding: const EdgeInsets.all(Espacios.paso4),
        actions: [
          Row(
            children: [
              Expanded(
                child: BotonUmbral(
                  texto: 'Cancelar',
                  estilo: EstiloBoton.secundario,
                  alPulsar: () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: Espacios.paso4),
              Expanded(
                child: BotonUmbral(
                  texto: 'Borrar',
                  alPulsar: () => Navigator.pop(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await _api.eliminarPartida(partida.partidaId);
      _cargar();
    } on ApiExcepcion catch (e) {
      _mostrarError(e);
    }
  }

  void _cerrarSesion() {
    UsuarioApi().cerrarSesion();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TituloPantalla()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final partidas = _partidas;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Espacios.paso4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Una sola fila de cabecera: en horizontal el alto es escaso.
              Row(
                children: [
                  Text('Partidas', style: Textos.encabezado()),
                  const SizedBox(width: Espacios.paso4),
                  Expanded(
                    child: Text(
                      'Hola, ${Sesion.usuario?.username ?? ''}.',
                      overflow: TextOverflow.ellipsis,
                      style: Textos.cuerpo(color: Colores.ceniza),
                    ),
                  ),
                  BotonUmbral(
                    texto: 'Nueva partida',
                    expandido: false,
                    alPulsar: _nueva,
                  ),
                  const SizedBox(width: Espacios.paso4),
                  BotonIcono(
                    icono: 'ajustes',
                    descripcion: 'Ajustes',
                    alPulsar: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AjustesPantalla(),
                      ),
                    ),
                  ),
                  const SizedBox(width: Espacios.paso2),
                  TextButton(
                    onPressed: _cerrarSesion,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      'Cerrar sesión',
                      style: Textos.etiqueta(color: Colores.ceniza),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espacios.paso4),
              const _EstadoConexion(),
              const Center(child: AvisoActualizacion()),
              if (_error != null) ...[
                Row(
                  children: [
                    Expanded(child: AvisoError(_error!)),
                    const SizedBox(width: Espacios.paso4),
                    BotonUmbral(
                      texto: 'Reintentar',
                      estilo: EstiloBoton.secundario,
                      expandido: false,
                      alPulsar: _cargar,
                    ),
                  ],
                ),
                const SizedBox(height: Espacios.paso4),
              ],
              Expanded(
                child: switch (partidas) {
                  null when _error == null => const Center(
                    child: CircularProgressIndicator(color: Colores.brasa),
                  ),
                  null => const SizedBox.shrink(),
                  [] => Center(
                    child: Text(
                      'Aún no tienes partidas.\nCrea un personaje para cruzar el umbral.',
                      textAlign: TextAlign.center,
                      style: Textos.cuerpo(color: Colores.ceniza),
                    ),
                  ),
                  // Tarjetas en columnas que llenan el ancho.
                  _ => GridView.builder(
                    padding: const EdgeInsets.only(
                      right: Espacios.paso1,
                      bottom: Espacios.paso1,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 460,
                          mainAxisExtent: 156,
                          crossAxisSpacing: Espacios.paso4,
                          mainAxisSpacing: Espacios.paso4,
                        ),
                    itemCount: partidas.length,
                    itemBuilder: (_, i) => _TarjetaPartida(
                      partida: partidas[i].partida,
                      activa: partidas[i].partida.partidaId == _partidaActiva,
                      alJugar: () => _jugar(partidas[i]),
                      alBorrar: () => _borrar(partidas[i]),
                    ),
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sin conexión se juega con lo guardado en el teléfono; el progreso se envía
/// solo al volver. Con todo enviado no ocupa nada.
class _EstadoConexion extends StatelessWidget {
  const _EstadoConexion();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        Sincronizacion.enLinea,
        Sincronizacion.pendientes,
      ]),
      builder: (_, _) {
        final enLinea = Sincronizacion.enLinea.value;
        final pendientes = Sincronizacion.pendientes.value;
        if (enLinea && pendientes == 0) return const SizedBox.shrink();
        final partidas = pendientes == 1 ? '1 partida' : '$pendientes partidas';
        return Padding(
          padding: const EdgeInsets.only(bottom: Espacios.paso4),
          child: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(
                  enLinea ? Icons.cloud_upload_outlined : Icons.cloud_off,
                  color: Colores.ceniza,
                  size: 20,
                ),
                const SizedBox(width: Espacios.paso2),
                Expanded(
                  child: Text(
                    enLinea
                        ? 'Enviando el progreso de $partidas jugado sin conexión.'
                        : 'Sin conexión: juegas con lo guardado en el teléfono. '
                              '${pendientes > 0 ? 'El progreso de $partidas' : 'Tu progreso'} '
                              'se enviará al volver la conexión.',
                    style: Textos.etiqueta(color: Colores.ceniza),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TarjetaPartida extends StatelessWidget {
  final Partida partida;
  final bool activa;
  final VoidCallback alJugar;
  final VoidCallback alBorrar;

  const _TarjetaPartida({
    required this.partida,
    required this.activa,
    required this.alJugar,
    required this.alBorrar,
  });

  String _fecha(DateTime fecha) {
    final f = fecha.toLocal();
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = partida.personaje;
    final clase = claseUi(p.claseCodigo);
    return PanelUmbral(
      colorBorde: activa ? Colores.brasa : Colores.borde,
      padding: const EdgeInsets.all(Espacios.paso2),
      child: Row(
        children: [
          SpriteUmbral(
            ruta: clase.sprite(p.apariencia),
            ancho: 32,
            alto: 40,
            escala: 2,
          ),
          const SizedBox(width: Espacios.paso4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: Textos.encabezado()),
                Text(
                  '${nombreClase(p.claseCodigo)} · Nivel ${p.nivel}',
                  style: Textos.cuerpo(),
                ),
                Text(
                  'ORO ${p.oro}',
                  style: Textos.etiqueta(color: Colores.brasa),
                ),
                Text(
                  'Jugada ${_fecha(partida.ultimaVezJugada)}',
                  style: Textos.etiqueta(color: Colores.ceniza),
                ),
                if (activa)
                  Text(
                    'ÚLTIMA PARTIDA',
                    style: Textos.etiqueta(color: Colores.brasa),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              BotonUmbral(texto: 'Jugar', alPulsar: alJugar, expandido: false),
              const SizedBox(height: Espacios.paso2),
              IconButton(
                onPressed: alBorrar,
                tooltip: 'Borrar partida',
                iconSize: 24,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.delete_outline, color: Colores.ceniza),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
