import 'api_cliente.dart';
import '../contrato/recompensa.dart';

/// Lo que da cada enemigo al ser derrotado.
class EnemigoApi {
  static Map<String, Recompensa>? _recompensas;

  /// Las recompensas no cambian mientras la app está abierta: se piden una vez.
  Future<Map<String, Recompensa>> recompensas() async {
    if (_recompensas case final guardadas?) return guardadas;
    final datos = await ApiCliente.get('/enemigos') as List;
    return _recompensas = {
      for (final r in datos.map(
        (r) => Recompensa.fromMap(r as Map<String, dynamic>),
      ))
        r.id: r,
    };
  }
}
