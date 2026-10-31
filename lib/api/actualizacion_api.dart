import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../contrato/actualizacion.dart';

/// Busca si hay una versión nueva del APK. Las publica
/// `.github/workflows/release.yml` como Release de GitHub al subir un tag
/// `vX.Y.Z`; la versión instalada es la de `pubspec.yaml`.
class ActualizacionApi {
  /// Repositorio de las Releases (`--dart-define=REPO_RELEASES=dueño/repo`).
  static const _repo = String.fromEnvironment(
    'REPO_RELEASES',
    defaultValue: 'martintagle/umbral',
  );

  static Future<Actualizacion?>? _busqueda;

  /// La versión publicada si es más nueva que la instalada. `null` si no la
  /// hay, si no se pudo saber (sin conexión, por ejemplo) o si no es Android:
  /// el APK solo sirve allí. Se busca una vez cada vez que se abre la app.
  Future<Actualizacion?> buscar() => _busqueda ??= _buscar();

  Future<Actualizacion?> _buscar() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final instalada = (await PackageInfo.fromPlatform()).version;
      final respuesta = await http
          .get(
            Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
            headers: {'accept': 'application/vnd.github+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) return null;
      final publicada = Actualizacion.fromMap(
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>,
      );
      return esMasNueva(publicada.version, instalada) ? publicada : null;
    } catch (_) {
      return null;
    }
  }

  /// Compara versiones `x.y.z` número a número; lo que falta cuenta como 0 y
  /// se ignoran los sufijos (`-beta`, `+7`).
  static bool esMasNueva(String publicada, String instalada) {
    List<int> partes(String v) => [
      for (final p in v.split(RegExp(r'[-+]')).first.split('.'))
        int.tryParse(p) ?? 0,
    ];
    final a = partes(publicada), b = partes(instalada);
    for (var i = 0; i < a.length || i < b.length; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
