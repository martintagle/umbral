import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:umbral/contrato/recompensa.dart';
import 'package:umbral/contrato/ubicacion.dart';
import 'package:umbral/ui/juego/registro_progreso.dart';

const _ojo = Recompensa(
  id: 'ojo-errante',
  categoria: Categoria.debil,
  expMin: 6,
  expMax: 10,
  oroMin: 2,
  oroMax: 4,
);

const _ubicacion = Ubicacion(
  zonaId: 'z',
  x: 0,
  y: 0,
  ultimoPuntoGuardado: null,
);

void main() {
  test('cada derrota da exp y oro al azar dentro del rango', () {
    final registro = RegistroProgreso({_ojo.id: _ojo}, Random(1));
    final tiradas = [
      for (var i = 0; i < 200; i++) registro.enemigoDerrotado(_ojo.id),
    ];

    expect(tiradas.map((t) => t.exp), everyElement(inInclusiveRange(6, 10)));
    expect(tiradas.map((t) => t.oro), everyElement(inInclusiveRange(2, 4)));
    // Con 200 tiradas salen todos los valores, no siempre el mismo.
    expect(tiradas.map((t) => t.exp).toSet(), {6, 7, 8, 9, 10});
    expect(registro.exp, tiradas.fold(0, (a, t) => a + t.exp));
    expect(registro.oro, tiradas.fold(0, (a, t) => a + t.oro));
  });

  test('al caer se suelta lo ganado y al recogerlo vuelve igual', () {
    final registro = RegistroProgreso({_ojo.id: _ojo}, Random(2));
    for (var i = 0; i < 3; i++) {
      registro.enemigoDerrotado(_ojo.id);
    }
    final (exp, oro) = (registro.exp, registro.oro);

    final botin = registro.soltar();
    expect((registro.exp, registro.oro), (0, 0));
    expect(registro.enemigos, isEmpty);

    registro.recuperar(botin);
    expect((registro.exp, registro.oro), (exp, oro));
    expect(registro.enemigos, {_ojo.id: 3});
  });

  test('al guardar se envía lo tirado y se descuenta lo enviado', () {
    final registro = RegistroProgreso({_ojo.id: _ojo}, Random(3));
    registro.enemigoDerrotado(_ojo.id);
    final enviado = registro.aProgreso(vidaActual: 10, ubicacion: _ubicacion);
    final posterior = registro.enemigoDerrotado(_ojo.id);

    expect(enviado.toMap()['exp'], enviado.exp);
    registro.descontar(enviado);
    expect(registro.exp, posterior.exp);
    expect(registro.oro, posterior.oro);
    expect(registro.enemigos, {_ojo.id: 1});
  });
}
