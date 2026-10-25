import 'dart:async';

import 'package:flutter/material.dart';

import '../tema/tema_umbral.dart';
import '../widgets/sprite_umbral.dart';
import 'login_pantalla.dart';

class TituloPantalla extends StatefulWidget {
  const TituloPantalla({super.key});

  @override
  State<TituloPantalla> createState() => _TituloPantallaState();
}

class _TituloPantallaState extends State<TituloPantalla> {
  late final Timer _parpadeo;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _parpadeo = Timer.periodic(const Duration(milliseconds: 700),
        (_) => setState(() => _visible = !_visible));
  }

  @override
  void dispose() {
    _parpadeo.cancel();
    super.dispose();
  }

  void _comenzar() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPantalla()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Semantics(
        button: true,
        label: 'Umbral. Toca para comenzar',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _comenzar,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(Espacios.paso4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SpriteUmbral(
                      ruta: 'assets/sprites/estructuras/altar-de-brasas.png',
                      ancho: 32,
                      alto: 32,
                    ),
                    const SizedBox(height: Espacios.paso6),
                    Text('Umbral',
                        style: Textos.tituloJuego()
                            .copyWith(fontSize: 96, height: 1)),
                    const SizedBox(height: Espacios.paso2),
                    Text('Lo que cruza no vuelve igual.',
                        textAlign: TextAlign.center,
                        style: Textos.cuerpo(color: Colores.ceniza)),
                    const SizedBox(height: 64),
                    AnimatedOpacity(
                      opacity: _visible ? 1 : 0,
                      duration: Duration.zero,
                      child: Text('TOCA PARA COMENZAR',
                          style: Textos.etiqueta(color: Colores.brasa)
                              .copyWith(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
