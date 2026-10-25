/// Réplica del subdocumento `usuarios.partidas[].personaje.atributos`.
class AtributosDto {
  final int vida;
  final int fuerza;
  final int destreza;
  final int inteligencia;

  const AtributosDto({
    required this.vida,
    required this.fuerza,
    required this.destreza,
    required this.inteligencia,
  });

  factory AtributosDto.fromMap(Map<String, dynamic> map) {
    return AtributosDto(
      vida: map['vida'] as int,
      fuerza: map['fuerza'] as int,
      destreza: map['destreza'] as int,
      inteligencia: map['inteligencia'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vida': vida,
      'fuerza': fuerza,
      'destreza': destreza,
      'inteligencia': inteligencia,
    };
  }
}
