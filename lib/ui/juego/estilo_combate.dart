import 'dart:math';
import 'dart:ui';

import '../tema/tema_umbral.dart';

/// Cómo se siente el arma de cada clase. El daño no está aquí: lo calcula el
/// servidor y llega en `CombateDto`.
class EstiloCombate {
  final double velocidad;
  final double recarga;

  /// Si es > 0, el arma golpea en un arco frente al personaje.
  final double alcance;
  final double arco;

  /// Si `distanciaProyectil` es > 0, el arma dispara.
  final double distanciaProyectil;
  final double velocidadProyectil;
  final double tamanoProyectil;
  final Color colorProyectil;

  const EstiloCombate({
    required this.velocidad,
    required this.recarga,
    this.alcance = 0,
    this.arco = 0,
    this.distanciaProyectil = 0,
    this.velocidadProyectil = 0,
    this.tamanoProyectil = 2,
    this.colorProyectil = Colores.hueso,
  });

  bool get dispara => distanciaProyectil > 0;

  /// Radio en el que el ataque se orienta solo hacia el enemigo más cercano.
  double get autoapuntado => dispara ? distanciaProyectil : alcance * 2.5;
}

const Map<String, EstiloCombate> estilosCombate = {
  'vagabundo': EstiloCombate(
      velocidad: 62, recarga: 0.38, alcance: 24, arco: pi * 0.7),
  'guerrero': EstiloCombate(
      velocidad: 52, recarga: 0.8, alcance: 30, arco: pi * 0.95),
  'arquero': EstiloCombate(
    velocidad: 60,
    recarga: 0.5,
    distanciaProyectil: 170,
    velocidadProyectil: 230,
    colorProyectil: Colores.hueso,
  ),
  'mago': EstiloCombate(
    velocidad: 56,
    recarga: 0.75,
    distanciaProyectil: 140,
    velocidadProyectil: 130,
    tamanoProyectil: 4,
    colorProyectil: Colores.alma,
  ),
  'prisionero': EstiloCombate(
      velocidad: 68, recarga: 0.22, alcance: 17, arco: pi * 0.5),
};

EstiloCombate estiloDe(String clase) =>
    estilosCombate[clase] ?? estilosCombate['vagabundo']!;
