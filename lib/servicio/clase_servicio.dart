import 'modelos/clase.dart';
import 'api_cliente.dart';

/// Clases que se pueden elegir al crear un personaje.
class ClaseServicio {
  static CatalogoClases? _catalogo;

  /// El catálogo no cambia mientras la app está abierta: se pide una vez.
  Future<CatalogoClases> catalogo() async =>
      _catalogo ??= CatalogoClases.fromMap(
        await ApiCliente.get('/clases') as Map<String, dynamic>,
      );
}
