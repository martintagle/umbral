import 'atributos_dto.dart';
import 'equipo_dto.dart';
import 'estadisticas_dto.dart';
import 'mundo_dto.dart';
import 'ubicacion_dto.dart';

/// Réplica del subdocumento `usuarios.partidas[].personaje`.
class PersonajeDto {
  final String nombre;
  final String clase;

  /// `hombre` o `mujer`: qué sprite de la clase usa el personaje.
  final String apariencia;
  final int nivel;
  final int exp;
  final int puntosLibres;
  final int oro;
  final AtributosDto atributos;
  final int vidaActual;
  final int estaminaActual;
  final EquipoDto equipo;
  final UbicacionDto ubicacion;
  final MundoDto mundo;
  final EstadisticasDto estadisticas;

  const PersonajeDto({
    required this.nombre,
    required this.clase,
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

  factory PersonajeDto.fromMap(Map<String, dynamic> map) {
    return PersonajeDto(
      nombre: map['nombre'] as String,
      clase: map['clase'] as String,
      apariencia: map['apariencia'] as String,
      nivel: map['nivel'] as int,
      exp: map['exp'] as int,
      puntosLibres: map['puntosLibres'] as int,
      oro: map['oro'] as int,
      atributos: AtributosDto.fromMap(map['atributos'] as Map<String, dynamic>),
      vidaActual: map['vidaActual'] as int,
      estaminaActual: map['estaminaActual'] as int,
      equipo: EquipoDto.fromMap(map['equipo'] as Map<String, dynamic>),
      ubicacion: UbicacionDto.fromMap(map['ubicacion'] as Map<String, dynamic>),
      mundo: MundoDto.fromMap(map['mundo'] as Map<String, dynamic>),
      estadisticas:
          EstadisticasDto.fromMap(map['estadisticas'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'clase': clase,
      'apariencia': apariencia,
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
