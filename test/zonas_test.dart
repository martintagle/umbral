// ignore_for_file: invalid_use_of_internal_member
import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umbral/contrato/partida_jugable.dart';
import 'package:umbral/contrato/recompensa.dart';
import 'package:umbral/ui/juego/animacion.dart';
import 'package:umbral/ui/juego/enemigo.dart';
import 'package:umbral/ui/juego/mapa_interiores.dart';
import 'package:umbral/ui/juego/mapa_mundo.dart';
import 'package:umbral/ui/juego/sala_interior.dart';
import 'package:umbral/ui/juego/tipos_enemigo.dart';
import 'package:umbral/ui/juego/umbral_juego.dart';
import 'package:umbral/ui/juego/zona_tierras.dart';

const _zonas = [
  'tierras-del-umbral',
  'cienaga',
  'minas',
  'abadia',
  'paramo',
  'umbral',
];

PartidaJugable _partida({
  String zonaId = 'cienaga',
  List<String> jefes = const [],
}) => PartidaJugable.fromMap({
  'partida': {
    'partidaId': 'p1',
    'creadaEn': '2026-10-25T00:00:00Z',
    'ultimaVezJugada': '2026-10-25T00:00:00Z',
    'personaje': {
      'nombre': 'Prueba',
      'claseCodigo': 'guerrero',
      'apariencia': 'hombre',
      'nivel': 30,
      'exp': 0,
      'puntosLibres': 0,
      'oro': 0,
      'atributos': {'vida': 20, 'fuerza': 10, 'destreza': 2, 'inteligencia': 1},
      'vidaActual': 320,
      'estaminaActual': 100,
      'equipo': {'nivelArma': 3, 'nivelArmadura': 3},
      'ubicacion': {
        'zonaId': zonaId,
        'x': 0,
        'y': 0,
        'ultimoPuntoGuardado': null,
      },
      'mundo': {
        'zonasDesbloqueadas': <String>[],
        'cofresAbiertos': <String>[],
        'jefesDerrotados': jefes,
      },
      'estadisticas': {
        'enemigosDerrotados': 0,
        'muertes': 0,
        'tiempoJugadoSeg': 0,
      },
    },
  },
  'combate': {
    'vidaMaxima': 320,
    'expSiguiente': 60,
    'dano': 30,
    'defensa': 6,
    'probabilidadCritico': 0.1,
    'multiplicadorCritico': 1.5,
    'mejoraArma': {'costo': 320, 'valorSiguiente': 33},
    'mejoraArmadura': {'costo': 320, 'valorSiguiente': 8},
  },
});

UmbralJuego _juego(PartidaJugable partida) => UmbralJuego(
  partida: partida,
  recompensas: {
    for (final e in [...Enemigos.todos, ...Enemigos.jefes])
      e.id: Recompensa(
        id: e.id,
        categoria: e.jefe ? Categoria.jefe : Categoria.media,
        expMin: 1,
        expMax: 1,
        oroMin: 1,
        oroMax: 1,
      ),
  },
  alGuardar: (_, _) async => partida,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cada zona y su mazmorra traen criaturas que el juego conoce', () async {
    final hojas =
        jsonDecode(
              await rootBundle.loadString(
                'assets/sprites/animaciones/hojas.json',
              ),
            )
            as Map<String, dynamic>;
    final conHoja = (hojas['enemigos'] as Map).keys.toSet();
    for (final t in [...Enemigos.todos, ...Enemigos.jefes]) {
      expect(conHoja, contains(t.id));
    }

    final interiores = await MapaInteriores.cargar();
    for (final id in _zonas) {
      final mapa = await MapaMundo.cargar(id);
      expect(mapa.id, id);
      for (final e in mapa.enemigos) {
        expect(Enemigos.porId(e.tipo), isNotNull, reason: '${e.tipo} en $id');
      }
      for (final t in mapa.enemigosDeLaZona) {
        expect(Enemigos.porId(t), isNotNull, reason: '$t en $id');
      }
      if (mapa.jefe case final j?) {
        expect(Enemigos.porId(j.tipo)?.jefe, isTrue);
        if (j.mazmorra case final m?) {
          final mazmorra = interiores.mazmorra(m)!;
          expect(mazmorra.jefe, j.tipo);
          expect(mazmorra.entradas(j.entrada!), isNotEmpty);
        }
      }
    }
    for (final s in interiores.salas) {
      for (final p in s.puntos.where((p) => p.tipo == 'enemigo')) {
        expect(Enemigos.porId(p.texto), isNotNull, reason: '${p.texto} en ${s.slug}');
      }
    }
  });

  testWidgets('llave, mazmorra, jefe, salida y vuelta atrás', (tester) async {
    await tester.runAsync(() async {
      final juego = _juego(_partida());
      Future<void> correr(double segundos) async {
        for (var t = 0.0; t < segundos; t += 1 / 60) {
          juego.update(1 / 60);
          await juego.ready();
          final grabadora = PictureRecorder();
          juego.render(Canvas(grabadora));
          grabadora.endRecording().dispose();
        }
      }

      juego.onGameResize(Vector2(844, 390));
      await juego.load();
      juego.mount();
      await juego.ready();
      await correr(0.1);

      final cienaga = juego.tierras;
      expect(cienaga.zonaId, 'cienaga');
      expect(juego.world, cienaga);
      expect(juego.jugador.position, cienaga.inicio);
      expect(cienaga.altares, hasLength(2));
      expect(juego.minimapa.value?.ruta, contains('minimapa-zona-2'));
      final mapa = cienaga.mapa;
      final reja = mapa.objeto('reja'), abierta = mapa.objeto('reja-abierta');
      expect(mapa.objetos[19][61], reja);

      // El cofre de la llave abre la reja de la arena, no la de la salida.
      final llave = mapa.cofres.firstWhere((c) => c.contenido == 'llave-cera');
      final acciones = cienaga.accionesEn(MapaMundo.piesEnCelda(llave.x, llave.y + 1));
      expect(acciones.map((a) => a.etiqueta), ['Abrir el cofre']);
      acciones.single.alPulsar();
      expect(juego.cofreAbierto('cienaga/cofre-llave'), isTrue);
      expect(mapa.objetos[19][61], abierta);
      expect(mapa.objetos[3][61], reja);

      // El oro de un cofre se ve en el acto.
      final conOro = mapa.cofres.firstWhere((c) => c.contenido == 'oro');
      final oroAntes = juego.oro.value;
      cienaga.accionesEn(MapaMundo.piesEnCelda(conOro.x, conOro.y + 1)).single.alPulsar();
      expect(juego.oro.value, oroAntes + 200);

      // La entrada de la arena baja a la mazmorra de la Madre Cirio.
      final (puerta, vestibulo) = cienaga.puertas.firstWhere(
        (p) => p.$2.slug == 'cienaga-vestibulo-de-los-cirios',
      );
      juego.entrar(vestibulo, puerta);
      await correr(0.1);
      var sala = juego.world as SalaInterior;
      expect(sala.sala.slug, 'cienaga-vestibulo-de-los-cirios');
      for (var i = 0; i < 3; i++) {
        juego.cruzar(sala, 'bajada');
        await correr(0.1);
        sala = juego.world as SalaInterior;
      }
      expect(sala.sala.slug, 'cienaga-altar-de-la-madre');
      final madre = sala.enemigosVivos.single;
      expect(madre.tipo, Enemigos.madreCirio);

      // Vencida, la salida de la zona se abre.
      juego.jugador.position.setFrom(sala.junto('jefe'));
      madre.recibirGolpe(1000000, false, Vector2(1, 0));
      await correr(0.2);
      expect(juego.jefesDerrotados, contains('jefe-madre-cirio'));
      expect(mapa.objetos[3][61], abierta);

      // Se descansa en el segundo altar y se cruza a las minas.
      juego.cruzar(sala, 'salida');
      await correr(0.1);
      await juego.cruzarFrontera('minas', adelante: true);
      await correr(0.1);
      expect(juego.tierras.zonaId, 'minas');
      expect(juego.world, juego.tierras);
      expect(juego.jugador.position, juego.tierras.inicio);

      // Las zarzas se cortan.
      final minas = juego.tierras;
      final zarza = minas.mapa.objeto('zarza');
      expect(minas.mapa.objetos[12][47], zarza);
      final junto = [
        for (final (x, y) in const [(46, 12), (49, 12), (47, 11), (47, 14), (46, 13)])
          MapaMundo.piesEnCelda(x, y),
      ].firstWhere(
        (p) => minas.libre(
          Rect.fromCenter(center: Offset(p.x, p.y - 1.5), width: 8, height: 3),
        ),
      );
      final cortar = minas.accionesEn(junto);
      expect(cortar.map((a) => a.etiqueta), ['Cortar la zarza']);
      cortar.single.alPulsar();
      expect(minas.mapa.objetos[12][47], minas.mapa.objeto('zarza-cortada'));
      expect(minas.mapa.objetos[13][48], minas.mapa.objeto('zarza-cortada'));

      // De vuelta a la ciénaga se llega junto a su salida, y sigue como estaba.
      await juego.cruzarFrontera('cienaga', adelante: false);
      await correr(0.1);
      expect(juego.tierras, same(cienaga));
      final salida = cienaga.mapa.salida!;
      expect(
        juego.jugador.position.distanceTo(MapaMundo.piesEnCelda(salida.x, salida.y)),
        lessThan(MapaMundo.tile * 4),
      );

      // Se despierta en el último altar aunque se caiga en otra zona.
      juego.jugador.position.setFrom(cienaga.junto(1));
      await juego.descansar(altar: 1);
      await juego.cruzarFrontera('minas', adelante: true);
      juego.jugador.recibirGolpe(1000000);
      expect(juego.muerto.value, isTrue);
      await juego.revivir();
      await correr(0.1);
      expect(juego.tierras.zonaId, 'cienaga');
      expect(cienaga.altarCerca(juego.jugador.position), 1);
    });
  });

  testWidgets('cada criatura y cada jefe pelean sin errores', (tester) async {
    await tester.runAsync(() async {
      final juego = _juego(_partida());
      juego.onGameResize(Vector2(844, 390));
      await juego.load();
      juego.mount();
      await juego.ready();
      await Hojas.preparar(juego.images, [
        for (final t in [...Enemigos.todos, ...Enemigos.jefes]) t.hoja,
      ]);
      final zona = juego.tierras;
      for (final e in zona.enemigosVivos.toList()) {
        e.removeFromParent();
      }

      for (final tipo in [...Enemigos.todos, ...Enemigos.jefes]) {
        final enemigo = Enemigo(tipo, juego.jugador.position + Vector2(24, 0));
        zona.add(enemigo);
        // Cerca, para que se prepare, ataque o embista y se enfurezca.
        for (var t = 0.0; t < 3; t += 1 / 60) {
          juego.vida.value = juego.vidaMaxima.value;
          if (t > 1.5 && tipo.jefe && !enemigo.furioso) {
            enemigo.vida = enemigo.vidaMaxima / 2 - 1;
          }
          juego.update(1 / 60);
          await juego.ready();
          final grabadora = PictureRecorder();
          juego.render(Canvas(grabadora));
          grabadora.endRecording().dispose();
        }
        enemigo.recibirGolpe(10000000, false, Vector2(1, 0));
        juego.update(1 / 60);
        await juego.ready();
        expect(enemigo.vivo, isFalse, reason: tipo.id);
      }
    });
  });

  testWidgets('tras el trono del Rey Hueco se baja a la ciénaga', (tester) async {
    await tester.runAsync(() async {
      final juego = _juego(
        _partida(
          zonaId: 'cripta-sala-del-trono',
          jefes: [Enemigos.reyHueco.id],
        ),
      );
      juego.onGameResize(Vector2(844, 390));
      await juego.load();
      juego.mount();
      await juego.ready();

      final trono = juego.world as SalaInterior;
      expect(trono.sala.slug, 'cripta-sala-del-trono');
      expect(juego.tierras.zonaId, ZonaTierras.id);
      final acciones = trono.accionesEn(trono.junto('jefe'));
      expect(acciones.map((a) => a.etiqueta), ['Bajar por el pasadizo']);

      await juego.cruzarFrontera('cienaga', adelante: true);
      expect(juego.tierras.zonaId, 'cienaga');
      expect(juego.world, juego.tierras);

      // Por la entrada de la ciénaga se vuelve a la sala del trono.
      await juego.cruzarFrontera(ZonaTierras.id, adelante: false);
      expect((juego.world as SalaInterior).sala.slug, 'cripta-sala-del-trono');
    });
  });
}
