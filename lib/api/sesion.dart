import '../contrato/usuario.dart';
import 'preferencias.dart';

/// Sesión iniciada: el usuario y el token con el que [ApiCliente] firma las
/// peticiones. Se recuerda en el teléfono hasta cerrar sesión, así que no hay
/// que volver a escribir la contraseña al abrir la app. Solo la abren y la
/// cierran las clases de `api/`; la UI solo la lee.
abstract final class Sesion {
  static Usuario? _usuario;
  static String? _token;

  static Usuario? get usuario => _usuario;
  static String? get token => _token;

  static void abrir(Usuario usuario, String token) {
    _usuario = usuario;
    _token = token;
    Preferencias.guardarSesion(usuario, token);
  }

  /// Recupera la sesión que quedó guardada en el teléfono. Devuelve `false`
  /// si no hay ninguna.
  static bool restaurar() {
    final token = Preferencias.token;
    if (token == null) return false;
    _token = token;
    _usuario = Preferencias.usuario;
    return true;
  }

  /// Sustituye el usuario por la versión más reciente del servidor.
  static void actualizar(Usuario usuario) {
    _usuario = usuario;
    Preferencias.guardarUsuario(usuario);
  }

  static void cerrar() {
    _usuario = null;
    _token = null;
    Preferencias.olvidarSesion();
  }
}
