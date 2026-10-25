// ignore_for_file: invalid_use_of_internal_member
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umbral/servicio/modelos/partida_jugable.dart';
import 'package:umbral/servicio/modelos/recompensa.dart';
import 'package:umbral/ui/juego/enemigo.dart';
import 'package:umbral/ui/juego/sala_interior.dart';
import 'package:umbral/ui/juego/tipos_enemigo.dart';
import 'package:umbral/ui/juego/umbral_juego.dart';
import 'package:umbral/ui/juego/zona_tierras.dart';

PartidaJugable _partida() => PartidaJugable.fromMap({
      'partida': {
        'partidaId': 'p1',
        'creadaEn': '2026-10-25T00:00:00Z',
        'ultimaVezJugada': '2026-10-25T00:00:00Z',
        'personaje': {
          'nombre': 'Prueba',
          'clase': 'vagabundo',
          'apariencia': 'mujer',
          'nivel': 10,
          'exp': 0,
          'puntosLibres': 0,
          'oro': 0,
          'atributos': {'vida': 4, 'fuerza': 3, 'destreza': 5, 'inteligencia': 1},
          'vidaActual': 128,
          'estaminaActual': 100,
          'equipo': {'nivelArma': 1, 'nivelArmadura': 1},
          'ubicacion': {
            'zonaId': 'otra',
            'x': 0,
            'y': 0,
            'ultimoPuntoGuardado': null
          },
          'mundo': {
            'zonasDesbloqueadas': <String>[],
            'cofresAbiertos': <String>[],
            'jefesDerrotados': <String>[]
          },
          'estadisticas': {
            'enemigosDerrotados': 0,
            'muertes': 0,
            'tiempoJugadoSeg': 0
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
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UmbralJuego juego;

  Future<void> correr(double segundos) async {
    for (var t = 0.0; t < segundos; t += 1 / 60) {
      juego.update(1 / 60);
      await juego.ready();
      // Dibuja el cuadro: así también se prueban los render.
      final grabadora = PictureRecorder();
      juego.render(Canvas(grabadora));
      grabadora.endRecording().dispose();
    }
  }

  setUp(() {
    final partida = _partida();
    juego = UmbralJuego(
      partida: partida,
      recompensas: {
        for (final e in [...Enemigos.todos, Enemigos.reyHueco])
          e.id: Recompensa(id: e.id, exp: 1, oro: 1),
      },
      alGuardar: (_, _) async => partida,
    );
  });

  testWidgets('escala, estamina, interiores y cripta', (tester) async {
    await tester.runAsync(() async {
      juego.onGameResize(Vector2(844, 390));
      await juego.load();
      juego.mount();
      await juego.ready();

      // Zoom par: los sprites a la mitad siguen en píxeles enteros.
      expect(juego.zoom, 4);
      expect(juego.world, isA<ZonaTierras>());
      expect(juego.jugador.position, juego.tierras.inicio);

      // La estamina baja al atacar, no deja atacar sin ella y se recupera.
      juego.botonAtaque = true;
      await correr(1.5);
      expect(juego.estamina.value, lessThan(40));
      juego.botonAtaque = false;
      await correr(4);
      expect(juego.estamina.value, UmbralJuego.estaminaMaxima);

      // Altar: descansar y atributos.
      await correr(0.1);
      expect(juego.acciones.value.map((a) => a.etiqueta),
          ['Descansar', 'Subir de nivel']);

      // Cinco estructuras con interior; la choza del sur es la herrería.
      final puertas = {
        for (final (p, s) in juego.tierras.puertas) s.slug: p
      };
      expect(puertas.keys, containsAll([
        'choza-en-ruinas',
        'herreria-abandonada',
        'capilla',
        'torre-derruida',
        'cripta-antecamara',
      ]));

      // Entrar a la capilla por su puerta.
      juego.jugador.position.setFrom(puertas['capilla']!);
      await correr(0.1);
      expect(juego.acciones.value.single.etiqueta, 'Entrar');
      juego.acciones.value.single.alPulsar();
      await correr(0.6);
      final capilla = juego.world as SalaInterior;
      expect(capilla.sala.nombre, 'Capilla');
      expect(juego.jugador.parent, capilla);
      expect(juego.region.value, 'Capilla');

      // El altar de la capilla abre las estadísticas.
      final altar = capilla.sala.punto('estadisticas')!;
      juego.jugador.position.setFrom(SalaInterior.piesEn(altar.x, altar.y + 1));
      await correr(0.1);
      expect(juego.acciones.value.single.etiqueta, 'Subir de nivel');

      // Pisar la salida devuelve al mundo, delante de la puerta.
      final salida = capilla.sala.punto('salida')!;
      juego.jugador.position.setFrom(SalaInterior.piesEn(salida.x, salida.y));
      await correr(0.1);
      expect(juego.world, juego.tierras);
      expect(juego.jugador.position, puertas['capilla']);

      // Cripta: la escalera baja a la sala del trono, donde espera el jefe.
      juego.entrar(
          juego.tierras.puertas.firstWhere((e) => e.$2.slug == 'cripta-antecamara').$2,
          puertas['cripta-antecamara']!);
      await correr(0.6);
      final antecamara = juego.world as SalaInterior;
      final bajada = antecamara.sala.punto('bajada')!;
      juego.jugador.position.setFrom(SalaInterior.piesEn(bajada.x, bajada.y));
      await correr(0.1);
      final trono = juego.world as SalaInterior;
      expect(trono.sala.slug, 'cripta-sala-del-trono');
      expect(trono.enemigosVivos.single.tipo, Enemigos.reyHueco);

      // El jefe se acerca, se prepara y ataca: el jugador recibe daño.
      final vidaAntes = juego.vida.value;
      juego.jugador.position.setFrom(trono.enemigosVivos.single.position +
          Vector2(0, 30));
      await correr(4);
      expect(juego.vida.value, lessThan(vidaAntes));

      // Subir vuelve a la antecámara junto a la escalera, y de ahí al mundo.
      final salidaTrono = trono.sala.punto('salida')!;
      juego.jugador.position
          .setFrom(SalaInterior.piesEn(salidaTrono.x, salidaTrono.y));
      await correr(0.1);
      expect(juego.world, antecamara);
      expect(juego.jugador.position, antecamara.llegada('bajada'));
      await correr(0.5);
      final salidaAnte = antecamara.sala.punto('salida')!;
      juego.jugador.position
          .setFrom(SalaInterior.piesEn(salidaAnte.x, salidaAnte.y));
      await correr(0.1);
      expect(juego.world, juego.tierras);

      // Pelea en el mundo: el jugador lo sigue de cerca (la polilla huye) y
      // la criatura se anima y muere sin errores.
      final enemigo = juego.tierras.enemigosVivos.first;
      juego.botonAtaque = true;
      for (var t = 0.0; t < 8 && enemigo.vivo; t += 1 / 60) {
        juego.jugador.position.setFrom(enemigo.position + Vector2(8, 0));
        juego.vida.value = juego.vidaMaxima.value;
        await correr(1 / 60);
      }
      juego.botonAtaque = false;
      expect(enemigo.vivo, isFalse);
      await correr(0.5);
      expect(juego.tierras.children.whereType<Enemigo>(), isNot(contains(enemigo)));
    });
  });
}
