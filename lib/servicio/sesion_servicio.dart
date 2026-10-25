import '../dto/usuario_dto.dart';

/// Sesión iniciada mientras la app está abierta: el usuario y el token con el
/// que [ApiCliente] firma las peticiones. Solo la abren y la cierran los
/// servicios; la UI solo la lee.
abstract final class SesionServicio {
  static UsuarioDto? _usuario;
  static String? _token;

  static UsuarioDto? get usuario => _usuario;
  static String? get token => _token;

  static void abrir(UsuarioDto usuario, String token) {
    _usuario = usuario;
    _token = token;
  }

  static void cerrar() {
    _usuario = null;
    _token = null;
  }
}
