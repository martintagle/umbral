import '../dto/usuario_dto.dart';
import 'preferencias_servicio.dart';

/// Sesión iniciada: el usuario y el token con el que [ApiCliente] firma las
/// peticiones. Se recuerda en el teléfono hasta cerrar sesión, así que no hay
/// que volver a escribir la contraseña al abrir la app. Solo la abren y la
/// cierran los servicios; la UI solo la lee.
abstract final class SesionServicio {
  static UsuarioDto? _usuario;
  static String? _token;

  static UsuarioDto? get usuario => _usuario;
  static String? get token => _token;

  static void abrir(UsuarioDto usuario, String token) {
    _usuario = usuario;
    _token = token;
    PreferenciasServicio.guardarSesion(usuario, token);
  }

  /// Recupera la sesión que quedó guardada en el teléfono. Devuelve `false`
  /// si no hay ninguna.
  static bool restaurar() {
    final token = PreferenciasServicio.token;
    if (token == null) return false;
    _token = token;
    _usuario = PreferenciasServicio.usuario;
    return true;
  }

  /// Sustituye el usuario por la versión más reciente del servidor.
  static void actualizar(UsuarioDto usuario) {
    _usuario = usuario;
    PreferenciasServicio.guardarUsuario(usuario);
  }

  static void cerrar() {
    _usuario = null;
    _token = null;
    PreferenciasServicio.olvidarSesion();
  }
}
