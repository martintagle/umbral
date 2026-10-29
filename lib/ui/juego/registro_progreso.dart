import '../../contrato/ubicacion.dart';
import '../../contrato/progreso.dart';
import '../../contrato/recompensa.dart';

/// Lo que ha pasado en la partida desde el último guardado. Al guardar se
/// envía como [Progreso] y, si el servidor lo acepta, se descuenta lo
/// enviado: lo ocurrido mientras la petición viajaba no se pierde.
class RegistroProgreso {
  RegistroProgreso(this._recompensas);

  final Map<String, Recompensa> _recompensas;

  /// Enemigos derrotados de cada tipo, por id.
  final Map<String, int> enemigos = {};
  int muertes = 0;
  double segundos = 0;

  void enemigoDerrotado(String tipo) =>
      enemigos.update(tipo, (n) => n + 1, ifAbsent: () => 1);

  /// Si el servidor no conoce el tipo, rechazará el guardado y lo avisará.
  Recompensa recompensa(String tipo) =>
      _recompensas[tipo] ?? Recompensa(id: tipo, exp: 0, oro: 0);

  /// Experiencia y oro que el servidor sumará al guardar; solo para el HUD.
  int get exp => _suma((r) => r.exp);
  int get oro => _suma((r) => r.oro);

  int _suma(int Function(Recompensa) valor) => enemigos.entries.fold(
    0,
    (total, e) => total + e.value * valor(recompensa(e.key)),
  );

  Progreso aProgreso({
    required int vidaActual,
    required Ubicacion ubicacion,
  }) {
    return Progreso(
      enemigosDerrotados: Map.of(enemigos),
      muertes: muertes,
      segundosJugados: segundos.floor(),
      vidaActual: vidaActual,
      ubicacion: ubicacion,
    );
  }

  /// Al caer: se quita lo ganado para dejarlo en el suelo.
  Map<String, int> soltarEnemigos() {
    final soltado = Map.of(enemigos);
    enemigos.clear();
    return soltado;
  }

  /// Al recoger lo que se soltó.
  void recuperar(Map<String, int> soltado) {
    soltado.forEach((tipo, n) => enemigos.update(tipo, (m) => m + n,
        ifAbsent: () => n));
  }

  void descontar(Progreso enviado) {
    enviado.enemigosDerrotados.forEach((tipo, n) {
      // Puede faltar si se cayó mientras se guardaba.
      final quedan = (enemigos[tipo] ?? 0) - n;
      if (quedan <= 0) {
        enemigos.remove(tipo);
      } else {
        enemigos[tipo] = quedan;
      }
    });
    muertes -= enviado.muertes;
    segundos -= enviado.segundosJugados;
  }
}
