import '../../dto/ubicacion_dto.dart';

/// Lo ocurrido en la partida desde el último guardado. La app envía los hechos
/// y el servidor calcula la experiencia, el oro y la subida de nivel. No
/// replica ninguna colección.
class Progreso {
  /// Enemigos derrotados de cada tipo: `{ id: cantidad }`.
  final Map<String, int> enemigosDerrotados;
  final int muertes;
  final int segundosJugados;
  final int vidaActual;
  final UbicacionDto ubicacion;

  const Progreso({
    required this.enemigosDerrotados,
    required this.muertes,
    required this.segundosJugados,
    required this.vidaActual,
    required this.ubicacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'enemigosDerrotados': enemigosDerrotados,
      'muertes': muertes,
      'segundosJugados': segundosJugados,
      'vidaActual': vidaActual,
      'ubicacion': ubicacion.toMap(),
    };
  }
}
