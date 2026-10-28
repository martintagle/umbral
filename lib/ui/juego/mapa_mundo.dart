import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

typedef Estructura = ({
  String sprite,
  int x,
  int y,
  int w,
  int h,
  int huellaFilas,
  List<(int, int)> puerta,
});
typedef Letrero = ({int x, int y, String texto});
typedef EnemigoMapa = ({String tipo, int x, int y, int radio});
typedef Region = ({String nombre, int x, int y, int w, int h});

/// `assets/mapas/mundo.json` (ver `docs/diseno/mundo.md`). Las posiciones del
/// JSON están en tiles; las que devuelve esta clase, en píxeles de arte.
class MapaMundo {
  static const tile = 16.0;

  final int ancho;
  final int alto;
  final int columnasTileset;
  final int indiceObjetos;
  final int indiceEntidades;
  final List<String> nombresObjetos;
  final List<String> nombresEntidades;
  final List<List<int>> suelo;
  final List<List<int>> objetos;
  final List<Estructura> estructuras;
  final List<(int, int)> cofres;
  final List<Letrero> letreros;
  final List<(int, int)> portales;
  final List<EnemigoMapa> enemigos;
  final List<Region> regiones;
  final Vector2 inicio;

  /// Celdas que no se pueden pisar a tamaño normal: el jugador aún no puede
  /// encogerse ni tiene la Hoz o la Llave, así que todo lo cerrado bloquea.
  late final Uint8List _solido;

  /// Además de lo sólido, los enemigos no pisan los tocones con runas.
  late final Uint8List _solidoEnemigo;

  /// Los proyectiles vuelan sobre el agua, pero no atraviesan muros ni árboles.
  late final Uint8List _bloqueaProyectil;

  /// Objetos que tapan a quien pasa por detrás: se ordenan con los sprites.
  /// El resto (troncos, pasto alto, escombros...) se dibuja con el suelo.
  late final Set<int> objetosAltos;

  MapaMundo._(Map<String, dynamic> m)
    : ancho = m['ancho'] as int,
      alto = m['alto'] as int,
      columnasTileset = m['columnasTileset'] as int,
      indiceObjetos = m['tiles']['indiceObjetos'] as int,
      indiceEntidades = m['tiles']['indiceEntidades'] as int,
      nombresObjetos = List<String>.from(m['tiles']['objetos'] as List),
      nombresEntidades = List<String>.from(m['tiles']['entidades'] as List),
      suelo = _rejilla(m['capas']['suelo']),
      objetos = _rejilla(m['capas']['objetos']),
      estructuras = [
        for (final e in m['estructuras'] as List)
          (
            sprite: e['sprite'] as String,
            x: e['x'] as int,
            y: e['y'] as int,
            w: e['w'] as int,
            h: e['h'] as int,
            huellaFilas: e['huellaFilas'] as int,
            puerta: [
              for (final p in e['puerta'] as List) (p[0] as int, p[1] as int),
            ],
          ),
      ],
      cofres = _celdas(m['cofres']),
      letreros = [
        for (final l in m['letreros'] as List)
          (x: l['x'] as int, y: l['y'] as int, texto: l['texto'] as String),
      ],
      portales = _celdas(m['portales']),
      enemigos = [
        for (final e in m['enemigos'] as List)
          (
            tipo: e['tipo'] as String,
            x: e['x'] as int,
            y: e['y'] as int,
            radio: e['radio'] as int? ?? 2,
          ),
      ],
      regiones = [
        for (final z in m['zonas'] as List)
          (
            nombre: z['nombre'] as String,
            x: z['x'] as int,
            y: z['y'] as int,
            w: z['w'] as int,
            h: z['h'] as int,
          ),
      ],
      inicio = Vector2(
        (m['inicio']['x'] as num) * tile,
        (m['inicio']['y'] as num) * tile + 12,
      ) {
    final nombresSuelo = List<String>.from(m['tiles']['suelo'] as List);
    final reglas = m['reglas'] as Map<String, dynamic>;
    final sueloSolido = {
      for (final n in [
        ...reglas['sueloBloquea'] as List,
        ...reglas['sueloSoloDiminuto'] as List,
      ])
        nombresSuelo.indexOf(n as String),
    };
    final agua = nombresSuelo.indexOf('agua');
    objetosAltos = {
      for (final n in [
        ...reglas['objetosBloquean'] as List,
        ...(reglas['objetosConLlave'] as Map).keys,
      ])
        nombresObjetos.indexOf(n as String),
    };
    final portal = nombresObjetos.indexOf('portal');

    _solido = Uint8List(ancho * alto);
    _solidoEnemigo = Uint8List(ancho * alto);
    _bloqueaProyectil = Uint8List(ancho * alto);
    void marcar(int x, int y, {bool proyectil = true}) {
      _solido[y * ancho + x] = 1;
      _solidoEnemigo[y * ancho + x] = 1;
      if (proyectil) _bloqueaProyectil[y * ancho + x] = 1;
    }

    for (var y = 0; y < alto; y++) {
      for (var x = 0; x < ancho; x++) {
        final s = suelo[y][x], o = objetos[y][x];
        if (sueloSolido.contains(s) || objetosAltos.contains(o)) marcar(x, y);
        if (s == agua) marcar(x, y, proyectil: false);
        if (o == portal) _solidoEnemigo[y * ancho + x] = 1;
      }
    }
    for (final e in estructuras) {
      for (var y = e.y + e.h - e.huellaFilas; y < e.y + e.h; y++) {
        for (var x = e.x; x < e.x + e.w; x++) {
          if (!e.puerta.contains((x, y))) marcar(x, y);
        }
      }
    }
    for (final (x, y) in [...cofres, for (final l in letreros) (l.x, l.y)]) {
      marcar(x, y);
    }
  }

  static Future<MapaMundo> cargar() async => MapaMundo._(
    jsonDecode(await rootBundle.loadString('assets/mapas/mundo.json'))
        as Map<String, dynamic>,
  );

  static List<List<int>> _rejilla(Object? capa) => [
    for (final fila in capa as List) List<int>.from(fila as List),
  ];

  static List<(int, int)> _celdas(Object? lista) => [
    for (final c in lista as List) (c['x'] as int, c['y'] as int),
  ];

  double get anchoPx => ancho * tile;
  double get altoPx => alto * tile;

  /// Pies de algo que está en la celda (x, y): centrado y casi en el borde inferior.
  static Vector2 piesEnCelda(int x, int y) =>
      Vector2(x * tile + tile / 2, y * tile + tile - 2);

  bool solido(double x, double y) => _celda(_solido, x, y);
  bool solidoEnemigo(double x, double y) => _celda(_solidoEnemigo, x, y);
  bool bloqueaProyectil(double x, double y) => _celda(_bloqueaProyectil, x, y);

  bool _celda(Uint8List rejilla, double x, double y) {
    if (x < 0 || y < 0) return true;
    final tx = x ~/ tile, ty = y ~/ tile;
    if (tx >= ancho || ty >= alto) return true;
    return rejilla[ty * ancho + tx] == 1;
  }

  /// Nombre de la región en la que está [p], o el del mapa si no hay ninguna.
  String regionEn(Vector2 p) {
    final tx = p.x ~/ tile, ty = p.y ~/ tile;
    for (final r in regiones) {
      if (tx >= r.x && tx < r.x + r.w && ty >= r.y && ty < r.y + r.h) {
        return r.nombre;
      }
    }
    return 'Tierras del Umbral';
  }
}
