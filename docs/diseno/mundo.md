# Tierras del Umbral: diseño del mundo

Mundo semiabierto inspirado en la exploración de *The Minish Cap*:

- La aldea central funciona como eje y hay regiones alrededor.
- Algunos caminos están cerrados hasta conseguir un objeto.
- Hay tocones con runas que te vuelven diminuto.
- Hay secretos que solo se ven siendo pequeño.

Vista completa del mundo con las zonas marcadas: [`vistas/mundo.png`](vistas/mundo.png). Prototipo jugable en el navegador: [`../prototipo/tierras-del-umbral.html`](../prototipo/tierras-del-umbral.html). Se abre con doble clic; los controles son las flechas o WASD, Z para Acción, X para Encoger y M para el Mapa.

## Archivos

| Archivo | Formato | Contenido |
| --- | --- | --- |
| `assets/mapas/mundo.json` | JSON | El mapa completo: capas de tiles, reglas, zonas, portales, estructuras, cofres, fragmentos, letreros, enemigos, jefe e inicio. |
| `assets/tiles/tileset.png` | PNG 128×64 | 30 tiles de 16×16 en 8 columnas: 11 de suelo, 13 de objetos y 6 de entidades, en ese orden. |
| `docs/prototipo/tierras-del-umbral.html` | HTML autónomo | Prototipo jugable de referencia. Toda la lógica está en un solo `<script>`. |

Los sprites de personajes, enemigos y estructuras son los de `assets/sprites/` (ver [`README.md`](README.md)).

## Estructura de `mundo.json`

- `tamanoTile` (16), `ancho` (64) y `alto` (48) se miden en tiles.
- `tiles.suelo`, `tiles.objetos` y `tiles.entidades` dan el nombre de cada tile en orden. Para encontrar un tile en el tileset:
  - un suelo `i` es el cuadro `i`;
  - un objeto `j` es el cuadro `indiceObjetos + j` (11 + j);
  - una entidad es el cuadro `indiceEntidades + k` (24 + k);
  - un cuadro `n` está en la columna `n % 8` y la fila `n ÷ 8`.
- `capas.suelo[y][x]` es el índice de suelo de cada celda, siempre presente.
- `capas.objetos[y][x]` es el índice de objeto de cada celda, o `-1` si no hay. Los objetos se dibujan sobre el suelo y se ordenan por su base junto con los sprites.
- `estructuras` indica qué sprite de `assets/sprites/estructuras/` va en cada lugar:
  - posición y tamaño en tiles (`x`, `y`, `w`, `h`);
  - `huellaFilas`: cuántas filas inferiores bloquean el paso;
  - `puerta`: celdas de esa huella que sí se pueden pisar (la puerta de la cripta).
- El sprite de una estructura se centra en su ancho y se apoya en la fila inferior.
- `cofres`, `fragmentos`, `letreros`, `enemigos`, `portales`, `jefe` e `inicio` usan coordenadas en tiles.

## Reglas de paso

| Elemento | Tamaño normal | Diminuto |
| --- | --- | --- |
| `agua` | Bloquea | Bloquea, salvo si hay un `tronco` encima |
| `muro-roca` | Bloquea | Bloquea |
| `hueco` (muro con agujero) | Bloquea | Pasa |
| `pino`, `arbol-seco`, `roca`, `cerca` | Bloquean | Bloquean |
| `zarza` | Bloquea; con la **Hoz**, Acción la corta (pasa a `zarza-cortada`) | Bloquea y no se puede cortar |
| `reja` | Bloquea; con la **Llave de hueso**, Acción la abre (pasa a `reja-abierta`) | Bloquea |
| `piedra-sellada` | Bloquea hasta entregar 4 fragmentos a la estatua de la aldea (pasa a `escombros`) | Bloquea |
| `portal` (tocón con runas) | Encoger | Crecer |
| Cofres y letreros | Bloquean; Acción los abre o los lee | Los cofres no se pueden abrir |
| Enemigos | Al tocarlos empieza un encuentro | No te ven |
| Fragmentos con `soloDiminuto` | Invisibles | Visibles; se recogen al tocarlos |

En el prototipo, el jugador tiene una caja de colisión en los pies de 10×6 px, o de 4×3 px siendo diminuto. Diminuto, el sprite se dibuja a la mitad de tamaño, la cámara se acerca al doble y la velocidad baja de 72 a 38 px/s.

## Zonas y progresión

| Zona | Tiles | Qué hay | Bloqueo |
| --- | --- | --- | --- |
| Aldea Cenizal (centro) | 22–41 × 15–31 | Inicio en el altar de brasas, capilla, dos chozas, pozo, estatua sin rostro que recibe los fragmentos, jardín amurallado con un hueco | Ninguno |
| Bosque Podrido (norte) | 0–63 × 0–14 | Senderos entre pinos, el cofre de la **Hoz** (9,4) y una arboleda secreta tras un muro con hueco | Ninguno |
| Cementerio de los Callados (este) | 43–62 × 15–34 | Lápidas, árbol de la jaula, cofre de oro y la cripta del jefe | Zarzas en la entrada (42,23–24): requiere la Hoz. Reja de la cripta: requiere la Llave |
| Lago Negro (oeste) | 0–20 × 15–38 | Puente roto, tronco hacia la isla con el cofre de la **Llave de hueso** (10,26), alcoba de roca con hueco | El tronco y el hueco solo se cruzan siendo diminuto |
| Ruinas del Sur | 14–62 × 33–46 | Torre derruida dentro de un recinto amurallado y el cofre del **Corazón de ceniza** (34,43) | La piedra sellada se abre con 4 fragmentos |

Recorrido previsto:

1. Bosque: conseguir la Hoz.
2. Cortar las zarzas del cementerio.
3. Encogerse en el tocón del lago, cruzar el tronco y abrir el cofre de la Llave (el cofre se abre a tamaño normal, así que hay que volver a crecer en un tocón).
4. Reunir los 4 fragmentos de umbral:
   - arboleda del bosque (diminuto);
   - jardín de la aldea (diminuto);
   - alcoba del lago (diminuto);
   - junto al árbol de la jaula (normal).
5. Llevar los fragmentos a la estatua para abrir el sur y conseguir el Corazón de ceniza.
6. Abrir la reja de la cripta y enfrentar al Rey Hueco.

Tocones con runas en (52,6), (30,29), (12,17) y (6,35). Comprobé por búsqueda en la rejilla que cada paso se puede completar y que el cementerio y la isla quedan cerrados hasta tener lo que corresponde.

## Pendiente para el juego real

- Conectar los encuentros con el combate por turnos. En el prototipo, "Luchar" solo elimina al enemigo.
- Animaciones al caminar en cuatro direcciones (hoy los sprites miran de frente y se reflejan al ir a la izquierda).
- Bordes de agua con autotiling.
- Guardado de partida.
