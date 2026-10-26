import 'atributos_base_dto.dart';
import 'clase_codigo.dart';

/// Réplica de un documento de la colección `clases`, tal como lo envía la API:
/// `_id` (el código de la clase) llega como [id]. Es la clase a la que apunta
/// `PersonajeDto.claseCodigo`.
class ClaseDto {
  final ClaseCodigo id;
  final String nombre;
  final String arma;
  final String descripcion;
  final AtributosBaseDto atributosBase;

  const ClaseDto({
    required this.id,
    required this.nombre,
    required this.arma,
    required this.descripcion,
    required this.atributosBase,
  });

  factory ClaseDto.fromJson(Map<String, dynamic> json) {
    return ClaseDto(
      id: ClaseCodigo.values.byName(json['id'] as String),
      nombre: json['nombre'] as String,
      arma: json['arma'] as String,
      descripcion: json['descripcion'] as String,
      atributosBase: AtributosBaseDto.fromJson(
        json['atributosBase'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'nombre': nombre,
      'arma': arma,
      'descripcion': descripcion,
      'atributosBase': atributosBase.toJson(),
    };
  }
}
