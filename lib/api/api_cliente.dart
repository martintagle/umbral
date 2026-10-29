import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_excepcion.dart';
import 'sesion.dart';

/// Habla con la API de Umbral (carpeta `servidor/`).
///
/// La dirección se pasa al compilar con `--dart-define=API_URL=...`. Por
/// defecto es la del PC visto desde el emulador de Android (10.0.2.2).
abstract final class ApiCliente {
  static const String base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  // El plan gratis de Render tarda 30-50 s en despertar la API tras estar inactiva.
  static const _espera = Duration(seconds: 60);
  static final http.Client _cliente = http.Client();

  static Future<dynamic> get(String ruta) => _enviar('GET', ruta);
  static Future<dynamic> post(String ruta, Object cuerpo) =>
      _enviar('POST', ruta, cuerpo);
  static Future<dynamic> put(String ruta, Object cuerpo) =>
      _enviar('PUT', ruta, cuerpo);
  static Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  static Future<dynamic> _enviar(
    String metodo,
    String ruta, [
    Object? cuerpo,
  ]) async {
    final peticion = http.Request(metodo, Uri.parse('$base$ruta'))
      ..headers['accept'] = 'application/json';
    final token = Sesion.token;
    if (token != null) peticion.headers['authorization'] = 'Bearer $token';
    if (cuerpo != null) {
      peticion.headers['content-type'] = 'application/json';
      peticion.body = jsonEncode(cuerpo);
    }

    final http.Response respuesta;
    try {
      respuesta = await http.Response.fromStream(
        await _cliente.send(peticion).timeout(_espera),
      );
    } on TimeoutException {
      throw const ApiExcepcion(
        'El servidor tarda demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const ApiExcepcion(
        'No se pudo contactar con el servidor. Revisa tu conexión.',
      );
    }

    final texto = utf8.decode(respuesta.bodyBytes);
    final datos = texto.isEmpty ? null : _json(texto);
    if (respuesta.statusCode >= 400) {
      final mensaje = datos is Map && datos['error'] is String
          ? datos['error'] as String
          : 'Error del servidor (${respuesta.statusCode}).';
      throw ApiExcepcion(mensaje, estado: respuesta.statusCode);
    }
    return datos;
  }

  static Object? _json(String texto) {
    try {
      return jsonDecode(texto);
    } on FormatException {
      throw const ApiExcepcion('El servidor envió una respuesta no válida.');
    }
  }
}
