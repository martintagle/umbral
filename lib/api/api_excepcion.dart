/// Error que llega a la UI, con un mensaje listo para mostrar.
class ApiExcepcion implements Exception {
  final String mensaje;

  /// Código HTTP de la respuesta, o `null` si no hubo respuesta del servidor.
  final int? estado;

  const ApiExcepcion(this.mensaje, {this.estado});

  bool get sesionCaducada => estado == 401;

  @override
  String toString() => mensaje;
}
