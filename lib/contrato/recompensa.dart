/// Las criaturas débiles abundan en el mapa y dan poco; las fuertes escasean y
/// dan más.
enum Categoria { debil, media, fuerte, jefe }

/// Lo que puede dar un enemigo al ser derrotado, según el servidor: cada
/// derrota da una cantidad al azar dentro de estos rangos, con los extremos
/// incluidos. No replica ninguna colección: es la respuesta de
/// `GET /api/enemigos`.
class Recompensa {
  final String id;
  final Categoria categoria;
  final int expMin;
  final int expMax;
  final int oroMin;
  final int oroMax;

  const Recompensa({
    required this.id,
    required this.categoria,
    required this.expMin,
    required this.expMax,
    required this.oroMin,
    required this.oroMax,
  });

  factory Recompensa.fromMap(Map<String, dynamic> map) {
    return Recompensa(
      id: map['id'] as String,
      categoria: Categoria.values.byName(map['categoria'] as String),
      expMin: map['expMin'] as int,
      expMax: map['expMax'] as int,
      oroMin: map['oroMin'] as int,
      oroMax: map['oroMax'] as int,
    );
  }
}
