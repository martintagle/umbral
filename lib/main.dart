import 'package:flutter/material.dart';

import 'ui/pantallas/titulo_pantalla.dart';
import 'ui/tema/tema_umbral.dart';
import 'ui/widgets/icono_umbral.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Iconos.cargar();
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
