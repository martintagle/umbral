import '../dto/atributos_dto.dart';
import 'modelos/partida_jugable.dart';
import 'modelos/progreso.dart';
import 'api_cliente.dart';
import 'usuario_servicio.dart';

/// Partidas del usuario con la sesión iniciada.
class PartidaServicio {
  final _usuarios = UsuarioServicio();

  Future<List<PartidaJugable>> listarPartidas() async {
    final datos = await ApiCliente.get('/partidas') as List;
    return datos
        .map((p) => PartidaJugable.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  /// El servidor crea el personaje con las estadísticas de su clase.
  Future<PartidaJugable> crearPartida({
    required String nombre,
    required String clase,
    required String apariencia,
  }) async {
    final datos = await ApiCliente.post('/partidas',
        {'nombre': nombre, 'clase': clase, 'apariencia': apariencia});
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Envía lo ocurrido desde el último guardado; el servidor aplica las reglas
  /// y devuelve la partida actualizada.
  Future<PartidaJugable> registrarProgreso(
      String partidaId, Progreso progreso) async {
    final datos =
        await ApiCliente.post('/partidas/$partidaId/progreso', progreso.toMap());
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Sube atributos gastando experiencia: [incrementos] dice cuántos puntos
  /// van a cada uno. Cada punto es un nivel; el servidor cobra y valida.
  Future<PartidaJugable> subirAtributos(
      String partidaId, AtributosDto incrementos) async {
    final datos = await ApiCliente.post(
        '/partidas/$partidaId/atributos', incrementos.toMap());
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Sube un nivel el `arma` o la `armadura` a cambio de oro.
  Future<PartidaJugable> mejorarEquipo(String partidaId, String pieza) async {
    final datos =
        await ApiCliente.post('/partidas/$partidaId/mejora', {'pieza': pieza});
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Si era la partida activa, el servidor la deja sin activa; la sesión se
  /// actualiza para reflejarlo.
  Future<void> eliminarPartida(String partidaId) async {
    await ApiCliente.delete('/partidas/$partidaId');
    await _usuarios.obtenerYo();
  }

  Future<void> seleccionarPartidaActiva(String? partidaId) async {
    await ApiCliente.put('/partidas/activa', {'partidaId': partidaId});
    await _usuarios.obtenerYo();
  }
}
