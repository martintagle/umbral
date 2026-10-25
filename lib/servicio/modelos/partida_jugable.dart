import '../../dto/partida_dto.dart';
import 'combate.dart';

/// Lo que devuelve la API por cada partida: la partida guardada y sus valores
/// de combate. No replica ninguna colección.
class PartidaJugable {
  final PartidaDto partida;
  final Combate combate;

  const PartidaJugable({required this.partida, required this.combate});

  factory PartidaJugable.fromMap(Map<String, dynamic> map) {
    return PartidaJugable(
      partida: PartidaDto.fromMap(map['partida'] as Map<String, dynamic>),
      combate: Combate.fromMap(map['combate'] as Map<String, dynamic>),
    );
  }
}
