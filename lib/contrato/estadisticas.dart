/// Subdocumento `usuarios.partidas[].personaje.estadisticas` tal como viaja en el JSON de la API.
class Estadisticas {
  final int enemigosDerrotados;
  final int muertes;
  final int tiempoJugadoSeg;

  const Estadisticas({
    required this.enemigosDerrotados,
    required this.muertes,
    required this.tiempoJugadoSeg,
  });

  factory Estadisticas.fromMap(Map<String, dynamic> map) {
    return Estadisticas(
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
