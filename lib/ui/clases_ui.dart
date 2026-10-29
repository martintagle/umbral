import '../contrato/apariencia.dart';
import '../contrato/clase_codigo.dart';
import '../api/clase_api.dart';

/// Sprites e iconos de cada clase. El nombre, el arma y la descripción están
/// en la colección `clases` (`ClaseApi`) y las estadísticas las calcula el
/// servidor; aquí solo está lo que es de la interfaz.
class ClaseUi {
  final ClaseCodigo id;

  /// Icono del arma en `assets/iconos/iconos.json`.
  final String iconoArma;
  final String armadura;

  /// Atributo con el que crece el daño del arma, para señalarlo en la
  /// pantalla de estadísticas.
  final String atributoArma;

  const ClaseUi(
    this.id, {
    required this.iconoArma,
    required this.armadura,
    required this.atributoArma,
  });

  String sprite(Apariencia apariencia) =>
      'assets/sprites/personajes/${id.name}-${apariencia.name}.png';
}

const Map<ClaseCodigo, ClaseUi> clasesUi = {
  ClaseCodigo.vagabundo: ClaseUi(
    ClaseCodigo.vagabundo,
    iconoArma: 'espada',
    armadura: 'Ropa de viaje',
    atributoArma: 'destreza',
  ),
  ClaseCodigo.guerrero: ClaseUi(
    ClaseCodigo.guerrero,
    iconoArma: 'espada',
    armadura: 'Armadura de placas',
    atributoArma: 'fuerza',
  ),
  ClaseCodigo.arquero: ClaseUi(
    ClaseCodigo.arquero,
    iconoArma: 'arco',
    armadura: 'Jubón de cuero',
    atributoArma: 'destreza',
  ),
  ClaseCodigo.mago: ClaseUi(
    ClaseCodigo.mago,
    iconoArma: 'grimorio',
    armadura: 'Túnica',
    atributoArma: 'inteligencia',
  ),
  ClaseCodigo.prisionero: ClaseUi(
    ClaseCodigo.prisionero,
    iconoArma: 'daga',
    armadura: 'Harapos',
    atributoArma: 'destreza',
  ),
};

ClaseUi claseUi(ClaseCodigo id) => clasesUi[id]!;

/// Nombre de la clase según la colección `clases`. Mientras no ha llegado el
/// catálogo (o en las pruebas) se muestra el código.
String nombreClase(ClaseCodigo codigo) =>
    ClaseApi.clase(codigo)?.nombre ?? codigo.name;
