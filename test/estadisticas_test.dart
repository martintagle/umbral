import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:umbral/contrato/atributos.dart';
import 'package:umbral/contrato/partida_jugable.dart';
import 'package:umbral/ui/pantallas/estadisticas_pantalla.dart';

PartidaJugable _partida({required int exp}) => PartidaJugable.fromMap({
      'partida': {
        'partidaId': 'p1',
        'creadaEn': '2026-10-25T00:00:00Z',
        'ultimaVezJugada': '2026-10-25T00:00:00Z',
        'personaje': {
          'nombre': 'Prueba',
          'claseCodigo': 'guerrero',
          'apariencia': 'hombre',
          'nivel': 1,
          'exp': exp,
          'puntosLibres': 0,
          'oro': 0,
          'atributos': {'vida': 14, 'fuerza': 15, 'destreza': 9, 'inteligencia': 6},
          'vidaActual': 152,
          'estaminaActual': 100,
          'equipo': {'nivelArma': 1, 'nivelArmadura': 2},
          'ubicacion': {
            'zonaId': 'tierras-del-umbral',
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
        'vidaMaxima': 152,
        'expSiguiente': 67,
        'costoNiveles': [67, 69, 71, 72],
        'dano': 18,
        'defensa': 4,
        'probabilidadCritico': 0.095,
        'multiplicadorCritico': 1.5,
        'mejoraArma': null,
        'mejoraArmadura': null,
      },
    });

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('cada punto cuesta más y no deja pasar de la experiencia',
      (tester) async {
    tester.view
      ..physicalSize = const Size(915, 412)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Atributos? enviado;
    await tester.pumpWidget(MaterialApp(
      home: EstadisticasPantalla(
        partida: _partida(exp: 150),
        alSubir: (incrementos) async {
          enviado = incrementos;
          return _partida(exp: 150 - 136);
        },
      ),
    ));
    await tester.pump();

    final sumarFuerza = find.bySemanticsLabel('Sumar Fuerza');
    await tester.tap(sumarFuerza);
    await tester.pump();
    expect(find.text('Gastas 67 · quedan 83'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Sumar Vigor'));
    await tester.pump();
    expect(find.text('Gastas 136 · quedan 14'), findsOneWidget);

    // El tercero costaría 71 más (207 > 150): sumar queda deshabilitado.
    await tester.tap(sumarFuerza);
    await tester.pump();
    expect(find.text('Gastas 136 · quedan 14'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Confirmar, 136 EXP'));
    await tester.pumpAndSettle();
    expect(enviado?.fuerza, 1);
    expect(enviado?.vida, 1);
  });
}
