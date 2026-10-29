import 'dart:ui';

import '../tema/tema_umbral.dart';

enum Ataque { cuerpoACuerpo, distancia }

/// Estadísticas y comportamiento de cada criatura. Las distancias están en
/// píxeles de arte y los tiempos en segundos. Lo que da al ser derrotada lo
/// decide el servidor (`EnemigoApi`), por [id].
///
/// La dificultad es la de un souls: pocos golpes bastan para caer, así que
/// cada ataque se avisa (la criatura se agazapa y parpadea en [preparacion]) y
/// se puede esquivar rodando.
class TipoEnemigo {
  final String id;
  final String nombre;
  final int vida;
  final int dano;

  /// Ninguna criatura corre más que el personaje más lento (el guerrero, 52):
  /// siempre se puede huir.
  final double velocidad;

  /// Distancia a la que ve al jugador y empieza a perseguirlo.
  final double deteccion;

  /// Distancia desde la que ataca. Los proyectiles recorren algo más.
  final double alcance;

  /// Tiempo de aviso antes de golpear: el jugador lo ve parpadear y puede
  /// apartarse o rodar.
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
  final double velocidadProyectil;
  final double tamanoProyectil;

  /// Proyectiles por disparo, abiertos en abanico.
  final int proyectiles;

  /// Golpes seguidos que encadena, con un aviso más corto entre ellos.
  final int combo;

  /// Si es firme, los golpes del jugador no le interrumpen el ataque.
  final bool firme;

  /// Los jefes no vuelven a su sitio ni se curan al alejarse el jugador.
  final bool jefe;

  /// Radio del cuerpo para golpes y choques, en píxeles de arte.
  final double radio;

  /// Altura del centro del cuerpo sobre los pies.
  final double alturaCentro;

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
    this.velocidadProyectil = 110,
    this.tamanoProyectil = 2,
    this.proyectiles = 1,
    this.combo = 1,
    this.firme = false,
    this.jefe = false,
    this.radio = 6,
    double? alturaCentro,
  }) : alturaCentro = alturaCentro ?? (vuela ? 10 : 6);

  String get sprite => 'sprites/enemigos/$id.png';
}

abstract final class Enemigos {
  /// Débil y esquivo: se mueve en zigzag y muerde dos veces.
  static const ojoErrante = TipoEnemigo(
    id: 'ojo-errante',
    nombre: 'Ojo errante',
    vida: 34,
    dano: 15,
    velocidad: 46,
    deteccion: 95,
    alcance: 10,
    preparacion: 0.32,
    recarga: 0.9,
    vuela: true,
    erratico: 1,
    combo: 2,
  );

  /// Mordida brutal: se agazapa y salta sobre el jugador desde lejos.
  static const fauce = TipoEnemigo(
    id: 'fauce',
    nombre: 'Fauce',
    vida: 80,
    dano: 34,
    velocidad: 40,
    deteccion: 100,
    alcance: 34,
    preparacion: 0.55,
    recarga: 1.3,
    embestida: 210,
  );

  /// Vuela y escupe polvo de hueso en abanico; huye si te acercas.
  static const polillaOsaria = TipoEnemigo(
    id: 'polilla-osaria',
    nombre: 'Polilla osaria',
    vida: 40,
    dano: 18,
    velocidad: 42,
    deteccion: 110,
    alcance: 75,
    preparacion: 0.5,
    recarga: 1.7,
    ataque: Ataque.distancia,
    vuela: true,
    colorProyectil: Colores.ceniza,
    velocidadProyectil: 125,
    proyectiles: 3,
  );

  /// Lenta y resistente; lanza fuego de sus velas y no se inmuta al recibir
  /// golpes.
  static const larvaCirio = TipoEnemigo(
    id: 'larva-cirio',
    nombre: 'Larva cirio',
    vida: 150,
    dano: 30,
    velocidad: 18,
    deteccion: 95,
    alcance: 85,
    preparacion: 0.8,
    recarga: 2.0,
    ataque: Ataque.distancia,
    colorProyectil: Colores.brasa,
    velocidadProyectil: 95,
    tamanoProyectil: 3,
    firme: true,
  );

  /// Muchos golpes rápidos que te agarran y te frenan.
  static const manojo = TipoEnemigo(
    id: 'manojo',
    nombre: 'Manojo',
    vida: 90,
    dano: 12,
    velocidad: 32,
    deteccion: 85,
    alcance: 12,
    preparacion: 0.24,
    recarga: 0.7,
    ralentiza: 1.4,
    combo: 3,
  );

  /// Se cura si no lo matas rápido, y golpea dos veces con su farol.
  static const ahorcadoFungico = TipoEnemigo(
    id: 'ahorcado-fungico',
    nombre: 'Ahorcado fúngico',
    vida: 85,
    dano: 24,
    velocidad: 30,
    deteccion: 85,
    alcance: 13,
    preparacion: 0.42,
    recarga: 1.1,
    regeneracion: 9,
    combo: 2,
  );

  /// Jefe de la sala del trono de la cripta. Alterna barridos, saltos que
  /// aplastan y lluvias de ojos; a media vida se enfurece y es más rápido.
  static const reyHueco = TipoEnemigo(
    id: 'jefe-rey-hueco',
    nombre: 'El Rey Hueco',
    vida: 950,
    dano: 46,
    velocidad: 30,
    deteccion: 140,
    alcance: 30,
    preparacion: 0.75,
    recarga: 1.0,
    embestida: 180,
    colorProyectil: Colores.alma,
    velocidadProyectil: 115,
    tamanoProyectil: 4,
    firme: true,
    jefe: true,
    radio: 11,
    alturaCentro: 14,
  );

  /// Las criaturas que aparecen en el mundo y en las salas (el jefe va
  /// aparte).
  static const todos = [
    ojoErrante,
    fauce,
    polillaOsaria,
    larvaCirio,
    manojo,
    ahorcadoFungico,
  ];

  static TipoEnemigo? porId(String id) =>
      [...todos, reyHueco].where((t) => t.id == id).firstOrNull;
}
