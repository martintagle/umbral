import '../dto/clase_dto.dart';
import 'api_cliente.dart';

/// Clases que se pueden elegir al crear un personaje.
class ClaseServicio {
  static CatalogoClasesDto? _catalogo;

  /// El catálogo no cambia mientras la app está abierta: se pide una vez.
  Future<CatalogoClasesDto> catalogo() async => _catalogo ??=
      CatalogoClasesDto.fromMap(await ApiCliente.get('/clases') as Map<String, dynamic>);
}
