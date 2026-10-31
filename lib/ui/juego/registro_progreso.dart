import 'dart:math';

import '../../contrato/progreso.dart';
import '../../contrato/recompensa.dart';
import '../../contrato/ubicacion.dart';

/// Lo ganado desde el último guardado que queda en el suelo al caer.
typedef Botin = ({Map<String, int> enemigos, int exp, int oro});

/// Lo que ha pasado en la partida desde el último guardado. Al guardar se
/// envía como [Progreso] y, si el servidor lo acepta, se descuenta lo
/// enviado: lo ocurrido mientras la petición viajaba no se pierde.
class RegistroProgreso {
  RegistroProgreso(this._recompensas, [Random? azar])
    : _azar = azar ?? Random();

  final Map<String, Recompensa> _recompensas;
  final Random _azar;

  /// Enemigos derrotados de cada tipo, por id.
  final Map<String, int> enemigos = {};

  /// Experiencia y oro que dieron esos enemigos.
  int exp = 0;
  int oro = 0;
  int muertes = 0;
  double segundos = 0;

  /// Cofres del mundo abiertos (`zonaId/cofreId`) y el oro que se espera de
  /// ellos. No caen al morir: un cofre abierto queda abierto.
  final Set<String> cofres = {};
  int oroCofres = 0;

  void cofreAbierto(String id, int oro) {
    if (cofres.add(id)) oroCofres += oro;
  }

  /// Anota la derrota y tira lo que da, dentro de los rangos del servidor.
  ({int exp, int oro}) enemigoDerrotado(String tipo) {
    enemigos.update(tipo, (n) => n + 1, ifAbsent: () => 1);
    final r = recompensa(tipo);
    final ganado = (
      exp: _entre(r.expMin, r.expMax),
      oro: _entre(r.oroMin, r.oroMax),
    );
    exp += ganado.exp;
    oro += ganado.oro;
    return ganado;
  }

  int _entre(int min, int max) => min + _azar.nextInt(max - min + 1);

  /// Si el servidor no conoce el tipo, rechazará el guardado y lo avisará.
  Recompensa recompensa(String tipo) =>
      _recompensas[tipo] ??
      Recompensa(
        id: tipo,
        categoria: Categoria.media,
        expMin: 0,
        expMax: 0,
        oroMin: 0,
        oroMax: 0,
      );

  Progreso aProgreso({required int vidaActual, required Ubicacion ubicacion}) {
    return Progreso(
      enemigosDerrotados: Map.of(enemigos),
      exp: exp,
      oro: oro,
      muertes: muertes,
      segundosJugados: segundos.floor(),
      vidaActual: vidaActual,
      ubicacion: ubicacion,
      cofresAbiertos: cofres.toList(),
      oroCofres: oroCofres,
    );
  }

  /// Al caer: se quita lo ganado para dejarlo en el suelo.
  Botin soltar() {
    final botin = (enemigos: Map.of(enemigos), exp: exp, oro: oro);
    enemigos.clear();
    exp = 0;
    oro = 0;
    return botin;
  }

  /// Al recoger lo que se soltó.
  void recuperar(Botin botin) {
    botin.enemigos.forEach(
      (tipo, n) => enemigos.update(tipo, (m) => m + n, ifAbsent: () => n),
    );
    exp += botin.exp;
    oro += botin.oro;
  }

  void descontar(Progreso enviado) {
    enviado.enemigosDerrotados.forEach((tipo, n) {
      // Puede faltar si se cayó mientras se guardaba.
      final quedan = (enemigos[tipo] ?? 0) - n;
      if (quedan <= 0) {
        enemigos.remove(tipo);
      } else {
        enemigos[tipo] = quedan;
      }
    });
    exp = max(0, exp - enviado.exp);
    oro = max(0, oro - enviado.oro);
    muertes -= enviado.muertes;
    segundos -= enviado.segundosJugados;
    cofres.removeAll(enviado.cofresAbiertos);
    oroCofres = max(0, oroCofres - enviado.oroCofres);
  }
}
