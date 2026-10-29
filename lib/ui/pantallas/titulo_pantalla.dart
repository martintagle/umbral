import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/sesion.dart';
import '../../api/usuario_api.dart';
import '../sonido.dart';
import '../tema/tema_umbral.dart';
import '../widgets/boton_umbral.dart';
import '../widgets/sprite_umbral.dart';
import 'ajustes_pantalla.dart';
import 'login_pantalla.dart';
import 'partidas_pantalla.dart';

class TituloPantalla extends StatefulWidget {
  const TituloPantalla({super.key});

  @override
  State<TituloPantalla> createState() => _TituloPantallaState();
}

class _TituloPantallaState extends State<TituloPantalla> {
  late final Timer _parpadeo;
  bool _visible = true;

  /// Si el teléfono recuerda una sesión, se entra directo a las partidas.
  late final bool _recordada = UsuarioApi().restaurarSesion();

  @override
  void initState() {
    super.initState();
    Sonido.pista(Audios.musicaTitulo);
    _parpadeo = Timer.periodic(
      const Duration(milliseconds: 700),
      (_) => setState(() => _visible = !_visible),
    );
  }

  @override
  void dispose() {
    _parpadeo.cancel();
    super.dispose();
  }

  void _comenzar() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            _recordada ? const PartidasPantalla() : const LoginPantalla(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = Sesion.usuario?.username;
    return Scaffold(
      body: Stack(
        children: [
          Semantics(
            button: true,
            label: 'Umbral. Toca para comenzar',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _comenzar,
              child: SafeArea(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(Espacios.paso4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SpriteUmbral(
                            ruta: 'assets/logo/logo-u-32.png',
                            ancho: 32,
                            alto: 32,
                            escala: 6,
                          ),
                          const SizedBox(width: Espacios.paso6 * 2),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Umbral',
                                style: Textos.tituloJuego().copyWith(
                                  fontSize: 112,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: Espacios.paso2),
                              Text(
                                'Lo que cruza no vuelve igual.',
                                style: Textos.cuerpo(color: Colores.ceniza),
                              ),
                              const SizedBox(height: Espacios.paso6 * 2),
                              AnimatedOpacity(
                                opacity: _visible ? 1 : 0,
                                duration: Duration.zero,
                                child: Text(
                                  'TOCA PARA COMENZAR',
                                  style: Textos.etiqueta(color: Colores.brasa)
                                      .copyWith(fontSize: 16),
                                ),
                              ),
                              if (_recordada && nombre != null) ...[
                                const SizedBox(height: Espacios.paso2),
                                Text(
                                  'Sesión de $nombre',
                                  style: Textos.etiqueta(color: Colores.ceniza),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(Espacios.paso4),
                child: BotonIcono(
                  icono: 'ajustes',
                  descripcion: 'Ajustes',
                  alPulsar: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AjustesPantalla()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
