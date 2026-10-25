import '../dto/partida_jugable_dto.dart';
import '../dto/progreso_dto.dart';
import 'api_cliente.dart';

/// Partidas del usuario con la sesión iniciada.
class PartidaServicio {
  Future<List<PartidaJugableDto>> listarPartidas() async {
    final datos = await ApiCliente.get('/partidas') as List;
    return datos
        .map((p) => PartidaJugableDto.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  /// El servidor crea el personaje con las estadísticas de su clase.
  Future<PartidaJugableDto> crearPartida({
    required String nombre,
    required String clase,
    required String apariencia,
  }) async {
    final datos = await ApiCliente.post('/partidas',
        {'nombre': nombre, 'clase': clase, 'apariencia': apariencia});
    return PartidaJugableDto.fromMap(datos as Map<String, dynamic>);
  }

  /// Envía lo ocurrido desde el último guardado; el servidor aplica las reglas
  /// y devuelve la partida actualizada.
  Future<PartidaJugableDto> registrarProgreso(
      String partidaId, ProgresoDto progreso) async {
    final datos =
        await ApiCliente.post('/partidas/$partidaId/progreso', progreso.toMap());
    return PartidaJugableDto.fromMap(datos as Map<String, dynamic>);
  }

  Future<void> eliminarPartida(String partidaId) =>
      ApiCliente.delete('/partidas/$partidaId');

  Future<void> seleccionarPartidaActiva(String? partidaId) =>
      ApiCliente.put('/partidas/activa', {'partidaId': partidaId});
}
