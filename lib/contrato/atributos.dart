/// Subdocumento `usuarios.partidas[].personaje.atributos` tal como viaja en el JSON de la API.
class Atributos {
  final int vida;
  final int fuerza;
  final int destreza;
  final int inteligencia;

  const Atributos({
    required this.vida,
    required this.fuerza,
    required this.destreza,
    required this.inteligencia,
  });

  factory Atributos.fromMap(Map<String, dynamic> map) {
    return Atributos(
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
