import 'ubicacion_dto.dart';

/// Lo ocurrido en la partida desde el último guardado. La app envía los hechos
/// y el servidor aplica las reglas (subida de nivel incluida). No es una
/// colección.
class ProgresoDto {
  final int expGanada;
  final int oroGanado;
  final int enemigosDerrotados;
  final int muertes;
  final int segundosJugados;
  final int vidaActual;
  final UbicacionDto ubicacion;

  const ProgresoDto({
    required this.expGanada,
    required this.oroGanado,
    required this.enemigosDerrotados,
    required this.muertes,
    required this.segundosJugados,
    required this.vidaActual,
    required this.ubicacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'expGanada': expGanada,
      'oroGanado': oroGanado,
      'enemigosDerrotados': enemigosDerrotados,
      'muertes': muertes,
      'segundosJugados': segundosJugados,
      'vidaActual': vidaActual,
      'ubicacion': ubicacion.toMap(),
    };
  }
}
