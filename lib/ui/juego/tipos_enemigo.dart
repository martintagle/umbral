import 'dart:ui';

import '../tema/tema_umbral.dart';

enum Ataque { cuerpoACuerpo, distancia }

/// Estadísticas y comportamiento de cada criatura. Las distancias están en
/// píxeles de arte y los tiempos en segundos. Lo que da al ser derrotada lo
/// decide el servidor (`EnemigoServicio`), por [id].
class TipoEnemigo {
  final String id;
  final String nombre;
  final int vida;
  final int dano;
  final double velocidad;
  final double deteccion;
  final double alcance;

  /// Tiempo de aviso antes de golpear: el jugador lo ve parpadear y puede
  /// apartarse.
  final double preparacion;
  final double recarga;
  final Ataque ataque;
  final bool vuela;

  /// Velocidad del salto al atacar; 0 si golpea sin moverse.
  final double embestida;

  /// Segundos que el golpe deja lento al jugador.
  final double ralentiza;

  /// Vida que recupera por segundo si lleva un rato sin recibir daño.
  final double regeneracion;

  /// Cuánto zigzaguea al moverse (0 = en línea recta).
  final double erratico;
  final Color colorProyectil;

  const TipoEnemigo({
    required this.id,
    required this.nombre,
    required this.vida,
    required this.dano,
    required this.velocidad,
    required this.deteccion,
    required this.alcance,
    required this.preparacion,
    required this.recarga,
    this.ataque = Ataque.cuerpoACuerpo,
    this.vuela = false,
    this.embestida = 0,
    this.ralentiza = 0,
    this.regeneracion = 0,
    this.erratico = 0,
    this.colorProyectil = Colores.ceniza,
  });

  String get sprite => 'sprites/enemigos/$id.png';
}

abstract final class Enemigos {
  /// Débil y esquivo: se mueve en zigzag.
  static const ojoErrante = TipoEnemigo(
    id: 'ojo-errante',
    nombre: 'Ojo errante',
    vida: 22,
    dano: 7,
    velocidad: 52,
    deteccion: 105,
    alcance: 14,
    preparacion: 0.35,
    recarga: 1.1,
    vuela: true,
    erratico: 1,
  );

  /// Mordida fuerte: se agazapa y salta sobre el jugador.
  static const fauce = TipoEnemigo(
    id: 'fauce',
    nombre: 'Fauce',
    vida: 48,
    dano: 17,
    velocidad: 36,
    deteccion: 100,
    alcance: 34,
    preparacion: 0.6,
    recarga: 1.6,
    embestida: 170,
  );

  /// Vuela y escupe polvo a distancia; huye si te acercas.
  static const polillaOsaria = TipoEnemigo(
    id: 'polilla-osaria',
    nombre: 'Polilla osaria',
    vida: 26,
    dano: 9,
    velocidad: 44,
    deteccion: 130,
    alcance: 85,
    preparacion: 0.5,
    recarga: 2.0,
    ataque: Ataque.distancia,
    vuela: true,
    colorProyectil: Colores.ceniza,
  );

  /// Lenta y resistente; lanza fuego de sus velas.
  static const larvaCirio = TipoEnemigo(
    id: 'larva-cirio',
    nombre: 'Larva cirio',
    vida: 95,
    dano: 14,
    velocidad: 16,
    deteccion: 95,
    alcance: 95,
    preparacion: 0.9,
    recarga: 2.4,
    ataque: Ataque.distancia,
    colorProyectil: Colores.brasa,
  );

  /// Muchos golpes débiles que te agarran y te frenan.
  static const manojo = TipoEnemigo(
    id: 'manojo',
    nombre: 'Manojo',
    vida: 60,
    dano: 6,
    velocidad: 30,
    deteccion: 90,
    alcance: 16,
    preparacion: 0.25,
    recarga: 0.6,
    ralentiza: 1.0,
  );

  /// Se cura si no lo matas rápido.
  static const ahorcadoFungico = TipoEnemigo(
    id: 'ahorcado-fungico',
    nombre: 'Ahorcado fúngico',
    vida: 52,
    dano: 10,
    velocidad: 28,
    deteccion: 95,
    alcance: 16,
    preparacion: 0.45,
    recarga: 1.3,
    regeneracion: 5,
  );

  static const todos = [
    ojoErrante,
    fauce,
    polillaOsaria,
    larvaCirio,
    manojo,
    ahorcadoFungico,
  ];
}
