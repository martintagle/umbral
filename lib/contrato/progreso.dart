import 'ubicacion.dart';

/// Lo ocurrido en la partida desde el último guardado. La app envía los hechos
/// y el servidor comprueba que cuadren y los suma. No replica ninguna
/// colección.
class Progreso {
  /// Enemigos derrotados de cada tipo: `{ id: cantidad }`.
  final Map<String, int> enemigosDerrotados;

  /// Experiencia y oro que dieron esos enemigos, tirados al azar dentro de su
  /// [Recompensa]. El servidor comprueba que el total quepa en sus rangos.
  final int exp;
  final int oro;
  final int muertes;
  final int segundosJugados;
  final int vidaActual;
  final Ubicacion ubicacion;

  const Progreso({
    required this.enemigosDerrotados,
    required this.exp,
    required this.oro,
    required this.muertes,
    required this.segundosJugados,
    required this.vidaActual,
    required this.ubicacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'enemigosDerrotados': enemigosDerrotados,
      'exp': exp,
      'oro': oro,
      'muertes': muertes,
      'segundosJugados': segundosJugados,
      'vidaActual': vidaActual,
      'ubicacion': ubicacion.toMap(),
    };
  }
}
