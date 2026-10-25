/// Valores de combate de un personaje, calculados por el servidor con las
/// reglas del juego. No es una colección: llega junto a cada partida.
class CombateDto {
  final int vidaMaxima;

  /// Experiencia total que hace falta para pasar al siguiente nivel.
  final int expSiguiente;
  final int dano;
  final int defensa;
  final double probabilidadCritico;
  final double multiplicadorCritico;

  const CombateDto({
    required this.vidaMaxima,
    required this.expSiguiente,
    required this.dano,
    required this.defensa,
    required this.probabilidadCritico,
    required this.multiplicadorCritico,
  });

  factory CombateDto.fromMap(Map<String, dynamic> map) {
    return CombateDto(
      vidaMaxima: map['vidaMaxima'] as int,
      expSiguiente: map['expSiguiente'] as int,
      dano: map['dano'] as int,
      defensa: map['defensa'] as int,
      probabilidadCritico: (map['probabilidadCritico'] as num).toDouble(),
      multiplicadorCritico: (map['multiplicadorCritico'] as num).toDouble(),
    );
  }
}
