# Tierras del Umbral: diseño del mundo

Mundo semiabierto inspirado en la exploración de *The Minish Cap*:

- La aldea central funciona como eje y hay regiones alrededor.
- Algunos caminos están cerrados hasta conseguir un objeto.
- Hay muros agrietados que se rompen a golpes y palancas que levantan pasarelas hundidas (`../exploracion.md`).
- Hay secretos tras ellos.

Vista completa del mundo con las zonas marcadas: [`vistas/mundo.png`](vistas/mundo.png). Prototipo jugable en el navegador: [`../prototipo/tierras-del-umbral.html`](../prototipo/tierras-del-umbral.html). Se abre con doble clic; los controles son las flechas o WASD, Z para Acción y M para el Mapa. **Es anterior al cambio:** todavía usa el encogimiento (tecla X), que el juego ya no tiene.

## Archivos

| Archivo | Formato | Contenido |
| --- | --- | --- |
| `assets/mapas/mundo.json` | JSON | El mapa completo: capas de tiles, reglas, zonas, mecanismos (palancas y muros agrietados), estructuras, cofres, fragmentos, letreros, enemigos, jefe e inicio. |
| `assets/tiles/tileset.png` | PNG 128×80 | 34 tiles de 16×16 en 8 columnas: 13 de suelo, 15 de objetos y 6 de entidades, en ese orden. |
| `docs/prototipo/tierras-del-umbral.html` | HTML autónomo | Prototipo jugable de referencia. Toda la lógica está en un solo `<script>`. |

Los sprites de personajes, enemigos y estructuras son los de `assets/sprites/` (ver [`README.md`](README.md)).

## Estructura de `mundo.json`

- `tamanoTile` (16), `ancho` (64) y `alto` (48) se miden en tiles.
- `tiles.suelo`, `tiles.objetos` y `tiles.entidades` dan el nombre de cada tile en orden. Para encontrar un tile en el tileset:
  - un suelo `i` es el cuadro `i`;
  - un objeto `j` es el cuadro `indiceObjetos + j` (13 + j);
  - una entidad es el cuadro `indiceEntidades + k` (28 + k);
  - un cuadro `n` está en la columna `n % 8` y la fila `n ÷ 8`.
- `capas.suelo[y][x]` es el índice de suelo de cada celda, siempre presente.
- `capas.objetos[y][x]` es el índice de objeto de cada celda, o `-1` si no hay. Los objetos se dibujan sobre el suelo y se ordenan por su base junto con los sprites.
- `estructuras` indica qué sprite de `assets/sprites/estructuras/` va en cada lugar:
  - posición y tamaño en tiles (`x`, `y`, `w`, `h`);
  - `huellaFilas`: cuántas filas inferiores bloquean el paso;
  - `puerta`: celdas de esa huella que sí se pueden pisar (la puerta de la cripta).
- El sprite de una estructura se centra en su ancho y se apoya en la fila inferior.
- `cofres`, `fragmentos`, `letreros`, `enemigos`, `mecanismos`, `jefe` e `inicio` usan coordenadas en tiles. `portales` sigue en el archivo, vacío.

## Reglas de paso

| Elemento | Paso |
| --- | --- |
| `agua` | Bloquea |
| `muro-roca` | Bloquea |
| `muro-agrietado` | Bloquea hasta recibir un ataque; entonces se rompe y queda `escombros` (ver `../exploracion.md`) |
| `pasarela-hundida` | Bloquea como el agua hasta accionar su palanca; entonces pasa a `puente` |
| `palanca` | Bloquea; «Accionar» la pasa a `palanca-activa` y sube su pasarela |
| `pino`, `arbol-seco`, `roca`, `cerca` | Bloquean |
| `zarza` | Bloquea; con la **Hoz**, Acción la corta (pasa a `zarza-cortada`) |
| `reja` | Bloquea; con la **Llave de hueso**, Acción la abre (pasa a `reja-abierta`) |
| `piedra-sellada` | Bloquea hasta entregar 4 fragmentos a la estatua de la aldea (pasa a `escombros`) |
| Cofres y letreros | Bloquean; Acción los abre o los lee |
| Fragmentos con `oculto` | Están detrás de un muro agrietado o de una pasarela; se recogen al tocarlos |

## Zonas y progresión

| Zona | Tiles | Qué hay | Bloqueo |
| --- | --- | --- | --- |
| Aldea Cenizal (centro) | 22–41 × 15–31 | Inicio en el altar de brasas, capilla, dos chozas, pozo, estatua sin rostro que recibe los fragmentos, jardín amurallado con un muro agrietado | Ninguno |
| Bosque Podrido (norte) | 0–63 × 0–14 | Senderos entre pinos, el cofre de la **Hoz** (9,4) y una arboleda secreta tras un muro agrietado | Ninguno |
| Cementerio de los Callados (este) | 43–62 × 15–34 | Lápidas, árbol de la jaula, cofre de oro y la cripta del jefe | Ninguno por ahora: las zarzas de la entrada (42,23–24) ya están cortadas y la reja de la cripta abierta, hasta que el juego tenga la Hoz y la Llave |
| Lago Negro (oeste) | 0–20 × 15–38 | Puente roto, pasarela hundida hacia la isla con el cofre de la **Llave de hueso** (10,26), alcoba de roca con un muro agrietado | La pasarela sube con la palanca de la orilla (12,17); la alcoba se abre rompiendo su muro |
| Ruinas del Sur | 14–62 × 33–46 | Torre derruida dentro de un recinto amurallado y el cofre del **Corazón de ceniza** (34,43) | La piedra sellada se abre con 4 fragmentos |

Recorrido previsto:

1. Bosque: conseguir la Hoz.
2. Cortar las zarzas del cementerio.
3. Accionar la palanca de la orilla del lago, cruzar la pasarela que sube y abrir el cofre de la Llave.
4. Reunir los 4 fragmentos de umbral:
   - arboleda del bosque (romper el muro agrietado de (56,5));
   - jardín de la aldea (romper el muro agrietado de (25,27));
   - alcoba del lago (romper el muro agrietado de (4,35));
   - junto al árbol de la jaula (normal).
5. Llevar los fragmentos a la estatua para abrir el sur y conseguir el Corazón de ceniza.
6. Abrir la reja de la cripta y enfrentar al Rey Hueco.

Mecanismos: palanca en (12,17) y muros agrietados en (56,5), (25,27) y (4,35). Comprobé por búsqueda en la rejilla que cada uno se alcanza sin activar nada y que cada secreto queda cerrado hasta activarlo.

## Pendiente para el juego real

- Conectar los encuentros con el combate por turnos. En el prototipo, "Luchar" solo elimina al enemigo.
- Animaciones al caminar en cuatro direcciones (hoy los sprites miran de frente y se reflejan al ir a la izquierda).
- Bordes de agua con autotiling.
- Guardado de partida.
