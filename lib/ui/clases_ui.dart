/// Textos y sprites de cada clase. Las estadísticas vienen del servidor
/// (`ClaseServicio`); aquí solo está lo que se muestra.
class ClaseUi {
  final String id;
  final String nombre;
  final String arma;
  final String descripcion;

  /// Icono del arma en `assets/iconos/iconos.json`.
  final String iconoArma;
  final String armadura;

  /// Atributo con el que crece el daño del arma, para señalarlo en la
  /// pantalla de estadísticas.
  final String atributoArma;

  const ClaseUi(
    this.id,
    this.nombre,
    this.arma,
    this.descripcion, {
    required this.iconoArma,
    required this.armadura,
    required this.atributoArma,
  });

  String sprite(String apariencia) =>
      'assets/sprites/personajes/$id-$apariencia.png';
}

const Map<String, ClaseUi> clasesUi = {
  'vagabundo': ClaseUi(
    'vagabundo',
    'Vagabundo',
    'Katana',
    'Ágil y equilibrado. Cortes rápidos de alcance medio.',
    iconoArma: 'espada',
    armadura: 'Ropa de viaje',
    atributoArma: 'destreza',
  ),
  'guerrero': ClaseUi(
    'guerrero',
    'Guerrero',
    'Espadón',
    'Resiste mucho y golpea fuerte en un arco amplio, pero despacio.',
    iconoArma: 'espada',
    armadura: 'Armadura de placas',
    atributoArma: 'fuerza',
  ),
  'arquero': ClaseUi(
    'arquero',
    'Arquero',
    'Arco largo',
    'Ataca desde lejos. Frágil si lo alcanzan.',
    iconoArma: 'arco',
    armadura: 'Jubón de cuero',
    atributoArma: 'destreza',
  ),
  'mago': ClaseUi(
    'mago',
    'Mago',
    'Libro de hechizos',
    'Lanza orbes de alma que hacen mucho daño. Poca vida.',
    iconoArma: 'grimorio',
    armadura: 'Túnica',
    atributoArma: 'inteligencia',
  ),
  'prisionero': ClaseUi(
    'prisionero',
    'Prisionero',
    'Daga',
    'Sin armadura ni oro. Puñaladas muy rápidas. Para quien busca desafío.',
    iconoArma: 'daga',
    armadura: 'Harapos',
    atributoArma: 'destreza',
  ),
};

ClaseUi claseUi(String id) => clasesUi[id] ?? clasesUi['vagabundo']!;
