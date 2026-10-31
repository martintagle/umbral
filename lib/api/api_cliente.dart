import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_excepcion.dart';
import 'sesion.dart';
import 'sincronizacion.dart';

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

  /// Una consulta se puede repetir sin riesgo: se corta antes y se reintenta
  /// con conexiones nuevas, hasta sumar [_espera]. Así una conexión que quedó
  /// colgada (la API se durmió o la red cambió) no deja la pantalla cargando.
  static const _esperaConsulta = Duration(seconds: 12);
  static const _intentosConsulta = 5;
  static http.Client _cliente = http.Client();

  static Future<dynamic> get(String ruta) async {
    for (var intento = 1; ; intento++) {
      try {
        return await _enviar('GET', ruta, null, _esperaConsulta);
      } on ApiExcepcion catch (e) {
        if (!e.agotado || intento == _intentosConsulta) rethrow;
        // Las peticiones en curso siguen en el cliente anterior.
        _cliente = http.Client();
      }
    }
  }

  static Future<dynamic> post(String ruta, Object cuerpo) =>
      _enviar('POST', ruta, cuerpo);
  static Future<dynamic> put(String ruta, Object cuerpo) =>
      _enviar('PUT', ruta, cuerpo);
  static Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  static Future<dynamic> _enviar(
    String metodo,
    String ruta, [
    Object? cuerpo,
    Duration espera = _espera,
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
        await _cliente.send(peticion),
      ).timeout(espera);
    } on TimeoutException {
      // No cuenta como sin conexión: la petición pudo llegar y aplicarse.
      throw const ApiExcepcion(
        'El servidor tarda demasiado en responder. Inténtalo de nuevo.',
        agotado: true,
      );
    } on http.ClientException {
      Sincronizacion.enLinea.value = false;
      throw const ApiExcepcion(
        'No se pudo contactar con el servidor. Revisa tu conexión.',
        sinConexion: true,
      );
    }
    Sincronizacion.enLinea.value = true;

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
