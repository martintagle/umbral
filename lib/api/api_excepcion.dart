/// Error que llega a la UI, con un mensaje listo para mostrar.
class ApiExcepcion implements Exception {
  final String mensaje;

  /// Código HTTP de la respuesta, o `null` si no hubo respuesta del servidor.
  final int? estado;

  /// La petición no llegó al servidor (sin internet): no se aplicó nada, así
  /// que se puede seguir con los datos del teléfono.
  final bool sinConexion;

  /// El servidor no respondió a tiempo: la petición pudo llegar o no.
  final bool agotado;

  const ApiExcepcion(
    this.mensaje, {
    this.estado,
    this.sinConexion = false,
    this.agotado = false,
  });

  bool get sesionCaducada => estado == 401;

  @override
  String toString() => mensaje;
}
