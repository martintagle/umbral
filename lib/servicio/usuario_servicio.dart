import '../dto/ajustes_dto.dart';
import '../dto/usuario_dto.dart';
import 'api_cliente.dart';
import 'sesion_servicio.dart';

class UsuarioServicio {
  /// Crea la cuenta y deja la sesión iniciada.
  Future<UsuarioDto> registrar({
    required String username,
    required String email,
    required String password,
  }) async {
    final datos = await ApiCliente.post('/usuarios/registro',
        {'username': username, 'email': email, 'password': password});
    return _abrirSesion(datos as Map<String, dynamic>);
  }

  /// [identificador] puede ser el email o el username.
  Future<UsuarioDto> iniciarSesion(String identificador, String password) async {
    final datos = await ApiCliente.post('/usuarios/login',
        {'identificador': identificador, 'password': password});
    return _abrirSesion(datos as Map<String, dynamic>);
  }

  /// Pide el usuario al servidor y actualiza la sesión con él.
  Future<UsuarioDto> obtenerYo() async {
    final usuario = UsuarioDto.fromMap(
        await ApiCliente.get('/usuarios/yo') as Map<String, dynamic>);
    SesionServicio.actualizar(usuario);
    return usuario;
  }

  Future<void> actualizarAjustes(AjustesDto ajustes) =>
      ApiCliente.put('/usuarios/yo/ajustes', ajustes.toMap());

  Future<void> eliminarCuenta() async {
    await ApiCliente.delete('/usuarios/yo');
    SesionServicio.cerrar();
  }

  void cerrarSesion() => SesionServicio.cerrar();

  UsuarioDto _abrirSesion(Map<String, dynamic> datos) {
    final usuario = UsuarioDto.fromMap(datos['usuario'] as Map<String, dynamic>);
    SesionServicio.abrir(usuario, datos['token'] as String);
    return usuario;
  }
}
