/// Réplica del subdocumento `usuarios.partidas[].personaje.estadisticas`.
class EstadisticasDto {
  final int enemigosDerrotados;
  final int muertes;
  final int tiempoJugadoSeg;

  const EstadisticasDto({
    required this.enemigosDerrotados,
    required this.muertes,
    required this.tiempoJugadoSeg,
  });

  factory EstadisticasDto.fromMap(Map<String, dynamic> map) {
    return EstadisticasDto(
      enemigosDerrotados: map['enemigosDerrotados'] as int,
      muertes: map['muertes'] as int,
      tiempoJugadoSeg: map['tiempoJugadoSeg'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enemigosDerrotados': enemigosDerrotados,
      'muertes': muertes,
      'tiempoJugadoSeg': tiempoJugadoSeg,
    };
  }
}
