import 'almacen_local.dart';
import 'api_cliente.dart';
import 'api_excepcion.dart';
import '../contrato/recompensa.dart';

/// Lo que da cada enemigo al ser derrotado.
class EnemigoApi {
  static Map<String, Recompensa>? _recompensas;
  static const _clave = 'enemigos';

  /// Las recompensas no cambian mientras la app está abierta: se piden una vez.
  /// Sin conexión, valen las últimas guardadas en el teléfono.
  Future<Map<String, Recompensa>> recompensas() async {
    if (_recompensas case final guardadas?) return guardadas;
    List datos;
    try {
      datos = await ApiCliente.get('/enemigos') as List;
      await AlmacenLocal.guardar(_clave, datos);
    } on ApiExcepcion catch (e) {
      if (!e.sinConexion) rethrow;
      datos = await AlmacenLocal.leer(_clave) as List? ?? (throw e);
    }
    return _recompensas = {
      for (final r in datos.map(
        (r) => Recompensa.fromMap(r as Map<String, dynamic>),
      ))
        r.id: r,
    };
  }

  /// Ids de los jefes.
  static Set<String> jefes(Map<String, Recompensa> recompensas) => {
    for (final r in recompensas.values)
      if (r.categoria == Categoria.jefe) r.id,
  };
}
