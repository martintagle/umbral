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

  /// Fila de su hoja con el golpe o el disparo. Sus eventos `golpe1`,
  /// `golpe2`... (o `disparo`) marcan cada impacto del combo.
  final String animacionAtaque;

  /// Animación de `efectos.png` o `efectos-2.png` de sus proyectiles.
  final String? efectoProyectil;

  /// Lo que dice un custodio al caer y el ascua que deja.
  final String? ultimasPalabras;
  final String? ascua;

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
    required this.animacionAtaque,
    this.efectoProyectil,
    this.ultimasPalabras,
    this.ascua,
  }) : alturaCentro = alturaCentro ?? (vuela ? 10 : 6);

  /// Su hoja en `assets/sprites/animaciones/hojas.json`.
  String get hoja => 'enemigos/$id';
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
    animacionAtaque: 'morder',
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
    animacionAtaque: 'morder',
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
    animacionAtaque: 'escupir',
    efectoProyectil: 'polvo',
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
    animacionAtaque: 'fuego',
    efectoProyectil: 'fuego',
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
    animacionAtaque: 'agarrar',
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
    animacionAtaque: 'farol',
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
    animacionAtaque: 'barrido',
    efectoProyectil: 'ojo',
    ultimasPalabras: 'Tanto mirar… y nunca vi quién venía.',
    ascua: 'Ascua de Hueso',
  );

  // Zona 2, Ciénaga de Cera. Las criaturas de cada zona vuelven en la
  // siguiente como las más débiles (`docs/guion.md`).

  /// Rápido y errático: pica tres veces.
  static const enjambre = TipoEnemigo(
    id: 'enjambre',
    nombre: 'Enjambre',
    vida: 70,
    dano: 20,
    velocidad: 48,
    deteccion: 100,
    alcance: 10,
    preparacion: 0.26,
    recarga: 0.8,
    vuela: true,
    erratico: 1.2,
    combo: 3,
    animacionAtaque: 'picar',
  );

  /// Se agazapa y cae encima desde lejos.
  static const sapoLapida = TipoEnemigo(
    id: 'sapo-lapida',
    nombre: 'Sapo lápida',
    vida: 170,
    dano: 44,
    velocidad: 30,
    deteccion: 105,
    alcance: 40,
    preparacion: 0.6,
    recarga: 1.5,
    embestida: 200,
    firme: true,
    radio: 8,
    animacionAtaque: 'salto',
  );

  /// Lento y firme; el golpe pega cera y frena.
  static const ahogadoDeCera = TipoEnemigo(
    id: 'ahogado-de-cera',
    nombre: 'Ahogado de cera',
    vida: 240,
    dano: 40,
    velocidad: 22,
    deteccion: 90,
    alcance: 14,
    preparacion: 0.7,
    recarga: 1.4,
    ralentiza: 1.0,
    firme: true,
    radio: 8,
    animacionAtaque: 'golpe',
  );

  // Zona 3, Minas de Sal Negra.

  /// Dos picazos seguidos.
  static const mineroHueco = TipoEnemigo(
    id: 'minero-hueco',
    nombre: 'Minero hueco',
    vida: 230,
    dano: 36,
    velocidad: 34,
    deteccion: 95,
    alcance: 14,
    preparacion: 0.45,
    recarga: 1.1,
    combo: 2,
    animacionAtaque: 'picazo',
  );

  /// Sale del suelo y embiste en línea recta.
  static const gusanoDeSal = TipoEnemigo(
    id: 'gusano-de-sal',
    nombre: 'Gusano de sal',
    vida: 280,
    dano: 58,
    velocidad: 36,
    deteccion: 110,
    alcance: 46,
    preparacion: 0.6,
    recarga: 1.6,
    embestida: 230,
    radio: 8,
    animacionAtaque: 'embestir',
  );

  /// No se mueve: suelta un abanico de cinco esquirlas.
  static const cristalVivo = TipoEnemigo(
    id: 'cristal-vivo',
    nombre: 'Cristal vivo',
    vida: 320,
    dano: 34,
    velocidad: 0,
    deteccion: 120,
    alcance: 95,
    preparacion: 0.75,
    recarga: 2.0,
    ataque: Ataque.distancia,
    firme: true,
    proyectiles: 5,
    colorProyectil: Colores.hueso,
    velocidadProyectil: 130,
    animacionAtaque: 'esquirlas',
    efectoProyectil: 'esquirla',
  );

  // Zona 4, Abadía Hundida.

  /// Vuela alto y cae en picado.
  static const gargolaRota = TipoEnemigo(
    id: 'gargola-rota',
    nombre: 'Gárgola rota',
    vida: 320,
    dano: 58,
    velocidad: 44,
    deteccion: 120,
    alcance: 50,
    preparacion: 0.55,
    recarga: 1.5,
    vuela: true,
    embestida: 240,
    animacionAtaque: 'picado',
  );

  /// Reza desde lejos y se cura si no la alcanzas.
  static const monjaSinRostro = TipoEnemigo(
    id: 'monja-sin-rostro',
    nombre: 'Monja sin rostro',
    vida: 300,
    dano: 46,
    velocidad: 26,
    deteccion: 125,
    alcance: 100,
    preparacion: 0.7,
    recarga: 1.8,
    ataque: Ataque.distancia,
    proyectiles: 3,
    colorProyectil: Colores.alma,
    velocidadProyectil: 115,
    tamanoProyectil: 3,
    regeneracion: 12,
    animacionAtaque: 'rezo',
    efectoProyectil: 'polvo',
  );

  /// La onda de la campana te deja lento.
  static const campanero = TipoEnemigo(
    id: 'campanero',
    nombre: 'Campanero',
    vida: 460,
    dano: 62,
    velocidad: 24,
    deteccion: 95,
    alcance: 22,
    preparacion: 0.85,
    recarga: 1.8,
    ralentiza: 1.6,
    firme: true,
    radio: 9,
    animacionAtaque: 'campanada',
  );

  // Zona 5, Páramo de Ceniza.

  /// Flota y dispara brasas en abanico.
  static const estandartePoseido = TipoEnemigo(
    id: 'estandarte-poseido',
    nombre: 'Estandarte poseído',
    vida: 420,
    dano: 52,
    velocidad: 36,
    deteccion: 130,
    alcance: 105,
    preparacion: 0.6,
    recarga: 1.6,
    ataque: Ataque.distancia,
    vuela: true,
    proyectiles: 3,
    colorProyectil: Colores.brasa,
    velocidadProyectil: 135,
    animacionAtaque: 'brasas',
    efectoProyectil: 'brasa',
  );

  /// Embiste a toda velocidad desde muy lejos.
  static const caballoSinJinete = TipoEnemigo(
    id: 'caballo-sin-jinete',
    nombre: 'Caballo sin jinete',
    vida: 560,
    dano: 80,
    velocidad: 46,
    deteccion: 140,
    alcance: 60,
    preparacion: 0.5,
    recarga: 1.7,
    embestida: 270,
    firme: true,
    radio: 10,
    animacionAtaque: 'embestida',
  );

  /// La amenaza más dura del páramo: tres tajos.
  static const soldadoDeCeniza = TipoEnemigo(
    id: 'soldado-de-ceniza',
    nombre: 'Soldado de ceniza',
    vida: 600,
    dano: 54,
    velocidad: 38,
    deteccion: 110,
    alcance: 15,
    preparacion: 0.4,
    recarga: 1.2,
    combo: 3,
    firme: true,
    animacionAtaque: 'tajos',
  );

  // Zona 6, El Umbral.

  /// Fija en el suelo: muerde desde abajo si pisas cerca.
  static const bocaDelHueco = TipoEnemigo(
    id: 'boca-del-hueco',
    nombre: 'Boca del Hueco',
    vida: 700,
    dano: 96,
    velocidad: 0,
    deteccion: 60,
    alcance: 16,
    preparacion: 0.5,
    recarga: 1.6,
    firme: true,
    radio: 10,
    animacionAtaque: 'morder',
  );

  /// Un ojo sobre un tallo: rayo rápido y largo.
  static const vigia = TipoEnemigo(
    id: 'vigia',
    nombre: 'Vigía',
    vida: 620,
    dano: 72,
    velocidad: 0,
    deteccion: 150,
    alcance: 120,
    preparacion: 0.8,
    recarga: 1.9,
    ataque: Ataque.distancia,
    firme: true,
    colorProyectil: Colores.sangre,
    velocidadProyectil: 170,
    tamanoProyectil: 3,
    animacionAtaque: 'rayo',
    efectoProyectil: 'rayo',
  );

  /// Tu reflejo: rápida, esquiva y con daga.
  static const sombraSinNombre = TipoEnemigo(
    id: 'sombra-sin-nombre',
    nombre: 'Sombra sin nombre',
    vida: 760,
    dano: 70,
    velocidad: 50,
    deteccion: 130,
    alcance: 14,
    preparacion: 0.32,
    recarga: 0.9,
    erratico: 0.6,
    combo: 2,
    animacionAtaque: 'tajos',
  );

  // Custodios de las zonas 2 a 6. Pelean como el Rey Hueco: barrido, salto,
  // lluvia y, a media vida, furia.

  static const madreCirio = TipoEnemigo(
    id: 'jefe-madre-cirio',
    nombre: 'La Madre Cirio',
    vida: 1500,
    dano: 62,
    velocidad: 28,
    deteccion: 150,
    alcance: 32,
    preparacion: 0.75,
    recarga: 1.0,
    embestida: 170,
    colorProyectil: Colores.brasa,
    velocidadProyectil: 115,
    tamanoProyectil: 4,
    firme: true,
    jefe: true,
    radio: 12,
    alturaCentro: 16,
    animacionAtaque: 'barrido',
    efectoProyectil: 'fuego',
    ultimasPalabras: 'Se me apagaron todas… ¿cuál eras tú?',
    ascua: 'Ascua de Cera',
  );

  static const capatazDeSal = TipoEnemigo(
    id: 'jefe-capataz-de-sal',
    nombre: 'El Capataz de Sal',
    vida: 2300,
    dano: 82,
    velocidad: 30,
    deteccion: 150,
    alcance: 34,
    preparacion: 0.7,
    recarga: 1.0,
    embestida: 190,
    colorProyectil: Colores.hueso,
    velocidadProyectil: 125,
    tamanoProyectil: 4,
    firme: true,
    jefe: true,
    radio: 12,
    alturaCentro: 16,
    animacionAtaque: 'barrido',
    efectoProyectil: 'esquirla',
    ultimasPalabras: 'Turno terminado… por fin.',
    ascua: 'Ascua de Sal',
  );

  static const abadesa = TipoEnemigo(
    id: 'jefe-abadesa',
    nombre: 'La Abadesa de las Mil Manos',
    vida: 3300,
    dano: 104,
    velocidad: 30,
    deteccion: 160,
    alcance: 36,
    preparacion: 0.7,
    recarga: 0.95,
    embestida: 180,
    ralentiza: 1.2,
    colorProyectil: Colores.brasa,
    velocidadProyectil: 120,
    tamanoProyectil: 4,
    firme: true,
    jefe: true,
    radio: 12,
    alturaCentro: 16,
    animacionAtaque: 'barrido',
    efectoProyectil: 'fuego',
    ultimasPalabras: 'Recé con todas… y ninguna alcanzó.',
    ascua: 'Ascua de Plegaria',
  );

  static const caballeroDeCeniza = TipoEnemigo(
    id: 'jefe-caballero-de-ceniza',
    nombre: 'El Caballero de Ceniza',
    vida: 4600,
    dano: 130,
    velocidad: 36,
    deteccion: 170,
    alcance: 38,
    preparacion: 0.6,
    recarga: 0.9,
    embestida: 230,
    colorProyectil: Colores.brasa,
    velocidadProyectil: 140,
    tamanoProyectil: 4,
    firme: true,
    jefe: true,
    radio: 12,
    alturaCentro: 16,
    animacionAtaque: 'barrido',
    efectoProyectil: 'brasa',
    ultimasPalabras: 'Cumplí… ¿verdad?',
    ascua: 'Ascua de Juramento',
  );

  /// No es un custodio caído: es lo que esperaba del otro lado.
  static const elQueMira = TipoEnemigo(
    id: 'jefe-el-que-mira',
    nombre: 'El Que Mira',
    vida: 6500,
    dano: 160,
    velocidad: 32,
    deteccion: 200,
    alcance: 40,
    preparacion: 0.6,
    recarga: 0.85,
    embestida: 200,
    colorProyectil: Colores.alma,
    velocidadProyectil: 135,
    tamanoProyectil: 4,
    firme: true,
    jefe: true,
    radio: 13,
    alturaCentro: 18,
    animacionAtaque: 'barrido',
    efectoProyectil: 'ojo',
    ascua: 'Ascua Última',
  );

  /// Las criaturas que aparecen en el mundo y en las salas (los jefes van
  /// aparte).
  static const todos = [
    ojoErrante,
    fauce,
    polillaOsaria,
    larvaCirio,
    manojo,
    ahorcadoFungico,
    enjambre,
    sapoLapida,
    ahogadoDeCera,
    mineroHueco,
    gusanoDeSal,
    cristalVivo,
    gargolaRota,
    monjaSinRostro,
    campanero,
    estandartePoseido,
    caballoSinJinete,
    soldadoDeCeniza,
    bocaDelHueco,
    vigia,
    sombraSinNombre,
  ];

  static const jefes = [
    reyHueco,
    madreCirio,
    capatazDeSal,
    abadesa,
    caballeroDeCeniza,
    elQueMira,
  ];

  static TipoEnemigo? porId(String id) =>
      [...todos, ...jefes].where((t) => t.id == id).firstOrNull;
}
