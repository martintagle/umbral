/// Subdocumento `usuarios.ajustes` tal como viaja en el JSON de la API.
class Ajustes {
  final String idioma;
  final double musica;
  final double efectos;

  const Ajustes({
    required this.idioma,
    required this.musica,
    required this.efectos,
  });

  factory Ajustes.fromMap(Map<String, dynamic> map) {
    return Ajustes(
      idioma: map['idioma'] as String,
      musica: (map['musica'] as num).toDouble(),
      efectos: (map['efectos'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'idioma': idioma,
      'musica': musica.toDouble(),
      'efectos': efectos.toDouble(),
    };
  }
}
