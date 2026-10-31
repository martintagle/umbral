# Zonas 2 a 6

Cinco mapas nuevos con el mismo formato que `assets/mapas/mundo.json` (zona 1), un tileset por bioma y un minimapa de todo el juego. Cada zona tiene un diseño propio y se explora de otra forma. La historia, los lugares y qué enemigos van en cada zona están en `docs/guion.md`.

## Archivos

| Zona | Mapa | Tileset | Tamaño | Jefe | Enemigos |
| --- | --- | --- | --- | --- | --- |
| 2 Ciénaga de Cera | `assets/mapas/zona-2-cienaga.json` | `assets/tiles/tileset-cienaga.png` | 72 × 54 | `jefe-madre-cirio` | 21 |
| 3 Minas de Sal Negra | `assets/mapas/zona-3-minas.json` | `assets/tiles/tileset-minas.png` | 80 × 60 | `jefe-capataz-de-sal` | 25 |
| 4 Abadía Hundida | `assets/mapas/zona-4-abadia.json` | `assets/tiles/tileset-abadia.png` | 88 × 66 | `jefe-abadesa` | 25 |
| 5 Páramo de Ceniza | `assets/mapas/zona-5-paramo.json` | `assets/tiles/tileset-paramo.png` | 96 × 72 | `jefe-caballero-de-ceniza` | 29 |
| 6 El Umbral | `assets/mapas/zona-6-umbral.json` | `assets/tiles/tileset-umbral.png` | 104 × 78 | `jefe-el-que-mira` | 31 |

Las vistas completas de cada mapa están en `docs/diseno/zonas/`.

## Cómo se explora cada zona

### 2. Ciénaga de Cera: archipiélago

Islas sobre agua de cera, unidas por pasarelas de tablas. Se entra por el oeste.

- **La Orilla de los Cirios:** altar y pozo.
- **El Bosque Goteante:** la isla grande del norte, con árboles de cera. Una pasarela lleva al islote de la llave.
- **Islas del sur.**
- **El Santuario de la Madre:** arena en la isla del noreste. Al vencer a la Madre Cirio se abre el embarcadero norte.
- **Secretos (diminuto):**
  - el islote de las Cunas, por troncos desde un portal de la isla sur;
  - un nido al noroeste, por troncos desde la orilla.

### 3. Minas de Sal Negra: laberinto bajo roca

Todo es roca. Las cámaras se unen por galerías estrechas. Se entra por la Bocamina, abajo a la izquierda.

- **Recorrido:**
  1. Se sube por las galerías.
  2. Se cruza al este hasta la cámara de la llave, al fondo noreste y tras unas zarzas de sal.
  3. Se baja al Lago Salobre.
  4. Por una cámara con altar se llega a la Veta Profunda (arena).
- **Salida:** la galería inundada al este.
- **Secretos (diminuto):**
  - una cámara sellada al norte, por una gatera (`hueco`);
  - la isla del lago, por troncos.

### 4. Abadía Hundida: edificio con salas

Se entra por el oeste, sobre la pasarela del Atrio Inundado. La abadía es un recinto amurallado.

- **Ala oeste:**
  - una sala norte medio inundada;
  - un pasillo;
  - una cripta sellada al sur.
- **Claustro:** en el centro, con cuatro jardines y cuatro puertas.
- **Cementerio de Campanas:** el ala este, con lápidas y campanas caídas. La llave está tras la fila de zarzas del norte.
- **La Nave Mayor:** la arena, al sur. Detrás de ella, el portón trasero.
- **Secretos (diminuto):**
  - la cripta del ala oeste, por un hueco en el muro;
  - una plataforma del atrio, por troncos.

### 5. Páramo de Ceniza: llanura abierta

Campo abierto, con pocos obstáculos y casi sin protección. Se entra por el norte, al Campamento Caído, que está cercado.

- **Las Trincheras:** al sur. Son un zigzag de cuatro pasillos con la entrada al oeste.
- **La Colina de los Estandartes:** al noreste. Es una meseta con dos rampas y guarda la llave en la cima.
- **El Círculo del Juramento:** una arena redonda en el centro.
- **Salida:** al vencer al Caballero se abre la grieta que corre hacia el este.
- **Secretos (diminuto):**
  - un búnker sellado al fondo de las trincheras;
  - el islote de una charca de ceniza, por troncos.

### 6. El Umbral: islas sobre el vacío

El agua de este tileset es el vacío: no se puede pisar. Las islas se unen por puentes de un solo paso. Se entra por El Borde, al oeste.

- **Isla central:** la siguiente después de El Borde, con el segundo altar.
- **Dos caminos desde ella:**
  - **Al norte:** la cadena de puentes llega a la puerta del Altar Mayor.
  - **Al sur:** lleva al Jardín de Ojos, donde está la llave.
- **Salida:** detrás de la arena hay un nicho cerrado. Pisar su casilla de `salida` lanza el final.
- **Secretos (diminuto):**
  - la torre del primer guardián, por una larga hilera de troncos;
  - un islote al norte de El Borde.

## Qué cambia respecto a mundo.json

- **Tilesets.** Tienen los mismos 30 tiles en el mismo orden que `tileset.png`; solo cambian los colores. Los índices de `capas` valen igual.
- **Campos nuevos:** `id`, `numero`, `bioma`, `entrada` (con `desde`), `salida` (con `hacia`) y `enemigosDeLaZona`.
- **`salida` es una casilla.** Al pisarla se carga la zona siguiente, y el jugador aparece en su `inicio`. No siempre está en el borde del mapa: en la zona 6 está dentro del nicho del Altar Mayor.
- **Llave de cada zona:** `llave-cera`, `llave-sal`, `llave-plegaria`, `llave-juramento` y `llave-ultima`. Abre la reja de entrada a la arena; `reglas.objetosConLlave.reja` dice cuál es.
- **Rejas de salida.** Las de `salida.rejaSalida` **no se abren con la llave: se abren al vencer al jefe**. Es la única regla que el código tiene que distinguir de la zona 1.
- **Hoz.** Se supone ya conseguida en la zona 1.

## Validación

Cada mapa pasó una búsqueda de alcance que comprueba:

- La llave se alcanza desde la entrada.
- La arena está cerrada sin la llave y el jefe se alcanza con ella.
- La salida está cerrada hasta vencer al jefe.
- Los cofres secretos y los fragmentos solo se alcanzan en diminuto.
- El resto de cofres y todos los letreros son alcanzables.
- Todos los enemigos aparecen en casillas alcanzables.

## Enemigos y jefes

`assets/datos/enemigos-nuevos.json` trae las estadísticas sugeridas con los mismos campos que `TipoEnemigo`, para pasarlas a `lib/ui/juego/tipos_enemigo.dart`:

- Cada zona sube entre un 35 y un 40 % la vida y el daño.
- Ninguna criatura pasa de velocidad 52.
- Cada jefe trae `ultimasPalabras` y `ascua`.

Las hojas de sprites están en `assets/sprites/animaciones/enemigos/` y ya figuran en `hojas.json`.

## Minimapa

`assets/minimapa/`:

- **`minimapa-zona-1.png` a `minimapa-zona-6.png`:** el terreno de cada zona, a 1 px por tile.
- **`mapa-mundo-1x.png`:** las seis zonas juntas a la misma escala, para un mapa global dentro del juego. Cada zona está colocada según el lado por el que se sale de la anterior.
- **`mapa-mundo.png`:** el mapa ilustrado a 4x, con nombres, ruta, altares, jefes, cofres, portales y leyenda.
- **`zonas.json`:** el índice. Por cada zona trae:
  - el archivo del mapa y del minimapa;
  - su posición dentro de `mapa-mundo-1x.png` (`mundo.x/y`);
  - sus subzonas;
  - sus marcadores en coordenadas de tile.

En el juego, dibuja el minimapa escalado con filtro *nearest* y pon encima el punto del jugador (`posición / 16`) y los marcadores.
