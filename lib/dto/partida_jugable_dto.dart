import 'combate_dto.dart';
import 'partida_dto.dart';

/// Lo que devuelve la API por cada partida: la partida guardada y sus valores
/// de combate. No es una colección.
class PartidaJugableDto {
  final PartidaDto partida;
  final CombateDto combate;

  const PartidaJugableDto({required this.partida, required this.combate});

  factory PartidaJugableDto.fromMap(Map<String, dynamic> map) {
    return PartidaJugableDto(
      partida: PartidaDto.fromMap(map['partida'] as Map<String, dynamic>),
      combate: CombateDto.fromMap(map['combate'] as Map<String, dynamic>),
    );
  }
}
