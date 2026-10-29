import 'apariencia.dart';
import 'atributos.dart';
import 'clase_codigo.dart';
import 'equipo.dart';
import 'estadisticas.dart';
import 'mundo.dart';
import 'ubicacion.dart';

/// Subdocumento `usuarios.partidas[].personaje` tal como viaja en el JSON de la API.
class Personaje {
  final String nombre;

  /// Llave hacia `clases._id`. El nombre, el arma y la descripción se buscan
  /// en la clase (`ClaseApi.clase`); no se copian en el personaje.
  final ClaseCodigo claseCodigo;
  final Apariencia apariencia;
  final int nivel;
  final int exp;
  final int puntosLibres;
  final int oro;

  /// Al crear el personaje son los `atributosBase` de su clase; después
  /// evolucionan solos.
  final Atributos atributos;
  final int vidaActual;
  final int estaminaActual;
  final Equipo equipo;
  final Ubicacion ubicacion;
  final Mundo mundo;
  final Estadisticas estadisticas;

  const Personaje({
    required this.nombre,
    required this.claseCodigo,
    required this.apariencia,
    required this.nivel,
    required this.exp,
    required this.puntosLibres,
    required this.oro,
    required this.atributos,
    required this.vidaActual,
    required this.estaminaActual,
    required this.equipo,
    required this.ubicacion,
    required this.mundo,
    required this.estadisticas,
  });

  factory Personaje.fromMap(Map<String, dynamic> map) {
    return Personaje(
      nombre: map['nombre'] as String,
      claseCodigo: ClaseCodigo.values.byName(map['claseCodigo'] as String),
      apariencia: Apariencia.values.byName(map['apariencia'] as String),
      nivel: map['nivel'] as int,
      exp: map['exp'] as int,
      puntosLibres: map['puntosLibres'] as int,
      oro: map['oro'] as int,
      atributos: Atributos.fromMap(map['atributos'] as Map<String, dynamic>),
      vidaActual: map['vidaActual'] as int,
      estaminaActual: map['estaminaActual'] as int,
      equipo: Equipo.fromMap(map['equipo'] as Map<String, dynamic>),
      ubicacion: Ubicacion.fromMap(map['ubicacion'] as Map<String, dynamic>),
      mundo: Mundo.fromMap(map['mundo'] as Map<String, dynamic>),
      estadisticas: Estadisticas.fromMap(
        map['estadisticas'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'claseCodigo': claseCodigo.name,
      'apariencia': apariencia.name,
      'nivel': nivel,
      'exp': exp,
      'puntosLibres': puntosLibres,
      'oro': oro,
      'atributos': atributos.toMap(),
      'vidaActual': vidaActual,
      'estaminaActual': estaminaActual,
      'equipo': equipo.toMap(),
      'ubicacion': ubicacion.toMap(),
      'mundo': mundo.toMap(),
      'estadisticas': estadisticas.toMap(),
    };
  }
}
