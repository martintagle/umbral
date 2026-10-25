import 'package:flutter/material.dart';

import '../../dto/partida_dto.dart';
import '../../dto/partida_jugable_dto.dart';
import '../../servicio/partida_servicio.dart';
import '../../servicio/servicio_excepcion.dart';
import '../../servicio/sesion_servicio.dart';
import '../../servicio/usuario_servicio.dart';
import '../clases_ui.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/panel_umbral.dart';
import '../widgets/sprite_umbral.dart';
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
  final _servicio = PartidaServicio();
  List<PartidaJugableDto>? _partidas;
  String? _error;
  String? _partidaActiva;

  @override
  void initState() {
    super.initState();
    _partidaActiva = SesionServicio.usuario?.partidaActiva;
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _error = null);
    try {
      final partidas = await _servicio.listarPartidas();
      partidas.sort((a, b) =>
          b.partida.ultimaVezJugada.compareTo(a.partida.ultimaVezJugada));
      if (mounted) setState(() => _partidas = partidas);
    } on ServicioExcepcion catch (e) {
      _mostrarError(e);
    }
  }

  void _mostrarError(ServicioExcepcion e) {
    if (!mounted) return;
    if (e.sesionCaducada) {
      UsuarioServicio().cerrarSesion();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPantalla()));
      return;
    }
    setState(() => _error = e.mensaje);
  }

  Future<void> _jugar(PartidaJugableDto partida) async {
    final id = partida.partida.partidaId;
    try {
      await _servicio.seleccionarPartidaActiva(id);
      _partidaActiva = id;
    } on ServicioExcepcion {
      // No impide jugar: solo marca la partida en la lista.
    }
    if (!mounted) return;
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => JuegoPantalla(partida: partida)));
    _cargar();
  }

  Future<void> _nueva() async {
    final creada = await Navigator.of(context).push<PartidaJugableDto>(
        MaterialPageRoute(builder: (_) => const NuevoPersonajePantalla()));
    if (creada != null) {
      await _jugar(creada);
    } else {
      _cargar();
    }
  }

  Future<void> _borrar(PartidaJugableDto jugable) async {
    final partida = jugable.partida;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar a ${partida.personaje.nombre}?',
            style: Textos.encabezado()),
        content: Text('La partida se pierde para siempre.',
            style: Textos.cuerpo(color: Colores.ceniza)),
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
      await _servicio.eliminarPartida(partida.partidaId);
      if (_partidaActiva == partida.partidaId) _partidaActiva = null;
      _cargar();
    } on ServicioExcepcion catch (e) {
      _mostrarError(e);
    }
  }

  void _cerrarSesion() {
    UsuarioServicio().cerrarSesion();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TituloPantalla()));
  }

  @override
  Widget build(BuildContext context) {
    final partidas = _partidas;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(Espacios.paso4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('Partidas', style: Textos.encabezado())),
                      TextButton(
                        onPressed: _cerrarSesion,
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48)),
                        child: Text('Cerrar sesión',
                            style: Textos.etiqueta(color: Colores.ceniza)),
                      ),
                    ],
                  ),
                  Text('Hola, ${SesionServicio.usuario?.username ?? ''}.',
                      style: Textos.cuerpo(color: Colores.ceniza)),
                  const SizedBox(height: Espacios.paso4),
                  if (_error != null) ...[
                    AvisoError(_error!),
                    const SizedBox(height: Espacios.paso2),
                    BotonUmbral(
                        texto: 'Reintentar',
                        estilo: EstiloBoton.secundario,
                        alPulsar: _cargar),
                    const SizedBox(height: Espacios.paso4),
                  ],
                  Expanded(
                    child: switch (partidas) {
                      null when _error == null => const Center(
                          child: CircularProgressIndicator(
                              color: Colores.brasa)),
                      null => const SizedBox.shrink(),
                      [] => Center(
                          child: Text(
                            'Aún no tienes partidas.\nCrea un personaje para cruzar el umbral.',
                            textAlign: TextAlign.center,
                            style: Textos.cuerpo(color: Colores.ceniza),
                          ),
                        ),
                      _ => ListView.separated(
                          itemCount: partidas.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: Espacios.paso4),
                          itemBuilder: (_, i) => _TarjetaPartida(
                            partida: partidas[i].partida,
                            activa: partidas[i].partida.partidaId == _partidaActiva,
                            alJugar: () => _jugar(partidas[i]),
                            alBorrar: () => _borrar(partidas[i]),
                          ),
                        ),
                    },
                  ),
                  const SizedBox(height: Espacios.paso4),
                  BotonUmbral(texto: 'Nueva partida', alPulsar: _nueva),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaPartida extends StatelessWidget {
  final PartidaDto partida;
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
    final clase = claseUi(p.clase);
    return PanelUmbral(
      colorBorde: activa ? Colores.brasa : Colores.borde,
      padding: const EdgeInsets.all(Espacios.paso2),
      child: Row(
        children: [
          SpriteUmbral(
              ruta: clase.sprite(p.apariencia), ancho: 32, alto: 40, escala: 2),
          const SizedBox(width: Espacios.paso4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: Textos.encabezado()),
                Text('${clase.nombre} · Nivel ${p.nivel}',
                    style: Textos.cuerpo()),
                Text('ORO ${p.oro}', style: Textos.etiqueta(color: Colores.brasa)),
                Text('Jugada ${_fecha(partida.ultimaVezJugada)}',
                    style: Textos.etiqueta(color: Colores.ceniza)),
                if (activa)
                  Text('ÚLTIMA PARTIDA',
                      style: Textos.etiqueta(color: Colores.brasa)),
              ],
            ),
          ),
          Column(
            children: [
              BotonUmbral(
                  texto: 'Jugar', alPulsar: alJugar, expandido: false),
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
