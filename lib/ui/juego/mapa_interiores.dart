import 'dart:convert';

import 'package:flutter/services.dart';

typedef PuntoSala = ({String tipo, int x, int y, String texto});

/// Una sala de `assets/interiores/interiores.json`. Las posiciones están en
/// tiles.
class Sala {
  final String slug;
  final String nombre;

  /// Sprite de la estructura del mundo a la que pertenece.
  final String estructura;
  final int ancho;
  final int alto;
  final List<List<int>> suelo;
  final List<List<int>> objetos;
  final List<PuntoSala> puntos;

  Sala._(Map<String, dynamic> m)
      : slug = m['slug'] as String,
        nombre = m['nombre'] as String,
        estructura = m['estructura'] as String,
        ancho = m['ancho'] as int,
        alto = m['alto'] as int,
        suelo = _rejilla(m['suelo']),
        objetos = _rejilla(m['objetos']),
        puntos = [
          for (final p in m['puntos'] as List)
            (
              tipo: p['tipo'] as String,
              x: p['x'] as int,
              y: p['y'] as int,
              texto: p['texto'] as String,
            )
        ];

  PuntoSala? punto(String tipo) =>
      puntos.where((p) => p.tipo == tipo).firstOrNull;

  static List<List<int>> _rejilla(Object? capa) => [
        for (final fila in capa as List) List<int>.from(fila as List),
      ];
}

/// Las salas interiores (ver `docs/diseno/interiores.md`) y su tileset.
class MapaInteriores {
  /// Imagen del tileset, dentro de `assets/interiores/`.
  final String tileset;
  final int columnasTileset;
  final int indiceObjetos;
  final List<String> nombresSuelo;
  final List<String> nombresObjetos;
  final Set<int> sueloBloquea;
  final Set<int> objetosTransitables;
  final List<Sala> salas;

  MapaInteriores._(Map<String, dynamic> m)
      : tileset = m['tileset'] as String,
        columnasTileset = m['columnasTileset'] as int,
        indiceObjetos = m['tiles']['indiceObjetos'] as int,
        nombresSuelo = List<String>.from(m['tiles']['suelo'] as List),
        nombresObjetos = List<String>.from(m['tiles']['objetos'] as List),
        sueloBloquea = {},
        objetosTransitables = {},
        salas = [for (final s in m['salas'] as List) Sala._(s)] {
    final reglas = m['reglas'] as Map<String, dynamic>;
    for (final n in reglas['sueloBloquea'] as List) {
      sueloBloquea.add(nombresSuelo.indexOf(n as String));
    }
    for (final n in reglas['objetosTransitables'] as List) {
      objetosTransitables.add(nombresObjetos.indexOf(n as String));
    }
  }

  static Future<MapaInteriores> cargar() async => MapaInteriores._(jsonDecode(
          await rootBundle.loadString('assets/interiores/interiores.json'))
      as Map<String, dynamic>);

  int objeto(String nombre) => nombresObjetos.indexOf(nombre);
  int suelo(String nombre) => nombresSuelo.indexOf(nombre);

  /// Salas a las que se llega por la puerta de una estructura con ese sprite,
  /// en orden. No incluye las que están bajo otra (se baja por una escalera).
  List<Sala> entradas(String estructura) => [
        for (final s in salas)
          if (s.estructura == estructura && arriba(s) == null) s
      ];

  /// La sala con escalera de bajada que lleva a [sala], si la hay: la anterior
  /// de la misma estructura que tenga una.
  Sala? arriba(Sala sala) {
    final i = salas.indexOf(sala);
    for (var j = i - 1; j >= 0; j--) {
      final s = salas[j];
      if (s.estructura == sala.estructura) {
        return s.punto('bajada') != null ? s : null;
      }
    }
    return null;
  }

  /// La sala a la que lleva la escalera de bajada de [sala].
  Sala? abajo(Sala sala) {
    final i = salas.indexOf(sala);
    for (var j = i + 1; j < salas.length; j++) {
      if (salas[j].estructura == sala.estructura) return salas[j];
    }
    return null;
  }
}
