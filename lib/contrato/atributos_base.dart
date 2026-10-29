/// Subdocumento `clases.atributosBase` tal como viaja en el JSON de la API.
class AtributosBase {
  final int vida;
  final int fuerza;
  final int destreza;
  final int inteligencia;

  const AtributosBase({
    required this.vida,
    required this.fuerza,
    required this.destreza,
    required this.inteligencia,
  });

  factory AtributosBase.fromJson(Map<String, dynamic> json) {
    return AtributosBase(
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
