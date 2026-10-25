import '../../dto/ubicacion_dto.dart';
import '../../servicio/modelos/progreso.dart';
import '../../servicio/modelos/recompensa.dart';

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

  int _suma(int Function(Recompensa) valor) => enemigos.entries
      .fold(0, (total, e) => total + e.value * valor(recompensa(e.key)));

  Progreso aProgreso({required int vidaActual, required UbicacionDto ubicacion}) {
    return Progreso(
      enemigosDerrotados: Map.of(enemigos),
      muertes: muertes,
      segundosJugados: segundos.floor(),
      vidaActual: vidaActual,
      ubicacion: ubicacion,
    );
  }

  void descontar(Progreso enviado) {
    enviado.enemigosDerrotados.forEach((tipo, n) {
      final quedan = enemigos[tipo]! - n;
      if (quedan == 0) {
        enemigos.remove(tipo);
      } else {
        enemigos[tipo] = quedan;
      }
    });
    muertes -= enviado.muertes;
    segundos -= enviado.segundosJugados;
  }
}
