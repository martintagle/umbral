import '../contrato/apariencia.dart';
import '../contrato/atributos.dart';
import '../contrato/clase_codigo.dart';
import '../contrato/partida_jugable.dart';
import '../contrato/progreso.dart';
import 'almacen_local.dart';
import 'api_cliente.dart';
import 'api_excepcion.dart';
import 'enemigo_api.dart';
import 'progreso_pendiente.dart';
import 'sesion.dart';
import 'sincronizacion.dart';
import 'usuario_api.dart';

/// Partidas del usuario con la sesión iniciada.
///
/// Se puede jugar sin conexión: la lista sale de la última copia guardada en
/// el teléfono ([AlmacenLocal]) y el progreso que no llega al servidor se
/// guarda allí y se envía al recuperar la conexión, antes que cualquier otro
/// cambio de esa partida. Crear, borrar, subir de nivel y mejorar el equipo
/// necesitan conexión: sus reglas son del servidor.
class PartidaApi {
  final _usuarios = UsuarioApi();

  /// Guardar y sincronizar van de uno en uno: así un progreso nunca se envía
  /// dos veces ni se pierde entre el envío y el borrado del pendiente.
  static Future<void> _cola = Future.value();

  static Future<T> _enCola<T>(Future<T> Function() tarea) {
    final resultado = _cola.then((_) => tarea());
    _cola = resultado.then((_) {}, onError: (_) {});
    return resultado;
  }

  String get _usuarioId => Sesion.usuario?.id ?? '';
  String get _clavePartidas => 'partidas:$_usuarioId';

  Future<List<PartidaJugable>> listarPartidas() async {
    try {
      await sincronizar();
      final datos = await ApiCliente.get('/partidas') as List;
      await AlmacenLocal.guardar(_clavePartidas, datos);
      return [
        for (final p in datos)
          PartidaJugable.fromMap(p as Map<String, dynamic>),
      ];
    } on ApiExcepcion catch (e) {
      if (!e.sinConexion) rethrow;
      return await _locales() ?? (throw e);
    }
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
    return _recordar(datos as Map<String, dynamic>);
  }

  /// Envía lo ocurrido desde el último guardado; el servidor aplica las reglas
  /// y devuelve la partida actualizada. Sin conexión, lo suma a lo pendiente
  /// de esa partida y devuelve cómo quedará al enviarlo.
  Future<PartidaJugable> registrarProgreso(
    String partidaId,
    Progreso progreso,
  ) => _enCola(() async {
    try {
      await _enviarPendientes();
      return await _enviarProgreso(partidaId, progreso.toMap());
    } on ApiExcepcion catch (e) {
      if (!e.sinConexion) rethrow;
      final pendientes = await AlmacenLocal.pendientes(_usuarioId);
      final anterior = pendientes[partidaId];
      final total = anterior == null
          ? progreso.toMap()
          : sumarProgresos(anterior, progreso.toMap());
      // Sin copia de la partida no hay con qué seguir jugando: no se guarda
      // nada y el juego conserva el progreso para reintentar.
      final local = await _local(partidaId, total);
      if (local == null) rethrow;
      await AlmacenLocal.guardarPendiente(_usuarioId, partidaId, total);
      Sincronizacion.pendientes.value = {...pendientes.keys, partidaId}.length;
      return local;
    }
  });

  /// Envía el progreso guardado sin conexión. Falla con [ApiExcepcion] si
  /// sigue sin haber conexión o la sesión caducó; lo pendiente se conserva.
  Future<void> sincronizar() => _enCola(_enviarPendientes);

  Future<void> _enviarPendientes() async {
    final pendientes = await AlmacenLocal.pendientes(_usuarioId);
    Sincronizacion.pendientes.value = pendientes.length;
    for (final MapEntry(key: partidaId, value: progreso)
        in pendientes.entries) {
      try {
        await _enviarProgreso(partidaId, progreso);
      } on ApiExcepcion catch (e) {
        // Si el servidor lo rechaza o la partida ya no existe, no se podrá
        // aplicar nunca: se descarta. Lo demás se reintenta más tarde.
        final rechazado =
            e.estado != null &&
            e.estado! >= 400 &&
            e.estado! < 500 &&
            !e.sesionCaducada &&
            e.estado != 409 &&
            e.estado != 429;
        if (!rechazado) rethrow;
      }
      await AlmacenLocal.borrarPendiente(_usuarioId, partidaId);
      Sincronizacion.pendientes.value--;
    }
  }

  Future<PartidaJugable> _enviarProgreso(
    String partidaId,
    Map<String, dynamic> progreso,
  ) async {
    final datos = await ApiCliente.post(
      '/partidas/$partidaId/progreso',
      progreso,
    );
    return _recordar(datos as Map<String, dynamic>);
  }

  /// Sube atributos gastando experiencia: [incrementos] dice cuántos puntos
  /// van a cada uno. Cada punto es un nivel; el servidor cobra y valida.
  Future<PartidaJugable> subirAtributos(
    String partidaId,
    Atributos incrementos,
  ) => _conServidor('Subir de nivel', () async {
    final datos = await ApiCliente.post(
      '/partidas/$partidaId/atributos',
      incrementos.toMap(),
    );
    return _recordar(datos as Map<String, dynamic>);
  });

  /// Sube un nivel el `arma` o la `armadura` a cambio de oro.
  Future<PartidaJugable> mejorarEquipo(String partidaId, String pieza) =>
      _conServidor('Mejorar el equipo', () async {
        final datos = await ApiCliente.post('/partidas/$partidaId/mejora', {
          'pieza': pieza,
        });
        return _recordar(datos as Map<String, dynamic>);
      });

  /// Para gastar experiencia u oro, el servidor debe tener antes todo lo
  /// ganado sin conexión.
  Future<PartidaJugable> _conServidor(
    String accion,
    Future<PartidaJugable> Function() peticion,
  ) => _enCola(() async {
    try {
      await _enviarPendientes();
      return await peticion();
    } on ApiExcepcion catch (e) {
      if (!e.sinConexion) rethrow;
      throw ApiExcepcion(
        'Sin conexión. $accion necesita internet; tu progreso sigue '
        'guardado en el teléfono.',
        sinConexion: true,
      );
    }
  });

  /// Si era la partida activa, el servidor la deja sin activa; la sesión se
  /// actualiza para reflejarlo.
  Future<void> eliminarPartida(String partidaId) async {
    await ApiCliente.delete('/partidas/$partidaId');
    await _enCola(() => AlmacenLocal.borrarPendiente(_usuarioId, partidaId));
    final guardadas = await AlmacenLocal.leer(_clavePartidas) as List?;
    if (guardadas != null) {
      await AlmacenLocal.guardar(_clavePartidas, [
        for (final p in guardadas)
          if (_id(p as Map<String, dynamic>) != partidaId) p,
      ]);
    }
    await _usuarios.obtenerYo();
  }

  Future<void> seleccionarPartidaActiva(String? partidaId) async {
    await ApiCliente.put('/partidas/activa', {'partidaId': partidaId});
    await _usuarios.obtenerYo();
  }

  /// Guarda en el teléfono la versión del servidor de una partida.
  Future<PartidaJugable> _recordar(Map<String, dynamic> datos) async {
    final guardadas = await AlmacenLocal.leer(_clavePartidas) as List? ?? [];
    final id = _id(datos);
    await AlmacenLocal.guardar(_clavePartidas, [
      for (final p in guardadas)
        if (_id(p as Map<String, dynamic>) != id) p,
      datos,
    ]);
    return PartidaJugable.fromMap(datos);
  }

  /// Las partidas guardadas en el teléfono con su progreso pendiente, o
  /// `null` si nunca se guardaron.
  Future<List<PartidaJugable>?> _locales() async {
    final guardadas = await AlmacenLocal.leer(_clavePartidas) as List?;
    if (guardadas == null) return null;
    final pendientes = await AlmacenLocal.pendientes(_usuarioId);
    Sincronizacion.pendientes.value = pendientes.length;
    final jefes = await _jefes();
    return [
      for (final p in guardadas.cast<Map<String, dynamic>>())
        PartidaJugable.fromMap(switch (pendientes[_id(p)]) {
          final progreso? => partidaConProgreso(p, progreso, jefes),
          null => p,
        }),
    ];
  }

  /// La partida guardada en el teléfono con [progreso] aplicado.
  Future<PartidaJugable?> _local(
    String partidaId,
    Map<String, dynamic> progreso,
  ) async {
    final guardadas = await AlmacenLocal.leer(_clavePartidas) as List?;
    final partida = guardadas
        ?.cast<Map<String, dynamic>>()
        .where((p) => _id(p) == partidaId)
        .firstOrNull;
    if (partida == null) return null;
    return PartidaJugable.fromMap(
      partidaConProgreso(partida, progreso, await _jefes()),
    );
  }

  Future<Set<String>> _jefes() async {
    try {
      return EnemigoApi.jefes(await EnemigoApi().recompensas());
    } on ApiExcepcion {
      return const {};
    }
  }

  static String _id(Map<String, dynamic> jugable) =>
      (jugable['partida'] as Map<String, dynamic>)['partidaId'] as String;
}
