/// Subdocumento `usuarios.partidas[].personaje.mundo` tal como viaja en el JSON de la API.
class Mundo {
  final List<String> zonasDesbloqueadas;
  final List<String> cofresAbiertos;
  final List<String> jefesDerrotados;

  /// `altar:<zona>:<n>` y `sala:<slug>`. Las partidas de antes no lo traen.
  final List<String> fogatasEncendidas;

  /// Criaturas caídas desde el último descanso por punto de aparición
  /// (`<zona o sala>#<n>`): no vuelven hasta descansar.
  final Map<String, int> enemigosCaidos;

  /// Diálogos de Oreste leídos (`oreste-<zona>-<n>`). Solo crece.
  final List<String> dialogosLeidos;

  /// Palancas accionadas y muros agrietados rotos (`<zonaId>/<id>`). Solo
  /// crece.
  final List<String> mecanismosActivados;

  const Mundo({
    required this.zonasDesbloqueadas,
    required this.cofresAbiertos,
    required this.jefesDerrotados,
    this.fogatasEncendidas = const [],
    this.enemigosCaidos = const {},
    this.dialogosLeidos = const [],
    this.mecanismosActivados = const [],
  });

  factory Mundo.fromMap(Map<String, dynamic> map) {
    return Mundo(
      zonasDesbloqueadas: List<String>.from(map['zonasDesbloqueadas'] as List),
      cofresAbiertos: List<String>.from(map['cofresAbiertos'] as List),
      jefesDerrotados: List<String>.from(map['jefesDerrotados'] as List),
      fogatasEncendidas: List<String>.from(
        map['fogatasEncendidas'] as List? ?? const [],
      ),
      enemigosCaidos: Map<String, int>.from(
        map['enemigosCaidos'] as Map? ?? const {},
      ),
      dialogosLeidos: List<String>.from(
        map['dialogosLeidos'] as List? ?? const [],
      ),
      mecanismosActivados: List<String>.from(
        map['mecanismosActivados'] as List? ?? const [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zonasDesbloqueadas': zonasDesbloqueadas,
      'cofresAbiertos': cofresAbiertos,
      'jefesDerrotados': jefesDerrotados,
      'fogatasEncendidas': fogatasEncendidas,
      'enemigosCaidos': enemigosCaidos,
      'dialogosLeidos': dialogosLeidos,
      'mecanismosActivados': mecanismosActivados,
    };
  }
}
