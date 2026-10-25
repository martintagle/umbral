import 'personaje_dto.dart';

/// Réplica de cada elemento del array `usuarios.partidas`, tal como lo envía
/// la API (fechas en ISO 8601).
class PartidaDto {
  final String partidaId;
  final DateTime creadaEn;
  final DateTime ultimaVezJugada;
  final PersonajeDto personaje;

  const PartidaDto({
    required this.partidaId,
    required this.creadaEn,
    required this.ultimaVezJugada,
    required this.personaje,
  });

  factory PartidaDto.fromMap(Map<String, dynamic> map) {
    return PartidaDto(
      partidaId: map['partidaId'] as String,
      creadaEn: DateTime.parse(map['creadaEn'] as String),
      ultimaVezJugada: DateTime.parse(map['ultimaVezJugada'] as String),
      personaje: PersonajeDto.fromMap(map['personaje'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partidaId': partidaId,
      'creadaEn': creadaEn.toUtc().toIso8601String(),
      'ultimaVezJugada': ultimaVezJugada.toUtc().toIso8601String(),
      'personaje': personaje.toMap(),
    };
  }
}
