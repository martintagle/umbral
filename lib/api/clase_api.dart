import '../contrato/clase_codigo.dart';
import '../contrato/clase.dart';
import 'almacen_local.dart';
import 'api_cliente.dart';
import 'api_excepcion.dart';
import '../contrato/catalogo_clases.dart';

/// Colección `clases`: las que se pueden elegir al crear un personaje y de
/// donde salen el nombre, el arma y la descripción de cada personaje.
class ClaseApi {
  static Future<CatalogoClases>? _pedido;
  static CatalogoClases? _catalogo;
  static const _clave = 'clases';

  /// Las clases no cambian: se piden una vez (al abrir la app) y se guardan.
  /// Sin conexión, vale la última copia del teléfono. Si la petición falla,
  /// la siguiente llamada lo vuelve a intentar.
  Future<CatalogoClases> catalogo() => _pedido ??= _pedir();

  Future<CatalogoClases> _pedir() async {
    try {
      Map<String, dynamic> datos;
      try {
        datos = await ApiCliente.get('/clases') as Map<String, dynamic>;
        await AlmacenLocal.guardar(_clave, datos);
      } on ApiExcepcion catch (e) {
        if (!e.sinConexion) rethrow;
        datos = await AlmacenLocal.leer(_clave) as Map<String, dynamic>? ??
            (throw e);
        // Con la copia se puede jugar, pero se reintenta la próxima vez.
        _pedido = null;
      }
      return _catalogo = CatalogoClases.fromMap(datos);
    } catch (_) {
      _pedido = null;
      rethrow;
    }
  }

  /// Clase de un personaje, buscada por su `claseCodigo`. `null` mientras no
  /// ha llegado el catálogo.
  static Clase? clase(ClaseCodigo codigo) => _catalogo?.clase(codigo);
}
