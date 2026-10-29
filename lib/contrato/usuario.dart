import 'ajustes.dart';
import 'estado_usuario.dart';
import 'partida.dart';

/// Documento de la colección `usuarios`, con sus subdocumentos
/// embebidos, tal como lo envía la API: `_id` llega como [id] en texto y
/// `passwordHash` nunca sale del servidor.
class Usuario {
  final String id;
  final String username;
  final String email;
  final EstadoUsuario estado;
  final DateTime creadoEn;
  final DateTime? ultimoLogin;
  final DateTime actualizadoEn;
  final int versionEsquema;
  final Ajustes ajustes;
  final String? partidaActiva;
  final List<Partida> partidas;

  const Usuario({
    required this.id,
    required this.username,
    required this.email,
    required this.estado,
    required this.creadoEn,
    this.ultimoLogin,
    required this.actualizadoEn,
    required this.versionEsquema,
    required this.ajustes,
    this.partidaActiva,
    required this.partidas,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    final ultimoLogin = map['ultimoLogin'] as String?;
    return Usuario(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      estado: EstadoUsuario.values.byName(map['estado'] as String),
      creadoEn: DateTime.parse(map['creadoEn'] as String),
      ultimoLogin: ultimoLogin == null ? null : DateTime.parse(ultimoLogin),
      actualizadoEn: DateTime.parse(map['actualizadoEn'] as String),
      versionEsquema: map['versionEsquema'] as int,
      ajustes: Ajustes.fromMap(map['ajustes'] as Map<String, dynamic>),
      partidaActiva: map['partidaActiva'] as String?,
      partidas: (map['partidas'] as List)
          .map((p) => Partida.fromMap(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'estado': estado.name,
      'creadoEn': creadoEn.toUtc().toIso8601String(),
      'ultimoLogin': ultimoLogin?.toUtc().toIso8601String(),
      'actualizadoEn': actualizadoEn.toUtc().toIso8601String(),
      'versionEsquema': versionEsquema,
      'ajustes': ajustes.toMap(),
      'partidaActiva': partidaActiva,
      'partidas': partidas.map((p) => p.toMap()).toList(),
    };
  }
}
