/// Lo que da un enemigo al ser derrotado, según el servidor. No replica
/// ninguna colección: es la respuesta de `GET /api/enemigos`.
class Recompensa {
  final String id;
  final int exp;
  final int oro;

  const Recompensa({required this.id, required this.exp, required this.oro});

  factory Recompensa.fromMap(Map<String, dynamic> map) {
    return Recompensa(
      id: map['id'] as String,
      exp: map['exp'] as int,
      oro: map['oro'] as int,
    );
  }
}
