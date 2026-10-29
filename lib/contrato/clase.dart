import 'atributos_base.dart';
import 'clase_codigo.dart';

/// Documento de la colección `clases` tal como lo envía la API (`GET /clases`):
/// `_id` (el código de la clase) llega como [id]. Es la clase a la que apunta
/// `Personaje.claseCodigo`.
class Clase {
  final ClaseCodigo id;
  final String nombre;
  final String arma;
  final String descripcion;
  final AtributosBase atributosBase;

  const Clase({
    required this.id,
    required this.nombre,
    required this.arma,
    required this.descripcion,
    required this.atributosBase,
  });

  factory Clase.fromJson(Map<String, dynamic> json) {
    return Clase(
      id: ClaseCodigo.values.byName(json['id'] as String),
      nombre: json['nombre'] as String,
      arma: json['arma'] as String,
      descripcion: json['descripcion'] as String,
      atributosBase: AtributosBase.fromJson(
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
