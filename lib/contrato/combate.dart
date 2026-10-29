/// Valores de combate de un personaje, calculados por el servidor con las
/// reglas del juego. No replica ninguna colección: llega junto a cada partida.
class Combate {
  final int vidaMaxima;

  /// Experiencia que cuesta el siguiente nivel.
  final int expSiguiente;

  /// Experiencia que cuesta cada uno de los próximos niveles, en orden. Cada
  /// punto de atributo es un nivel y cuesta más que el anterior.
  final List<int> costoNiveles;
  final int dano;
  final int defensa;
  final double probabilidadCritico;
  final double multiplicadorCritico;

  /// Lo que cuesta y da subir un nivel el arma o la armadura en la herrería;
  /// `null` si ya están al máximo.
  final Mejora? mejoraArma;
  final Mejora? mejoraArmadura;

  const Combate({
    required this.vidaMaxima,
    required this.expSiguiente,
    this.costoNiveles = const [],
    required this.dano,
    required this.defensa,
    required this.probabilidadCritico,
    required this.multiplicadorCritico,
    this.mejoraArma,
    this.mejoraArmadura,
  });

  factory Combate.fromMap(Map<String, dynamic> map) {
    return Combate(
      vidaMaxima: map['vidaMaxima'] as int,
      expSiguiente: map['expSiguiente'] as int,
      costoNiveles: List<int>.from(map['costoNiveles'] as List? ?? const []),
      dano: map['dano'] as int,
      defensa: map['defensa'] as int,
      probabilidadCritico: (map['probabilidadCritico'] as num).toDouble(),
      multiplicadorCritico: (map['multiplicadorCritico'] as num).toDouble(),
      mejoraArma: Mejora.fromMap(map['mejoraArma']),
      mejoraArmadura: Mejora.fromMap(map['mejoraArmadura']),
    );
  }
}

class Mejora {
  final int costo;

  /// Daño (arma) o defensa (armadura) con el nivel siguiente.
  final int valorSiguiente;

  const Mejora({required this.costo, required this.valorSiguiente});

  static Mejora? fromMap(Object? map) => map is Map<String, dynamic>
      ? Mejora(
          costo: map['costo'] as int,
          valorSiguiente: map['valorSiguiente'] as int,
        )
      : null;
}
