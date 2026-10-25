/// Réplica del subdocumento `usuarios.partidas[].personaje.ubicacion`.
class UbicacionDto {
  final String zonaId;
  final int x;
  final int y;
  final String? ultimoPuntoGuardado;

  const UbicacionDto({
    required this.zonaId,
    required this.x,
    required this.y,
    this.ultimoPuntoGuardado,
  });

  factory UbicacionDto.fromMap(Map<String, dynamic> map) {
    return UbicacionDto(
      zonaId: map['zonaId'] as String,
      x: map['x'] as int,
      y: map['y'] as int,
      ultimoPuntoGuardado: map['ultimoPuntoGuardado'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'zonaId': zonaId,
      'x': x,
      'y': y,
      'ultimoPuntoGuardado': ultimoPuntoGuardado,
    };
  }
}
