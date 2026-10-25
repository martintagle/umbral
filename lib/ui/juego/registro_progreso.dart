import '../../dto/progreso_dto.dart';
import '../../dto/ubicacion_dto.dart';

/// Lo que ha pasado en la partida desde el último guardado. Al guardar se
/// envía como [ProgresoDto] y, si el servidor lo acepta, se descuenta lo
/// enviado: lo ocurrido mientras la petición viajaba no se pierde.
class RegistroProgreso {
  int exp = 0;
  int oro = 0;
  int enemigos = 0;
  int muertes = 0;
  double segundos = 0;

  void enemigoDerrotado({required int exp, required int oro}) {
    this.exp += exp;
    this.oro += oro;
    enemigos++;
  }

  ProgresoDto aDto({required int vidaActual, required UbicacionDto ubicacion}) {
    return ProgresoDto(
      expGanada: exp,
      oroGanado: oro,
      enemigosDerrotados: enemigos,
      muertes: muertes,
      segundosJugados: segundos.floor(),
      vidaActual: vidaActual,
      ubicacion: ubicacion,
    );
  }

  void descontar(ProgresoDto enviado) {
    exp -= enviado.expGanada;
    oro -= enviado.oroGanado;
    enemigos -= enviado.enemigosDerrotados;
    muertes -= enviado.muertes;
    segundos -= enviado.segundosJugados;
  }
}
