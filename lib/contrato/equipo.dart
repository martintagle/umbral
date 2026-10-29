/// Subdocumento `usuarios.partidas[].personaje.equipo` tal como viaja en el JSON de la API.
class Equipo {
  final int nivelArma;
  final int nivelArmadura;

  const Equipo({required this.nivelArma, required this.nivelArmadura});

  factory Equipo.fromMap(Map<String, dynamic> map) {
    return Equipo(
      nivelArma: map['nivelArma'] as int,
      nivelArmadura: map['nivelArmadura'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {'nivelArma': nivelArma, 'nivelArmadura': nivelArmadura};
  }
}
