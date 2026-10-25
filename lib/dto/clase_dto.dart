import 'atributos_dto.dart';
import 'combate_dto.dart';

/// Una clase tal como se muestra al crear un personaje. No es una colección:
/// es la respuesta de `GET /api/clases`.
class ClaseDto {
  final String id;
  final AtributosDto atributos;
  final int oroInicial;

  /// Valores de combate de un personaje nuevo de esta clase.
  final CombateDto combate;

  const ClaseDto({
    required this.id,
    required this.atributos,
    required this.oroInicial,
    required this.combate,
  });

  factory ClaseDto.fromMap(Map<String, dynamic> map) {
    return ClaseDto(
      id: map['id'] as String,
      atributos: AtributosDto.fromMap(map['atributos'] as Map<String, dynamic>),
      oroInicial: map['oroInicial'] as int,
      combate: CombateDto.fromMap(map['combate'] as Map<String, dynamic>),
    );
  }
}

class CatalogoClasesDto {
  final List<String> apariencias;
  final List<ClaseDto> clases;

  const CatalogoClasesDto({required this.apariencias, required this.clases});

  factory CatalogoClasesDto.fromMap(Map<String, dynamic> map) {
    return CatalogoClasesDto(
      apariencias: List<String>.from(map['apariencias'] as List),
      clases: (map['clases'] as List)
          .map((c) => ClaseDto.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
