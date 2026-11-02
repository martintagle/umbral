import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:umbral/ui/juego/mapa_interiores.dart';
import 'package:umbral/ui/juego/oreste.dart';

/// Un mundo de mentira: lo que se ha encendido, abierto, vencido y leído.
class _Estado implements EstadoMundo {
  final Set<String> fogatas = {};
  final Set<String> cofres = {};
  @override
  final Set<String> jefesDerrotados = {};
  @override
  final Set<String> dialogosLeidos = {};

  @override
  bool fogataEncendidaEn(String zonaId) => fogatas.contains(zonaId);

  @override
  bool cofreAbierto(String id) => cofres.contains(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatosOreste datos;
  setUpAll(() async {
    datos = DatosOreste.desdeJson(
      await rootBundle.loadString('assets/datos/npc-oreste.json'),
    );
  });

  test('22 diálogos, seis frases de espera y un refugio por zona', () async {
    expect(datos.dialogos, hasLength(22));
    expect(datos.espera.keys, [1, 2, 3, 4, 5, 6]);
    expect(datos.refugios.keys, [1, 2, 3, 4, 5, 6]);
    expect(datos.trasAstilla, isNotEmpty);
    // Cada refugio es una sala que existe, y Oreste está en una celda libre.
    final interiores = await MapaInteriores.cargar();
    for (final MapEntry(key: zona, value: r) in datos.refugios.entries) {
      final sala = interiores.porSlug(r.sala);
      expect(sala, isNotNull, reason: 'zona $zona: ${r.sala}');
      expect(sala!.objetos[r.y][r.x], -1, reason: 'zona $zona');
    }
  });

  test('cada zona va en orden y espera a sus requisitos', () {
    final estado = _Estado();
    expect(datos.siguiente(1, estado)?.id, 'oreste-1-1');
    estado.dialogosLeidos.add('oreste-1-1');
    // Sin altar encendido no hay nada nuevo, pero quedan pendientes.
    expect(datos.siguiente(1, estado), isNull);
    expect(datos.tienePendientes(1, estado), isTrue);
    estado.fogatas.add('tierras-del-umbral');
    expect(datos.siguiente(1, estado)?.id, 'oreste-1-2');
    estado.dialogosLeidos.add('oreste-1-2');
    expect(datos.siguiente(1, estado), isNull);
    estado.jefesDerrotados.add('jefe-rey-hueco');
    expect(datos.siguiente(1, estado)?.id, 'oreste-1-3');
    estado.dialogosLeidos.add('oreste-1-3');
    expect(datos.tienePendientes(1, estado), isFalse);
  });

  test('con todo cumplido, cada zona sale en su orden', () {
    final estado = _Estado();
    for (final d in datos.dialogos) {
      for (final r in d.requiere) {
        final [tipo, ...resto] = r.split(':');
        final valor = resto.join(':');
        switch (tipo) {
          case 'fogata':
            estado.fogatas.add(valor);
          case 'cofre':
            estado.cofres.add(valor);
          case 'jefe':
            estado.jefesDerrotados.add(valor);
        }
      }
    }
    for (var zona = 1; zona <= 6; zona++) {
      final leidos = <String>[];
      for (var d = datos.siguiente(zona, estado);
          d != null;
          d = datos.siguiente(zona, estado)) {
        leidos.add(d.id);
        estado.dialogosLeidos.add(d.id);
      }
      final esperados = [
        for (final d in datos.dialogos)
          if (d.zona == zona && d.id != 'oreste-6-4') d.id,
      ];
      expect(leidos.take(esperados.length), esperados, reason: 'zona $zona');
    }
    expect(estado.dialogosLeidos, hasLength(22));
  });

  test('está en un solo sitio y sale a la mazmorra tras el jefe', () {
    final estado = _Estado();
    // Sin leer nada, espera en la zona 1 aunque se haya llegado más lejos.
    expect(datos.zonaDe(estado), 1);
    expect(datos.enRefugio(1, estado), isTrue);
    expect(datos.enRefugio(2, estado), isFalse);
    estado.dialogosLeidos.addAll(['oreste-1-1', 'oreste-1-2', 'oreste-1-3']);
    expect(datos.zonaDe(estado), 2);

    // Vencido el jefe de la ciénaga sin seguir la misión, no sale.
    estado.jefesDerrotados.add('jefe-madre-cirio');
    expect(datos.anteLaMazmorra(2, estado), isFalse);
    expect(datos.enRefugio(2, estado), isTrue);

    // Siguiéndola, solo queda el diálogo del jefe: espera fuera.
    estado.dialogosLeidos.addAll(['oreste-2-1', 'oreste-2-2']);
    expect(datos.anteLaMazmorra(2, estado), isTrue);
    expect(datos.enRefugio(2, estado), isFalse);
    estado.dialogosLeidos.add('oreste-2-3');
    expect(datos.zonaDe(estado), 3);
    expect(datos.anteLaMazmorra(2, estado), isFalse);

    // En la zona 1 el diálogo del jefe se da en la capilla.
    final otro = _Estado()
      ..dialogosLeidos.addAll(['oreste-1-1', 'oreste-1-2'])
      ..jefesDerrotados.add('jefe-rey-hueco');
    expect(datos.anteLaMazmorra(1, otro), isFalse);
    expect(datos.enRefugio(1, otro), isTrue);
  });

  test('«todos» solo se cumple con los otros 21 leídos', () {
    final estado = _Estado();
    final otros = [
      for (final d in datos.dialogos)
        if (d.id != 'oreste-6-4') d.id,
    ];
    expect(otros, hasLength(21));
    estado.dialogosLeidos.addAll(otros.skip(1));
    expect(datos.cumple('todos', estado, 'oreste-6-4'), isFalse);
    estado.dialogosLeidos.add(otros.first);
    expect(datos.cumple('todos', estado, 'oreste-6-4'), isTrue);
    expect(datos.siguiente(6, estado)?.id, 'oreste-6-4');
  });
}
