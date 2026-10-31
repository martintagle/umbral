import 'package:flutter_test/flutter_test.dart';
import 'package:umbral/api/actualizacion_api.dart';
import 'package:umbral/api/almacen_local.dart';
import 'package:umbral/api/progreso_pendiente.dart';
import 'package:umbral/contrato/actualizacion.dart';
import 'package:umbral/contrato/partida_jugable.dart';

Map<String, dynamic> _progreso({
  required Map<String, int> enemigos,
  required int exp,
  int muertes = 0,
  int segundos = 60,
  int vida = 100,
  int x = 0,
}) => {
  'enemigosDerrotados': enemigos,
  'exp': exp,
  'oro': exp ~/ 2,
  'muertes': muertes,
  'segundosJugados': segundos,
  'vidaActual': vida,
  'ubicacion': {
    'zonaId': 'tierras',
    'x': x,
    'y': 0,
    'ultimoPuntoGuardado': null,
  },
};

Map<String, dynamic> _partida() => {
  'partida': {
    'partidaId': 'p1',
    'creadaEn': '2026-10-25T00:00:00.000Z',
    'ultimaVezJugada': '2026-10-25T00:00:00.000Z',
    'personaje': {
      'nombre': 'Prueba',
      'claseCodigo': 'vagabundo',
      'apariencia': 'mujer',
      'nivel': 10,
      'exp': 100,
      'puntosLibres': 0,
      'oro': 50,
      'atributos': {'vida': 4, 'fuerza': 3, 'destreza': 5, 'inteligencia': 1},
      'vidaActual': 128,
      'estaminaActual': 100,
      'equipo': {'nivelArma': 1, 'nivelArmadura': 1},
      'ubicacion': {
        'zonaId': 'tierras',
        'x': 0,
        'y': 0,
        'ultimoPuntoGuardado': null,
      },
      'mundo': {
        'zonasDesbloqueadas': <String>[],
        'cofresAbiertos': <String>[],
        'jefesDerrotados': <String>[],
      },
      'estadisticas': {
        'enemigosDerrotados': 3,
        'muertes': 1,
        'tiempoJugadoSeg': 600,
      },
    },
  },
  'combate': {
    'vidaMaxima': 128,
    'expSiguiente': 60,
    'dano': 16,
    'defensa': 2,
    'probabilidadCritico': 0.1,
    'multiplicadorCritico': 1.5,
    'mejoraArma': {'costo': 300, 'valorSiguiente': 19},
    'mejoraArmadura': {'costo': 300, 'valorSiguiente': 4},
  },
};

void main() {
  test('los progresos sin enviar se suman en uno', () {
    final total = sumarProgresos(
      _progreso(enemigos: {'fauce': 1, 'manojo': 2}, exp: 80, muertes: 1),
      _progreso(
        enemigos: {'manojo': 1, 'ojo-errante': 3},
        exp: 40,
        segundos: 30,
        vida: 70,
        x: 5,
      ),
    );
    expect(total['enemigosDerrotados'], {
      'fauce': 1,
      'manojo': 3,
      'ojo-errante': 3,
    });
    expect(total['exp'], 120);
    expect(total['oro'], 60);
    expect(total['muertes'], 1);
    expect(total['segundosJugados'], 90);
    // La vida y el sitio son los del último guardado.
    expect(total['vidaActual'], 70);
    expect((total['ubicacion'] as Map)['x'], 5);
  });

  test('sin conexión se ve la partida con su progreso pendiente', () {
    final local = PartidaJugable.fromMap(
      partidaConProgreso(
        _partida(),
        _progreso(
          enemigos: {'jefe-rey-hueco': 1, 'fauce': 2},
          exp: 400,
          muertes: 2,
          segundos: 120,
          vida: 90,
          x: 7,
        ),
        {'jefe-rey-hueco'},
      ),
    );
    final p = local.partida.personaje;
    expect(p.exp, 500);
    expect(p.oro, 250);
    expect(p.vidaActual, 90);
    expect(p.ubicacion.x, 7);
    expect(p.mundo.jefesDerrotados, ['jefe-rey-hueco']);
    expect(p.estadisticas.enemigosDerrotados, 6);
    expect(p.estadisticas.muertes, 3);
    expect(p.estadisticas.tiempoJugadoSeg, 720);
    // El nivel y el combate no cambian: subirlos es cosa del servidor.
    expect(p.nivel, 10);
    expect(local.combate.dano, 16);
  });

  test('sin base SQLite, el teléfono lo recuerda en memoria', () async {
    await AlmacenLocal.guardar('partidas:u1', [_partida()]);
    expect(await AlmacenLocal.leer('partidas:u1'), [_partida()]);

    final progreso = _progreso(enemigos: {'fauce': 1}, exp: 30);
    await AlmacenLocal.guardarPendiente('u1', 'p1', progreso);
    expect(await AlmacenLocal.pendientes('u1'), {'p1': progreso});
    expect(await AlmacenLocal.pendientes('u2'), isEmpty);
    await AlmacenLocal.borrarPendiente('u1', 'p1');
    expect(await AlmacenLocal.pendientes('u1'), isEmpty);

    await AlmacenLocal.guardarPendiente('u1', 'p1', progreso);
    await AlmacenLocal.olvidarUsuario('u1', 'partidas:u1');
    expect(await AlmacenLocal.pendientes('u1'), isEmpty);
    expect(await AlmacenLocal.leer('partidas:u1'), isNull);
  });

  test('compara versiones número a número', () {
    expect(ActualizacionApi.esMasNueva('0.1.7', '0.1.6'), isTrue);
    expect(ActualizacionApi.esMasNueva('0.2.0', '0.1.10'), isTrue);
    expect(ActualizacionApi.esMasNueva('0.1.10', '0.1.9'), isTrue);
    expect(ActualizacionApi.esMasNueva('1.0', '0.9.9'), isTrue);
    expect(ActualizacionApi.esMasNueva('0.1.6', '0.1.6'), isFalse);
    expect(ActualizacionApi.esMasNueva('0.1.6', '0.1.6+7'), isFalse);
    expect(ActualizacionApi.esMasNueva('0.1.5', '0.1.6'), isFalse);
  });

  test('lee la versión y el APK de la Release de GitHub', () {
    final nueva = Actualizacion.fromMap({
      'tag_name': 'v0.1.7-beta',
      'html_url': 'https://github.com/martintagle/umbral/releases/tag/v0.1.7-beta',
      'assets': [
        {
          'name': 'umbral.apk',
          'browser_download_url':
              'https://github.com/martintagle/umbral/releases/download/v0.1.7-beta/umbral.apk',
        },
      ],
    });
    expect(nueva.version, '0.1.7');
    expect(nueva.url, endsWith('/umbral.apk'));

    // Sin APK, la página de la Release.
    final sinApk = Actualizacion.fromMap({
      'tag_name': 'v0.2.0',
      'html_url': 'https://github.com/martintagle/umbral/releases/tag/v0.2.0',
      'assets': <Map<String, dynamic>>[],
    });
    expect(sinApk.version, '0.2.0');
    expect(sinApk.url, contains('/releases/tag/'));
  });
}
