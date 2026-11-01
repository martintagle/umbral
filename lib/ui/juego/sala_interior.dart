import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';

import '../sonido.dart';
import '../tema/tema_umbral.dart';
import 'efectos.dart';
import 'enemigo.dart';
import 'escenario.dart';
import 'iluminacion.dart';
import 'mapa_interiores.dart';
import 'oreste.dart';
import 'tipos_enemigo.dart';
import 'umbral_juego.dart';

const _lado = 16.0;

/// Una sala interior (`docs/diseno/interiores.md`). Se crea una vez por sala y
/// se conserva: lo abierto sigue abierto hasta descansar.
class SalaInterior extends Escenario {
  SalaInterior(this.sala) : mapa = sala.mapa {
    _solido = Uint8List(sala.ancho * sala.alto);
    for (var y = 0; y < sala.alto; y++) {
      for (var x = 0; x < sala.ancho; x++) {
        final o = sala.objetos[y][x];
        if (mapa.sueloBloquea.contains(sala.suelo[y][x]) ||
            (o >= 0 && !mapa.objetosTransitables.contains(o))) {
          _solido[y * sala.ancho + x] = 1;
        }
      }
    }
  }

  final MapaInteriores mapa;
  final Sala sala;
  late final Uint8List _solido;
  final Set<PuntoSala> _abiertos = {};
  NieblaSello? _niebla;
  double _avisoSello = 0;

  static const _distanciaInteraccion = 22.0;

  @override
  bool pisaPiedra(Vector2 pies) => true;

  /// La cripta y las mazmorras suenan a criaturas que se arrastran en la
  /// oscuridad.
  @override
  String? get pista =>
      sala.estructura == 'entrada-de-cripta' || mapa.zona != null
          ? Audios.ambienteCripta
          : null;

  /// El custodio del punto `jefe`: el de la mazmorra o, en la cripta, el Rey
  /// Hueco.
  TipoEnemigo get tipoJefe =>
      Enemigos.porId(mapa.jefe ?? '') ?? Enemigos.reyHueco;

  /// La fogata de la sala del custodio aparece al vencerlo; las demás están
  /// siempre.
  bool get fogataVisible =>
      sala.punto('jefe') == null || game.jefesDerrotados.contains(tipoJefe.id);

  /// El jefe de esta sala, si está despierto y en pie: sella la salida.
  bool get _sellada {
    final jefe = game.jefe.value;
    return jefe != null && identical(jefe.parent, this) && jefe.despierto;
  }

  @override
  Rect get limites =>
      Rect.fromLTWH(0, 0, sala.ancho * _lado, sala.alto * _lado);

  @override
  String regionEn(Vector2 pies) => sala.nombre;

  @override
  Future<void> onLoad() async {
    final tileset = game.images.fromCache('interiores/${mapa.tileset}');
    final hoguera = sala.punto('hoguera');
    add(_SueloSala(mapa, sala, tileset));
    for (var y = 0; y < sala.alto; y++) {
      add(_FilaSala(mapa, sala, tileset, y, sinDibujar: hoguera));
    }

    final iluminacion = Iluminacion(oscuridad: 0.88);
    if (hoguera != null) {
      final fogata = _Fogata(this, tileset, hoguera);
      add(fogata);
      iluminacion.fijas.add(fogata.luz);
    }
    void luz(int x, int y, double radio, Color? tinte, {double alto = 4}) =>
        iluminacion.fijas.add(
          Luz(
            Vector2((x + 0.5) * _lado, (y + 0.5) * _lado - alto),
            radio: radio,
            tinte: tinte,
            parpadeo: tinte == Colores.brasa ? 2 : 0,
          ),
        );
    final candelabro = mapa.objeto('candelabro'),
        forja = mapa.objeto('forja'),
        altar = mapa.objeto('altar-brasas'),
        altarCapilla = mapa.objeto('altar-capilla'),
        vitral = mapa.objeto('vitral'),
        velas = mapa.objeto('velas'),
        brasero = mapa.objeto('brasero'),
        cristal = mapa.objeto('cristal'),
        ojo = mapa.objeto('ojo'),
        salida = mapa.suelo('umbral-salida');
    for (var y = 0; y < sala.alto; y++) {
      for (var x = 0; x < sala.ancho; x++) {
        if (sala.suelo[y][x] == salida) luz(x, y, 22, null, alto: 0);
        // Una celda vacía vale -1, igual que un objeto que el tileset no
        // tiene: sin este corte, cada hueco de la sala sería una luz.
        final o = sala.objetos[y][x];
        if (o < 0 || (hoguera?.x == x && hoguera?.y == y)) continue;
        if (o == candelabro) luz(x, y, 34, Colores.brasa);
        if (o == forja) luz(x, y, 46, Colores.brasa);
        if (o == altar) luz(x, y, 42, Colores.brasa);
        if (o == altarCapilla) luz(x, y, 26, Colores.brasa);
        if (o == vitral) luz(x, y, 22, Colores.alma);
        if (o == velas) luz(x, y, 30, Colores.brasa);
        if (o == brasero) luz(x, y, 40, Colores.brasa);
        if (o == cristal) luz(x, y, 20, Colores.alma);
        if (o == ojo) luz(x, y, 14, Colores.sangre);
      }
    }
    add(iluminacion);
    reiniciarEnemigos();
    ponerOreste();
  }

  Oreste? _oreste;

  @override
  Oreste? get oreste => switch (_oreste) {
    final o? when !o.isRemoved && !o.desvaneciendose => o,
    _ => null,
  };

  /// Pone a Oreste si esta sala es su refugio en la zona actual y aún tiene
  /// algo que hacer en ella; si no, lo quita. Las salas comunes (la capilla,
  /// la herrería, el refugio) sirven a varias zonas: se llama al entrar.
  void ponerOreste() {
    final zona = game.tierras.mapa.numero;
    final refugio = game.datosOreste.refugios[zona];
    final toca = refugio != null &&
        refugio.sala == sala.slug &&
        game.oresteEnZona(zona);
    final actual = oreste;
    if (toca && actual == null) {
      add(_oreste = Oreste(piesEn(refugio.x, refugio.y)));
    } else if (!toca && actual != null) {
      actual.removeFromParent();
      _oreste = null;
    }
  }

  @override
  bool libre(Rect pies, {bool enemigo = false}) {
    for (final esquina in [
      pies.topLeft,
      pies.topRight,
      pies.bottomLeft,
      pies.bottomRight,
    ]) {
      if (bloquea(esquina.dx, esquina.dy)) return false;
    }
    return true;
  }

  @override
  bool bloquea(double x, double y) {
    if (x < 0 || y < 0) return true;
    final tx = x ~/ _lado, ty = y ~/ _lado;
    if (tx >= sala.ancho || ty >= sala.alto) return true;
    return _solido[ty * sala.ancho + tx] == 1;
  }

  @override
  void reiniciarEnemigos() {
    _abiertos.clear();
    for (final e in children.whereType<Enemigo>().toList()) {
      e.removeFromParent();
    }
    for (final c in children.whereType<Proyectil>().toList()) {
      c.removeFromParent();
    }
    // Con el nivel, los puntos de criaturas débiles y medias traen compañía en
    // las celdas libres de al lado.
    final fuerza = game.fuerzaEnemigos;
    for (final (i, p) in sala.puntos.indexed) {
      if (p.tipo != 'enemigo') continue;
      if (Enemigos.porId(p.texto) case final tipo?) {
        // Las que cayeron desde el último descanso no vuelven.
        final origen = '${sala.slug}#$i';
        final n = game.criaturasPorPuntoDeSala(tipo.id) - game.caidosEn(origen);
        final celdas = [
          for (final (dx, dy) in const [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)])
            if (_cabe(piesEn(p.x + dx, p.y + dy))) piesEn(p.x + dx, p.y + dy),
        ];
        for (final pies in celdas.take(max(0, n))) {
          add(Enemigo(tipo, pies, fuerza: fuerza, origen: origen));
        }
      }
    }
    // El custodio espera en su sitio, si aún no ha caído. Crece la mitad que
    // el resto: ya cuesta bastante vencerlo.
    if (sala.punto('jefe') case final p?
        when !game.jefesDerrotados.contains(tipoJefe.id)) {
      add(Enemigo(tipoJefe, piesEn(p.x, p.y), fuerza: 1 + (fuerza - 1) / 2));
    }
  }

  bool _cabe(Vector2 pies) => libre(
      Rect.fromCenter(center: Offset(pies.x, pies.y - 1.5), width: 8, height: 3));

  @override
  void update(double dt) {
    super.update(dt);
    _avisoSello = (_avisoSello - dt).clamp(0, 10);
    // La niebla aparece sobre la salida mientras dura el combate.
    final sellada = _sellada;
    if (sellada && _niebla == null) {
      final p = sala.punto('salida')!;
      final (desde, hasta) = _tramo(p);
      add(_niebla = NieblaSello(Rect.fromLTWH(desde * _lado, (p.y - 0.5) * _lado,
          (hasta - desde + 1) * _lado, _lado * 1.5)));
    } else if (!sellada && _niebla != null) {
      _niebla!.removeFromParent();
      _niebla = null;
    }
  }

  /// Pies de alguien de pie junto al punto [tipo] (debajo, si cabe).
  Vector2 junto(String tipo) {
    final p = sala.punto(tipo)!;
    for (final (dx, dy) in const [(0, 1), (-1, 1), (1, 1), (-1, 0), (1, 0)]) {
      final pies = piesEn(p.x + dx, p.y + dy);
      if (libre(Rect.fromCenter(
          center: Offset(pies.x, pies.y - 1.5), width: 8, height: 3))) {
        return pies;
      }
    }
    return llegada('salida');
  }

  /// Pies de alguien de pie en la celda (x, y).
  static Vector2 piesEn(int x, int y) =>
      Vector2((x + 0.5) * _lado, (y + 1) * _lado - 3);

  /// Dónde aparece el jugador al llegar por el punto [tipo] (`salida` o
  /// `bajada`): en la fila contigua, del lado de dentro de la sala.
  Vector2 llegada(String tipo) {
    final p = sala.punto(tipo)!;
    final (desde, hasta) = _tramo(p);
    final fila = p.y >= sala.alto - 1 ? p.y - 1 : p.y + 1;
    return Vector2((desde + hasta + 1) / 2 * _lado, (fila + 1) * _lado - 3);
  }

  /// Celdas contiguas de la fila de [p] con el mismo suelo: una salida o una
  /// escalera pueden medir dos tiles.
  (int, int) _tramo(PuntoSala p) {
    final tile = sala.suelo[p.y][p.x];
    var desde = p.x, hasta = p.x;
    while (desde > 0 && sala.suelo[p.y][desde - 1] == tile) {
      desde--;
    }
    while (hasta < sala.ancho - 1 && sala.suelo[p.y][hasta + 1] == tile) {
      hasta++;
    }
    return (desde, hasta);
  }

  @override
  void pisando(Vector2 pies) {
    final tx = pies.x ~/ _lado, ty = (pies.y - 1) ~/ _lado;
    for (final p in sala.puntos) {
      if (p.tipo != 'salida' && p.tipo != 'bajada') continue;
      final (desde, hasta) = _tramo(p);
      if (ty == p.y && tx >= desde && tx <= hasta) {
        if (p.tipo == 'salida' && _sellada) {
          if (_avisoSello == 0) {
            _avisoSello = 3;
            game.mostrarAviso('Una niebla de ceniza sella la salida.');
          }
          return;
        }
        game.cruzar(this, p.tipo);
        return;
      }
    }
  }

  @override
  List<AccionContexto> accionesEn(Vector2 pies) {
    // Vencido el Rey Hueco, tras el trono baja un pasadizo hacia la ciénaga.
    final pasadizo = switch (sala.punto('jefe')) {
      final j?
          when mapa.zona == null &&
              game.jefesDerrotados.contains(tipoJefe.id) &&
              piesEn(j.x, j.y).distanceTo(pies) < 32 =>
        AccionContexto('Bajar por el pasadizo', game.bajarPorElPasadizo),
      _ => null,
    };
    // Junto a Oreste se le habla, además de lo que haya a mano.
    if (oreste case final o? when o.position.distanceTo(pies) < 24) {
      return [
        AccionContexto('Hablar', game.hablarConOreste, boton: 'hablar'),
        ..._accionesDelLugar(pies, pasadizo),
      ];
    }
    return _accionesDelLugar(pies, pasadizo);
  }

  /// Lo que hay a mano en la sala. Si la hoguera del custodio está cerca, el
  /// [pasadizo] va dentro de su menú en lugar de alternarse con ella.
  List<AccionContexto> _accionesDelLugar(
    Vector2 pies, [
    AccionContexto? pasadizo,
  ]) {
    PuntoSala? cerca;
    var mejor = _distanciaInteraccion;
    for (final p in sala.puntos) {
      if (p.tipo == 'enemigo' || p.tipo == 'jefe') continue;
      if (p.tipo == 'hoguera' && !fogataVisible) continue;
      final d = Vector2(
        (p.x + 0.5) * _lado,
        (p.y + 0.5) * _lado,
      ).distanceTo(pies);
      if (d < mejor) {
        mejor = d;
        cerca = p;
      }
    }
    if (pasadizo != null && cerca?.tipo != 'hoguera') return [pasadizo];
    return switch (cerca?.tipo) {
      'herreria' => [
        AccionContexto(
          'Usar el yunque',
          () => game.abrirPantalla(PantallaJuego.herreria),
          boton: 'yunque',
        ),
      ],
      'estadisticas' => [game.accionSubirNivel()],
      'hoguera' => game.accionesFogata(
        UmbralJuego.fogataSala(sala),
        donde: Vector2((cerca!.x + 0.5) * _lado, (cerca.y + 0.5) * _lado - 6),
        descansar: () => game.descansar(enSala: this),
        ademas: [
          ?pasadizo,
          if (sala.punto('jefe') != null)
            AccionContexto(
              'Salir de la mazmorra',
              game.salirDeLaMazmorra,
            ),
        ],
      ),
      'cofre' => [
        AccionContexto(
          _abiertos.contains(cerca) ? 'Cofre vacío' : 'Abrir el cofre',
          () => _abrirCofre(cerca!),
          boton: 'abrir',
        ),
      ],
      'secreto' => [
        AccionContexto(
          'Examinar',
          () => game.mostrarAviso('La trampilla está atrancada desde abajo.'),
          boton: 'leer',
        ),
      ],
      'subida' => [
        AccionContexto(
          'Subir',
          () => game.mostrarAviso(
            'La escalera al mirador se derrumbó a mitad de camino.',
          ),
        ),
      ],
      _ => const [],
    };
  }

  void _abrirCofre(PuntoSala p) {
    if (_abiertos.contains(p)) {
      game.mostrarAviso('Ya no queda nada. Vuelve después de descansar.');
      return;
    }
    _abiertos.add(p);
    // No hay objetos que llevarse: el arma es lo único que se porta.
    if (sala.slug == 'choza-en-ruinas') {
      game.curar('Bebes las pociones del cofre. Tu vida se renueva.');
    } else if (sala.slug == 'cripta-osario') {
      game.rellenarFrascos(
          'Un frasco de brasas a medio llenar. Tus frascos y tu vida se renuevan.');
    } else if (mapa.zona != null) {
      // En las mazmorras, lo que guarda el cofre arde como un frasco. El texto
      // entre paréntesis es una nota de diseño: no se muestra.
      final hallazgo = p.texto.replaceAll(RegExp(r'\s*\(.*\)'), '');
      game.rellenarFrascos('$hallazgo. Tus frascos y tu vida se renuevan.');
    } else {
      game.mostrarAviso('El cofre está vacío. Alguien llegó antes.');
    }
  }
}

/// Suelo, muros y objetos de paso, dibujados una vez en una imagen.
class _SueloSala extends PositionComponent {
  _SueloSala(MapaInteriores mapa, Sala sala, Image tileset)
    : super(priority: -1 << 20) {
    final grabadora = PictureRecorder();
    final canvas = Canvas(grabadora);
    for (var y = 0; y < sala.alto; y++) {
      for (var x = 0; x < sala.ancho; x++) {
        _tile(canvas, tileset, mapa, sala.suelo[y][x], x, y);
        final o = sala.objetos[y][x];
        if (o >= 0 && mapa.objetosTransitables.contains(o)) {
          _tile(canvas, tileset, mapa, mapa.indiceObjetos + o, x, y);
        }
      }
    }
    _imagen = grabadora.endRecording().toImageSync(
      (sala.ancho * _lado).toInt(),
      (sala.alto * _lado).toInt(),
    );
  }

  late final Image _imagen;

  @override
  void render(Canvas canvas) =>
      canvas.drawImage(_imagen, Offset.zero, _pintura);
}

/// Muebles de una fila: se ordenan con los sprites según su base.
/// La celda [sinDibujar] (la hoguera) la dibuja [_Fogata].
class _FilaSala extends PositionComponent {
  _FilaSala(
    this._mapa,
    Sala sala,
    this._tileset,
    this._fila, {
    PuntoSala? sinDibujar,
  }) : super(priority: ((_fila + 1) * _lado).round()) {
    for (var x = 0; x < sala.ancho; x++) {
      if (sinDibujar?.x == x && sinDibujar?.y == _fila) continue;
      final o = sala.objetos[_fila][x];
      if (o >= 0 && !_mapa.objetosTransitables.contains(o)) {
        _celdas.add((x, _mapa.indiceObjetos + o));
      }
    }
  }

  final MapaInteriores _mapa;
  final Image _tileset;
  final int _fila;
  final List<(int, int)> _celdas = [];

  @override
  void render(Canvas canvas) {
    for (final (x, cuadro) in _celdas) {
      _tile(canvas, _tileset, _mapa, cuadro, x, _fila);
    }
  }
}

/// El altar de brasas de la hoguera: gris y sin luz hasta encenderlo. En la
/// sala del custodio no está hasta vencerlo.
class _Fogata extends PositionComponent {
  _Fogata(this._sala, this._tileset, this._punto)
    : luz = Luz(
        Vector2((_punto.x + 0.5) * _lado, (_punto.y + 0.5) * _lado - 4),
        radio: 42,
        tinte: Colores.brasa,
        parpadeo: 2,
      ),
      super(priority: ((_punto.y + 1) * _lado).round());

  final SalaInterior _sala;
  final Image _tileset;
  final PuntoSala _punto;
  final Luz luz;
  final _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void update(double dt) {
    luz.encendida = _sala.fogataVisible &&
        _sala.game.fogataEncendida(UmbralJuego.fogataSala(_sala.sala));
    _paint.colorFilter = luz.encendida ? null : filtroApagada;
  }

  @override
  void render(Canvas canvas) {
    final altar = _sala.mapa.objeto('altar-brasas');
    if (!_sala.fogataVisible || altar < 0) return;
    _tile(
      canvas,
      _tileset,
      _sala.mapa,
      _sala.mapa.indiceObjetos + altar,
      _punto.x,
      _punto.y,
      _paint,
    );
  }
}

final _pintura = Paint()
  ..filterQuality = FilterQuality.none
  ..isAntiAlias = false;

void _tile(
  Canvas canvas,
  Image tileset,
  MapaInteriores mapa,
  int cuadro,
  int x,
  int y, [
  Paint? pintura,
]) {
  final columnas = mapa.columnasTileset;
  canvas.drawImageRect(
    tileset,
    Rect.fromLTWH(
      (cuadro % columnas) * _lado,
      (cuadro ~/ columnas) * _lado,
      _lado,
      _lado,
    ),
    Rect.fromLTWH(x * _lado, y * _lado, _lado, _lado),
    pintura ?? _pintura,
  );
}
