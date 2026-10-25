import 'package:flutter/material.dart';

import 'ui/pantallas/titulo_pantalla.dart';
import 'ui/tema/tema_umbral.dart';

void main() {
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
