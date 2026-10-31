import 'dart:convert';

import 'package:flutter/services.dart';

typedef PuntoSala = ({String tipo, int x, int y, String texto});

/// Una sala de `assets/interiores/interiores.json` o de una mazmorra
/// (`mazmorra-<zona>.json`). Las posiciones están en tiles.
class Sala {
  /// El archivo de la sala: su tileset, sus reglas y su jefe.
  late final MapaInteriores mapa;

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
          ),
      ];

  PuntoSala? punto(String tipo) =>
      puntos.where((p) => p.tipo == tipo).firstOrNull;

  static List<List<int>> _rejilla(Object? capa) => [
    for (final fila in capa as List) List<int>.from(fila as List),
  ];
}

/// Un archivo de salas interiores (ver `docs/diseno/interiores.md` y
/// `docs/mazmorras.md`) y su tileset.
class MapaInteriores {
  /// Mazmorras de los jefes de las zonas 2 a 6, además de `interiores.json`.
  static const _mazmorras = [
    'mazmorra-cienaga',
    'mazmorra-minas',
    'mazmorra-abadia',
    'mazmorra-paramo',
    'mazmorra-umbral',
  ];

  /// `null` en `interiores.json`.
  final String? id;

  /// Zona de la mazmorra; `null` en `interiores.json`, cuyas salas son de
  /// la zona 1 (la cripta) o de cualquier zona (chozas, capilla, torre).
  final String? zona;

  /// Id del jefe que espera en el punto `jefe`; sin él, el Rey Hueco.
  final String? jefe;

  /// Ambiente de la mazmorra (`cera`, `sal`...).
  final String? tema;

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
    : id = m['id'] as String?,
      zona = m['zona'] as String?,
      jefe = m['jefe'] as String?,
      tema = m['tema'] as String?,
      tileset = m['tileset'] as String,
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
    for (final s in salas) {
      s.mapa = this;
    }
  }

  static Future<MapaInteriores> _leer(String archivo) async => MapaInteriores._(
    jsonDecode(await rootBundle.loadString('assets/interiores/$archivo.json'))
        as Map<String, dynamic>,
  );

  /// `interiores.json` y las mazmorras.
  static Future<Interiores> cargar() async => Interiores([
    await _leer('interiores'),
    for (final m in _mazmorras) await _leer(m),
  ]);

  int objeto(String nombre) => nombresObjetos.indexOf(nombre);
  int suelo(String nombre) => nombresSuelo.indexOf(nombre);

  /// Salas a las que se llega por la puerta de una estructura con ese sprite,
  /// en orden. No incluye las que están bajo otra (se baja por una escalera).
  List<Sala> entradas(String estructura) => [
    for (final s in salas)
      if (s.estructura == estructura && arriba(s) == null) s,
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

/// Todas las salas interiores, de todos los archivos.
class Interiores {
  Interiores(this.mapas);

  final List<MapaInteriores> mapas;

  late final List<Sala> salas = [for (final m in mapas) ...m.salas];

  Sala? porSlug(String slug) => salas.where((s) => s.slug == slug).firstOrNull;

  MapaInteriores? mazmorra(String id) =>
      mapas.where((m) => m.id == id).firstOrNull;

  /// Salas a las que se llega por la puerta de una estructura con ese sprite.
  List<Sala> entradas(String estructura) => [
    for (final m in mapas) ...m.entradas(estructura),
  ];

  Sala? arriba(Sala sala) => sala.mapa.arriba(sala);
  Sala? abajo(Sala sala) => sala.mapa.abajo(sala);

  /// Las salas que siguen a [entrada] escalera abajo, empezando por ella.
  List<Sala> recorrido(Sala entrada) => [
    for (Sala? s = entrada;
        s != null;
        s = s.punto('bajada') == null ? null : abajo(s))
      s,
  ];
}
