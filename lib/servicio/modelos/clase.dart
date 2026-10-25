import '../../dto/atributos_dto.dart';
import 'combate.dart';

/// Una clase tal como se muestra al crear un personaje. No replica ninguna
/// colección: es la respuesta de `GET /api/clases`.
class Clase {
  final String id;

  /// Nivel con el que empieza: 1 más cada punto de atributo por encima de 1.
  final int nivel;
  final AtributosDto atributos;
  final int oroInicial;

  /// Valores de combate de un personaje nuevo de esta clase.
  final Combate combate;

  const Clase({
    required this.id,
    required this.nivel,
    required this.atributos,
    required this.oroInicial,
    required this.combate,
  });

  factory Clase.fromMap(Map<String, dynamic> map) {
    return Clase(
      id: map['id'] as String,
      nivel: map['nivel'] as int? ?? 1,
      atributos: AtributosDto.fromMap(map['atributos'] as Map<String, dynamic>),
      oroInicial: map['oroInicial'] as int,
      combate: Combate.fromMap(map['combate'] as Map<String, dynamic>),
    );
  }
}

class CatalogoClases {
  final List<String> apariencias;
  final List<Clase> clases;

  const CatalogoClases({required this.apariencias, required this.clases});

  factory CatalogoClases.fromMap(Map<String, dynamic> map) {
    return CatalogoClases(
      apariencias: List<String>.from(map['apariencias'] as List),
      clases: (map['clases'] as List)
          .map((c) => Clase.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
