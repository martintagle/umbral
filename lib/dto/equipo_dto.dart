/// Réplica del subdocumento `usuarios.partidas[].personaje.equipo`.
class EquipoDto {
  final int nivelArma;
  final int nivelArmadura;

  const EquipoDto({
    required this.nivelArma,
    required this.nivelArmadura,
  });

  factory EquipoDto.fromMap(Map<String, dynamic> map) {
    return EquipoDto(
      nivelArma: map['nivelArma'] as int,
      nivelArmadura: map['nivelArmadura'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nivelArma': nivelArma,
      'nivelArmadura': nivelArmadura,
    };
  }
}
