import 'dart:async';

import 'package:flutter/foundation.dart';

import 'partida_api.dart';
import 'sesion.dart';

/// Estado del modo sin conexión, para que la UI lo muestre, y el reintento
/// del envío del progreso guardado en el teléfono.
abstract final class Sincronizacion {
  /// Falso desde que una petición no llega al servidor hasta que otra llega.
  static final enLinea = ValueNotifier<bool>(true);

  /// Partidas con progreso guardado en el teléfono que aún no llegó al
  /// servidor.
  static final pendientes = ValueNotifier<int>(0);

  static Timer? _reintento;

  /// Cada 30 segundos, si queda progreso por enviar y hay sesión, lo intenta.
  static void iniciar() {
    _reintento ??= Timer.periodic(const Duration(seconds: 30), (_) {
      if (pendientes.value > 0 && Sesion.token != null) {
        PartidaApi().sincronizar().ignore();
      }
    });
  }
}
