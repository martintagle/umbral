import 'dart:math';
import 'dart:ui';

import '../../contrato/clase_codigo.dart';
import '../tema/tema_umbral.dart';

/// Cómo se siente el arma de cada clase. El daño no está aquí: lo calcula el
/// servidor y llega en `Combate`.
class EstiloCombate {
  final double velocidad;
  final double recarga;

  /// Estamina que gasta cada ataque (de un máximo de 100).
  final double costoEstamina;

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
    required this.costoEstamina,
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

const Map<ClaseCodigo, EstiloCombate> estilosCombate = {
  ClaseCodigo.vagabundo: EstiloCombate(
    velocidad: 62,
    recarga: 0.38,
    costoEstamina: 16,
    alcance: 17,
    arco: pi * 0.7,
  ),
  ClaseCodigo.guerrero: EstiloCombate(
    velocidad: 52,
    recarga: 0.8,
    costoEstamina: 30,
    alcance: 21,
    arco: pi * 0.95,
  ),
  ClaseCodigo.arquero: EstiloCombate(
    velocidad: 60,
    recarga: 0.5,
    costoEstamina: 14,
    distanciaProyectil: 170,
    velocidadProyectil: 230,
    colorProyectil: Colores.hueso,
  ),
  ClaseCodigo.mago: EstiloCombate(
    velocidad: 56,
    recarga: 0.75,
    costoEstamina: 24,
    distanciaProyectil: 140,
    velocidadProyectil: 130,
    tamanoProyectil: 4,
    colorProyectil: Colores.alma,
  ),
  ClaseCodigo.prisionero: EstiloCombate(
    velocidad: 68,
    recarga: 0.22,
    costoEstamina: 10,
    alcance: 12,
    arco: pi * 0.5,
  ),
};

EstiloCombate estiloDe(ClaseCodigo clase) => estilosCombate[clase]!;
