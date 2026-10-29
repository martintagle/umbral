import '../contrato/clase_codigo.dart';
import '../contrato/clase.dart';
import 'api_cliente.dart';
import '../contrato/catalogo_clases.dart';

/// Colección `clases`: las que se pueden elegir al crear un personaje y de
/// donde salen el nombre, el arma y la descripción de cada personaje.
class ClaseApi {
  static Future<CatalogoClases>? _pedido;
  static CatalogoClases? _catalogo;

  /// Las clases no cambian: se piden una vez (al abrir la app) y se guardan.
  /// Si la petición falla, la siguiente llamada lo vuelve a intentar.
  Future<CatalogoClases> catalogo() => _pedido ??= _pedir();

  Future<CatalogoClases> _pedir() async {
    try {
      return _catalogo = CatalogoClases.fromMap(
        await ApiCliente.get('/clases') as Map<String, dynamic>,
      );
    } catch (_) {
      _pedido = null;
      rethrow;
    }
  }

  /// Clase de un personaje, buscada por su `claseCodigo`. `null` mientras no
  /// ha llegado el catálogo.
  static Clase? clase(ClaseCodigo codigo) => _catalogo?.clase(codigo);
}
