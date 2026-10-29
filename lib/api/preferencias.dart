import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../contrato/usuario.dart';

/// Lo que el teléfono recuerda entre aperturas de la app: la última sesión
/// iniciada y el volumen. Se guarda en el almacenamiento privado de la app.
/// Si no se pudo cargar (por ejemplo, en las pruebas), no recuerda nada.
abstract final class Preferencias {
  static const _token = 'sesion.token';
  static const _usuario = 'sesion.usuario';
  static const _identificador = 'sesion.identificador';
  static const _musica = 'ajustes.musica';
  static const _efectos = 'ajustes.efectos';

  static SharedPreferences? _prefs;

  static Future<void> cargar() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  static String? get token => _prefs?.getString(_token);

  /// Usuario de la última sesión, para mostrarlo antes de que responda el
  /// servidor.
  static Usuario? get usuario {
    final texto = _prefs?.getString(_usuario);
    if (texto == null) return null;
    try {
      return Usuario.fromMap(jsonDecode(texto) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Correo o usuario con el que se entró por última vez: rellena el login
  /// aunque la sesión haya caducado.
  static String? get identificador => _prefs?.getString(_identificador);

  static void guardarSesion(Usuario usuario, String token) {
    _prefs
      ?..setString(_token, token)
      ..setString(_usuario, jsonEncode(usuario.toMap()))
      ..setString(_identificador, usuario.username);
  }

  static void guardarUsuario(Usuario usuario) =>
      _prefs?.setString(_usuario, jsonEncode(usuario.toMap()));

  /// Olvida el token, pero no el identificador.
  static void olvidarSesion() {
    _prefs
      ?..remove(_token)
      ..remove(_usuario);
  }

  static double? get musica => _prefs?.getDouble(_musica);
  static double? get efectos => _prefs?.getDouble(_efectos);

  static void guardarVolumen({
    required double musica,
    required double efectos,
  }) {
    _prefs
      ?..setDouble(_musica, musica)
      ..setDouble(_efectos, efectos);
  }
}
