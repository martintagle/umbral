/// Subdocumento `usuarios.partidas[].personaje.mundo` tal como viaja en el JSON de la API.
class Mundo {
  final List<String> zonasDesbloqueadas;
  final List<String> cofresAbiertos;
  final List<String> jefesDerrotados;

  const Mundo({
    required this.zonasDesbloqueadas,
    required this.cofresAbiertos,
    required this.jefesDerrotados,
  });

  factory Mundo.fromMap(Map<String, dynamic> map) {
    return Mundo(
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
