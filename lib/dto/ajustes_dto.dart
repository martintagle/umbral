/// Réplica del subdocumento `usuarios.ajustes`.
class AjustesDto {
  final String idioma;
  final double musica;
  final double efectos;

  const AjustesDto({
    required this.idioma,
    required this.musica,
    required this.efectos,
  });

  factory AjustesDto.fromMap(Map<String, dynamic> map) {
    return AjustesDto(
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
