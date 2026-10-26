/// Réplica del subdocumento `clases.atributosBase`.
class AtributosBaseDto {
  final int vida;
  final int fuerza;
  final int destreza;
  final int inteligencia;

  const AtributosBaseDto({
    required this.vida,
    required this.fuerza,
    required this.destreza,
    required this.inteligencia,
  });

  factory AtributosBaseDto.fromJson(Map<String, dynamic> json) {
    return AtributosBaseDto(
      vida: json['vida'] as int,
      fuerza: json['fuerza'] as int,
      destreza: json['destreza'] as int,
      inteligencia: json['inteligencia'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vida': vida,
      'fuerza': fuerza,
      'destreza': destreza,
      'inteligencia': inteligencia,
    };
  }
}
