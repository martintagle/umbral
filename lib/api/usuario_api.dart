import '../contrato/ajustes.dart';
import '../contrato/usuario.dart';
import 'almacen_local.dart';
import 'api_cliente.dart';
import 'sesion.dart';

class UsuarioApi {
  /// Crea la cuenta y deja la sesión iniciada.
  Future<Usuario> registrar({
    required String username,
    required String email,
    required String password,
  }) async {
    final datos = await ApiCliente.post('/usuarios/registro', {
      'username': username,
      'email': email,
      'password': password,
    });
    return _abrirSesion(datos as Map<String, dynamic>);
  }

  /// [identificador] puede ser el email o el username.
  Future<Usuario> iniciarSesion(String identificador, String password) async {
    final datos = await ApiCliente.post('/usuarios/login', {
      'identificador': identificador,
      'password': password,
    });
    return _abrirSesion(datos as Map<String, dynamic>);
  }

  /// Vuelve a abrir la última sesión guardada en el teléfono, sin pedir la
  /// contraseña. Devuelve `false` si no había ninguna. El token puede haber
  /// caducado: la primera petición lo dirá con `sesionCaducada`.
  bool restaurarSesion() => Sesion.restaurar();

  /// Pide el usuario al servidor y actualiza la sesión con él.
  Future<Usuario> obtenerYo() async {
    final usuario = Usuario.fromMap(
      await ApiCliente.get('/usuarios/yo') as Map<String, dynamic>,
    );
    Sesion.actualizar(usuario);
    return usuario;
  }

  Future<void> actualizarAjustes(Ajustes ajustes) =>
      ApiCliente.put('/usuarios/yo/ajustes', ajustes.toMap());

  Future<void> eliminarCuenta() async {
    await ApiCliente.delete('/usuarios/yo');
    if (Sesion.usuario?.id case final id?) {
      await AlmacenLocal.olvidarUsuario(id, 'partidas:$id');
    }
    Sesion.cerrar();
  }

  void cerrarSesion() => Sesion.cerrar();

  Usuario _abrirSesion(Map<String, dynamic> datos) {
    final usuario = Usuario.fromMap(datos['usuario'] as Map<String, dynamic>);
    Sesion.abrir(usuario, datos['token'] as String);
    return usuario;
  }
}
