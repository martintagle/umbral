import 'apariencia.dart';
import 'clase_codigo.dart';
import 'clase.dart';
import 'combate.dart';

/// Una clase con lo que tendría un personaje nuevo de esa clase. No replica
/// ninguna colección: la clase sí ([clase]); el resto lo calcula el servidor.
class ClaseInicial {
  final Clase clase;

  /// Nivel con el que empieza: 1 más cada punto de atributo por encima de 1.
  final int nivel;
  final int oroInicial;

  /// Valores de combate de un personaje nuevo de esta clase.
  final Combate combate;

  const ClaseInicial({
    required this.clase,
    required this.nivel,
    required this.oroInicial,
    required this.combate,
  });

  factory ClaseInicial.fromMap(Map<String, dynamic> map) {
    return ClaseInicial(
      clase: Clase.fromJson(map['clase'] as Map<String, dynamic>),
      nivel: map['nivel'] as int,
      oroInicial: map['oroInicial'] as int,
      combate: Combate.fromMap(map['combate'] as Map<String, dynamic>),
    );
  }
}

/// Respuesta de `GET /api/clases`.
class CatalogoClases {
  final List<Apariencia> apariencias;
  final List<ClaseInicial> clases;

  const CatalogoClases({required this.apariencias, required this.clases});

  factory CatalogoClases.fromMap(Map<String, dynamic> map) {
    return CatalogoClases(
      apariencias: (map['apariencias'] as List)
          .map((a) => Apariencia.values.byName(a as String))
          .toList(),
      clases: (map['clases'] as List)
          .map((c) => ClaseInicial.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  Clase? clase(ClaseCodigo codigo) =>
      clases.where((c) => c.clase.id == codigo).firstOrNull?.clase;
}
