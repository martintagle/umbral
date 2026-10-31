import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Base SQLite del teléfono, para jugar sin conexión. Guarda la última
/// respuesta del servidor a cada consulta (partidas, clases y enemigos) y el
/// progreso que no se pudo enviar; [PartidaApi] lo manda al servidor (y de ahí
/// a Mongo) cuando vuelve la conexión.
///
/// Si la base no se pudo abrir (en las pruebas o en el escritorio), guarda lo
/// mismo en memoria mientras la app está abierta.
abstract final class AlmacenLocal {
  static Database? _bd;
  static final Map<String, String> _cache = {};
  static final Map<String, Map<String, String>> _pendientes = {};

  static Future<void> abrir() async {
    try {
      _bd = await openDatabase(
        p.join(await getDatabasesPath(), 'umbral.db'),
        version: 1,
        onCreate: (bd, _) async {
          await bd.execute(
            'CREATE TABLE cache (clave TEXT PRIMARY KEY, valor TEXT NOT NULL)',
          );
          await bd.execute(
            'CREATE TABLE progreso_pendiente ('
            'usuario_id TEXT NOT NULL, '
            'partida_id TEXT NOT NULL, '
            'progreso TEXT NOT NULL, '
            'PRIMARY KEY (usuario_id, partida_id))',
          );
        },
      );
    } catch (_) {
      _bd = null;
    }
  }

  /// La última respuesta guardada con [clave], ya leída del JSON, o `null`.
  static Future<Object?> leer(String clave) async {
    final bd = _bd;
    final String? texto;
    if (bd == null) {
      texto = _cache[clave];
    } else {
      final filas = await bd.query(
        'cache',
        columns: ['valor'],
        where: 'clave = ?',
        whereArgs: [clave],
      );
      texto = filas.isEmpty ? null : filas.first['valor'] as String;
    }
    return texto == null ? null : jsonDecode(texto);
  }

  static Future<void> guardar(String clave, Object? valor) async {
    final texto = jsonEncode(valor);
    final bd = _bd;
    if (bd == null) {
      _cache[clave] = texto;
      return;
    }
    await bd.insert('cache', {
      'clave': clave,
      'valor': texto,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Progreso sin enviar de cada partida del usuario, por `partidaId`.
  static Future<Map<String, Map<String, dynamic>>> pendientes(
    String usuarioId,
  ) async {
    final bd = _bd;
    final Map<String, String> textos;
    if (bd == null) {
      textos = _pendientes[usuarioId] ?? const {};
    } else {
      textos = {
        for (final fila in await bd.query(
          'progreso_pendiente',
          where: 'usuario_id = ?',
          whereArgs: [usuarioId],
        ))
          fila['partida_id'] as String: fila['progreso'] as String,
      };
    }
    return {
      for (final MapEntry(:key, :value) in textos.entries)
        key: jsonDecode(value) as Map<String, dynamic>,
    };
  }

  static Future<void> guardarPendiente(
    String usuarioId,
    String partidaId,
    Map<String, dynamic> progreso,
  ) async {
    final texto = jsonEncode(progreso);
    final bd = _bd;
    if (bd == null) {
      (_pendientes[usuarioId] ??= {})[partidaId] = texto;
      return;
    }
    await bd.insert('progreso_pendiente', {
      'usuario_id': usuarioId,
      'partida_id': partidaId,
      'progreso': texto,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> borrarPendiente(String usuarioId, String partidaId) async {
    final bd = _bd;
    if (bd == null) {
      _pendientes[usuarioId]?.remove(partidaId);
      return;
    }
    await bd.delete(
      'progreso_pendiente',
      where: 'usuario_id = ? AND partida_id = ?',
      whereArgs: [usuarioId, partidaId],
    );
  }

  /// Olvida las partidas y el progreso pendiente de una cuenta borrada.
  static Future<void> olvidarUsuario(String usuarioId, String clavePartidas) async {
    final bd = _bd;
    if (bd == null) {
      _pendientes.remove(usuarioId);
      _cache.remove(clavePartidas);
      return;
    }
    await bd.delete(
      'progreso_pendiente',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
    );
    await bd.delete('cache', where: 'clave = ?', whereArgs: [clavePartidas]);
  }
}
