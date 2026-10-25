/// Réplica del subdocumento `usuarios.partidas[].personaje.mundo`.
class MundoDto {
  final List<String> zonasDesbloqueadas;
  final List<String> cofresAbiertos;
  final List<String> jefesDerrotados;

  const MundoDto({
    required this.zonasDesbloqueadas,
    required this.cofresAbiertos,
    required this.jefesDerrotados,
  });

  factory MundoDto.fromMap(Map<String, dynamic> map) {
    return MundoDto(
      zonasDesbloqueadas: List<String>.from(map['zonasDesbloqueadas'] as List),
      cofresAbiertos: List<String>.from(map['cofresAbiertos'] as List),
      jefesDerrotados: List<String>.from(map['jefesDerrotados'] as List),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zonasDesbloqueadas': zonasDesbloqueadas,
      'cofresAbiertos': cofresAbiertos,
      'jefesDerrotados': jefesDerrotados,
    };
  }
}
