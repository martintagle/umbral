import 'personaje.dart';

/// Cada elemento del array `usuarios.partidas` tal como lo envía
/// la API (fechas en ISO 8601).
class Partida {
  final String partidaId;
  final DateTime creadaEn;
  final DateTime ultimaVezJugada;
  final Personaje personaje;

  const Partida({
    required this.partidaId,
    required this.creadaEn,
    required this.ultimaVezJugada,
    required this.personaje,
  });

  factory Partida.fromMap(Map<String, dynamic> map) {
    return Partida(
      partidaId: map['partidaId'] as String,
      creadaEn: DateTime.parse(map['creadaEn'] as String),
      ultimaVezJugada: DateTime.parse(map['ultimaVezJugada'] as String),
      personaje: Personaje.fromMap(map['personaje'] as Map<String, dynamic>),
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
