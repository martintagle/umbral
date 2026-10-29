import '../contrato/apariencia.dart';
import '../contrato/atributos.dart';
import '../contrato/clase_codigo.dart';
import '../contrato/partida_jugable.dart';
import '../contrato/progreso.dart';
import 'api_cliente.dart';
import 'usuario_api.dart';

/// Partidas del usuario con la sesión iniciada.
class PartidaApi {
  final _usuarios = UsuarioApi();

  Future<List<PartidaJugable>> listarPartidas() async {
    final datos = await ApiCliente.get('/partidas') as List;
    return datos
        .map((p) => PartidaJugable.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  /// El servidor crea el personaje copiando los atributos base de su clase.
  Future<PartidaJugable> crearPartida({
    required String nombre,
    required ClaseCodigo claseCodigo,
    required Apariencia apariencia,
  }) async {
    final datos = await ApiCliente.post('/partidas', {
      'nombre': nombre,
      'claseCodigo': claseCodigo.name,
      'apariencia': apariencia.name,
    });
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Envía lo ocurrido desde el último guardado; el servidor aplica las reglas
  /// y devuelve la partida actualizada.
  Future<PartidaJugable> registrarProgreso(
    String partidaId,
    Progreso progreso,
  ) async {
    final datos = await ApiCliente.post(
      '/partidas/$partidaId/progreso',
      progreso.toMap(),
    );
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Sube atributos gastando experiencia: [incrementos] dice cuántos puntos
  /// van a cada uno. Cada punto es un nivel; el servidor cobra y valida.
  Future<PartidaJugable> subirAtributos(
    String partidaId,
    Atributos incrementos,
  ) async {
    final datos = await ApiCliente.post(
      '/partidas/$partidaId/atributos',
      incrementos.toMap(),
    );
    return PartidaJugable.fromMap(datos as Map<String, dynamic>);
  }

  /// Sube un nivel el `arma` o la `armadura` a cambio de oro.
  Future<PartidaJugable> mejorarEquipo(String partidaId, String pieza) async {
    final datos = await ApiCliente.post('/partidas/$partidaId/mejora', {
      'pieza': pieza,
    });
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
