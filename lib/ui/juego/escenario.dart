import 'dart:ui';

import 'package:flame/components.dart';

import 'enemigo.dart';
import 'umbral_juego.dart';

/// Algo que se puede hacer donde está el jugador: descansar, entrar, abrir un
/// cofre... La pantalla lo muestra como emblema con su texto al lado y la
/// tecla E hace la primera.
class AccionContexto {
  final String etiqueta;
  final VoidCallback alPulsar;

  /// Emblema `assets/hud/boton-accion-<boton>.png`: `descansar`, `entrar`,
  /// `yunque`, `leer`, `abrir` o `hablar`.
  final String boton;

  /// El texto va en `brasa` para llamar la atención (por ejemplo, cuando
  /// alcanza la experiencia para subir de nivel).
  final bool resaltada;

  const AccionContexto(
    this.etiqueta,
    this.alPulsar, {
    this.boton = 'entrar',
    this.resaltada = false,
  });
}

/// Un lugar jugable: el mundo abierto o una sala interior. Las coordenadas
/// están en píxeles de arte desde la esquina superior izquierda.
abstract class Escenario extends World with HasGameReference<UmbralJuego> {
  Rect get limites;

  /// Bajo techo y sobre piedra: cambia el sonido de los pasos.
  bool get interior => false;

  /// Música o ambiente del lugar; `null` para el silencio de la noche.
  String? get pista => null;

  /// Nombre que la pantalla anuncia al llegar a [pies].
  String regionEn(Vector2 pies);

  /// [pies] es la caja de colisión; [enemigo] pide además las reglas de paso
  /// de las criaturas.
  bool libre(Rect pies, {bool enemigo = false});

  /// Para proyectiles.
  bool bloquea(double x, double y);

  Iterable<Enemigo> get enemigosVivos =>
      children.whereType<Enemigo>().where((e) => e.vivo);

  /// Vuelve a poner a las criaturas en su sitio con la vida llena. Se usa al
  /// descansar y al morir.
  void reiniciarEnemigos();

  List<AccionContexto> accionesEn(Vector2 pies) => const [];

  /// Lo llama el juego cada cuadro: para salidas y escaleras que se activan
  /// al pisarlas.
  void pisando(Vector2 pies) {}

  void limitar(Vector2 p) {
    p.x = p.x.clamp(limites.left + 8, limites.right - 8);
    p.y = p.y.clamp(limites.top + 12, limites.bottom - 4);
  }
}
