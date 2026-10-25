/// Textos y sprites de cada clase. Las estadísticas vienen del servidor
/// (`ClaseServicio`); aquí solo está lo que se muestra.
class ClaseUi {
  final String id;
  final String nombre;
  final String arma;
  final String descripcion;

  const ClaseUi(this.id, this.nombre, this.arma, this.descripcion);

  String sprite(String apariencia) =>
      'assets/sprites/personajes/$id-$apariencia.png';
}

const Map<String, ClaseUi> clasesUi = {
  'vagabundo': ClaseUi('vagabundo', 'Vagabundo', 'Katana',
      'Ágil y equilibrado. Cortes rápidos de alcance medio.'),
  'guerrero': ClaseUi('guerrero', 'Guerrero', 'Espadón',
      'Resiste mucho y golpea fuerte en un arco amplio, pero despacio.'),
  'arquero': ClaseUi('arquero', 'Arquero', 'Arco largo',
      'Ataca desde lejos. Frágil si lo alcanzan.'),
  'mago': ClaseUi('mago', 'Mago', 'Libro de hechizos',
      'Lanza orbes de alma que hacen mucho daño. Poca vida.'),
  'prisionero': ClaseUi('prisionero', 'Prisionero', 'Daga',
      'Sin armadura ni oro. Puñaladas muy rápidas. Para quien busca desafío.'),
};

ClaseUi claseUi(String id) => clasesUi[id] ?? clasesUi['vagabundo']!;
