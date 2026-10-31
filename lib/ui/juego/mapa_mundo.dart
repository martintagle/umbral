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
typedef CofreMapa = ({String id, int x, int y, String contenido, String texto});

/// Borde por el que se pasa a otra zona. [rejas] son las de la salida, que
/// se abren al vencer al jefe de la zona.
typedef Paso = ({int x, int y, String zona, List<(int, int)> rejas});

/// La puerta de la mazmorra del jefe: [entrada] es el sprite de la
/// estructura y [mazmorra] el id de su JSON en `assets/interiores/`.
typedef JefeMapa = ({String tipo, String? mazmorra, String? entrada});

/// Una zona del mundo: `assets/mapas/mundo.json` (zona 1, ver
/// `docs/diseno/mundo.md`) o `zona-<n>-<id>.json` (zonas 2 a 6, ver
/// `docs/zonas.md`). Las posiciones del JSON están en tiles; las que devuelve
/// esta clase, en píxeles de arte.
class MapaMundo {
  static const tile = 16.0;

  /// Las zonas en el orden en que se recorren, con su archivo.
  static const _archivos = {
    'tierras-del-umbral': 'mundo.json',
    'cienaga': 'zona-2-cienaga.json',
    'minas': 'zona-3-minas.json',
    'abadia': 'zona-4-abadia.json',
    'paramo': 'zona-5-paramo.json',
    'umbral': 'zona-6-umbral.json',
  };
  static const primera = 'tierras-del-umbral';

  static bool existe(String zona) => _archivos.containsKey(zona);

  final String id;
  final int numero;
  final String nombre;

  /// Imagen del tileset, dentro de `assets/`.
  final String tileset;

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
  final List<CofreMapa> cofres;
  final List<Letrero> letreros;
  final List<(int, int)> portales;
  final List<EnemigoMapa> enemigos;
  final List<Region> regiones;
  final Vector2 inicio;

  /// Por dónde se llega desde la zona anterior y por dónde se sale a la
  /// siguiente. La zona 1 no tiene ninguno: se sale por la cripta.
  final Paso? entrada;
  final Paso? salida;
  final JefeMapa? jefe;

  /// Las criaturas de la zona; las tres primeras vienen de la anterior y aquí
  /// son las débiles.
  final List<String> enemigosDeLaZona;

  /// Cofres, letreros y estructuras: no cambian al abrir rejas o cortar
  /// zarzas.
  late final Uint8List _fijo;
  late final Set<int> _sueloSolido;
  late final int _agua;
  late final int _portal;

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
    : id = m['id'] as String? ?? primera,
      numero = m['numero'] as int? ?? 1,
      nombre = m['nombre'] as String,
      tileset = (m['tileset'] as String).replaceFirst('../', ''),
      ancho = m['ancho'] as int,
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
      cofres = [
        for (final c in m['cofres'] as List)
          (
            id: c['id'] as String,
            x: c['x'] as int,
            y: c['y'] as int,
            contenido: c['contenido'] as String,
            texto: c['texto'] as String,
          ),
      ],
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
      ),
      entrada = _paso(m['entrada'], 'desde'),
      salida = _paso(m['salida'], 'hacia'),
      jefe = switch (m['jefe']) {
        final Map<String, dynamic> j => (
          tipo: j['tipo'] as String,
          mazmorra: j['mazmorra'] as String?,
          entrada: j['entrada'] as String?,
        ),
        _ => null,
      },
      enemigosDeLaZona = List<String>.from(
        m['enemigosDeLaZona'] as List? ?? const [],
      ) {
    final nombresSuelo = List<String>.from(m['tiles']['suelo'] as List);
    final reglas = m['reglas'] as Map<String, dynamic>;
    _sueloSolido = {
      for (final n in [
        ...reglas['sueloBloquea'] as List,
        ...reglas['sueloSoloDiminuto'] as List,
      ])
        nombresSuelo.indexOf(n as String),
    };
    _agua = nombresSuelo.indexOf('agua');
    objetosAltos = {
      for (final n in [
        ...reglas['objetosBloquean'] as List,
        ...(reglas['objetosConLlave'] as Map).keys,
      ])
        nombresObjetos.indexOf(n as String),
    };
    _portal = nombresObjetos.indexOf('portal');

    _solido = Uint8List(ancho * alto);
    _solidoEnemigo = Uint8List(ancho * alto);
    _bloqueaProyectil = Uint8List(ancho * alto);
    _fijo = Uint8List(ancho * alto);
    for (final e in estructuras) {
      for (var y = e.y + e.h - e.huellaFilas; y < e.y + e.h; y++) {
        for (var x = e.x; x < e.x + e.w; x++) {
          if (!e.puerta.contains((x, y))) _fijo[y * ancho + x] = 1;
        }
      }
    }
    for (final (x, y) in [
      for (final c in cofres) (c.x, c.y),
      for (final l in letreros) (l.x, l.y),
    ]) {
      _fijo[y * ancho + x] = 1;
    }
    for (var y = 0; y < alto; y++) {
      for (var x = 0; x < ancho; x++) {
        _calcular(x, y);
      }
    }
  }

  /// Qué bloquea la celda (x, y) según su suelo, su objeto y lo fijo.
  void _calcular(int x, int y) {
    final i = y * ancho + x;
    final s = suelo[y][x], o = objetos[y][x];
    final bloquea =
        _fijo[i] == 1 || _sueloSolido.contains(s) || objetosAltos.contains(o);
    _solido[i] = bloquea || s == _agua ? 1 : 0;
    _solidoEnemigo[i] = _solido[i] == 1 || o == _portal ? 1 : 0;
    // Los proyectiles vuelan sobre el agua.
    _bloqueaProyectil[i] = bloquea ? 1 : 0;
  }

  /// Índice del objeto [nombre] en la capa de objetos, o -1.
  int objeto(String nombre) => nombresObjetos.indexOf(nombre);

  /// Cambia el objeto de la celda (x, y), por ejemplo una reja por la reja
  /// abierta, y recalcula qué bloquea.
  void cambiarObjeto(int x, int y, int objeto) {
    objetos[y][x] = objeto;
    _calcular(x, y);
  }

  static Future<MapaMundo> cargar([String zona = primera]) async => MapaMundo._(
    jsonDecode(
          await rootBundle.loadString(
            'assets/mapas/${_archivos[zona] ?? _archivos[primera]}',
          ),
        )
        as Map<String, dynamic>,
  );

  static Paso? _paso(Object? datos, String campo) => switch (datos) {
    final Map<String, dynamic> d => (
      x: d['x'] as int,
      y: d['y'] as int,
      zona: d[campo] as String,
      rejas: [
        for (final r in d['rejaSalida'] as List? ?? const [])
          (r[0] as int, r[1] as int),
      ],
    ),
    _ => null,
  };

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
    return nombre;
  }

  /// Centro de la celda (x, y).
  static Vector2 centroDe(int x, int y) =>
      Vector2((x + 0.5) * tile, (y + 0.5) * tile);
}
