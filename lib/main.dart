import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'servicio/clase_servicio.dart';
import 'servicio/preferencias_servicio.dart';
import 'ui/pantallas/titulo_pantalla.dart';
import 'ui/sonido.dart';
import 'ui/tema/tema_umbral.dart';
import 'ui/widgets/icono_umbral.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El juego y todas sus pantallas están pensados en horizontal.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await PreferenciasServicio.cargar();
  await Iconos.cargar();
  await Sonido.iniciar();
  // Las clases no cambian: se piden una vez, sin esperar, y quedan en caché.
  // Si falla (sin conexión), se reintenta al llegar a la lista de partidas.
  ClaseServicio().catalogo().ignore();
  runApp(const UmbralApp());
}

class UmbralApp extends StatelessWidget {
  const UmbralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Umbral',
      debugShowCheckedModeBanner: false,
      theme: temaUmbral(),
      home: const TituloPantalla(),
    );
  }
}
