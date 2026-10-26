# Interiores de Umbral

Ocho salas para las estructuras que se pueden visitar, armadas con tiles de 16×16 (`tileset-interiores.png`, 8 columnas: 12 suelos y muros, y luego 26 muebles). Vista de todas las salas: [`vistas/interiores.png`](vistas/interiores.png). Cada sala a 1x: `vistas/interiores/sala-*-1x.png`.

Vista cenital como el mundo:

- Las dos primeras filas de cada sala son la cara del muro del fondo.
- Los bordes laterales e inferior son tope oscuro.
- La salida está abajo, en una alfombra de luz (`umbral-salida`).

| Sala | Estructura | Tamaño | Qué hay | Puntos de interacción |
| --- | --- | --- | --- | --- |
| Choza en ruinas | Choza del norte de la aldea | 10×9 | Chimenea fría, olla, mesa con dos sillas, cama de paja, barril, estante, trampilla | Cofre (pociones), trampilla (sótano futuro) |
| Herrería abandonada | Choza del sur de la aldea | 10×9 | Forja encendida, yunque, mesa, barriles y cajas | **Yunque: abre la pantalla de herrería** |
| Capilla | Capilla | 13×15 | Nave con alfombra, 4 filas de bancos, altar con cruz dorada, candelabros, vitrales, pilares, escombros | **Altar de brasas: abre la pantalla de estadísticas** |
| Torre derruida | Torre de las Ruinas del Sur | 9×10 | Estantes, mesa, escombros, rincones hundidos, escalera hacia arriba | Cofre (Corazón de ceniza), escalera al mirador (futuro) |
| Cripta: antecámara | Entrada de cripta | 12×11 | Cadenas en el muro, sarcófagos con runa `alma`, ataúdes, pilares, montones de calaveras | Escalera abajo a la sala del trono |
| Cripta: osario | Entrada de cripta | 16×14 | Abismos (`vacio`) que obligan a rodear, pilares, ataúdes, calaveras | Cofre (rellena los frascos), 6 criaturas, escalera abajo |
| Cripta: galería de las cadenas | Entrada de cripta | 18×13 | Pasillo con alfombra, filas de sarcófagos, cadenas | **Hoguera** (descansar y subir de nivel), 6 criaturas, escalera abajo |
| Cripta: sala del trono | Entrada de cripta | 17×15 | Arena amplia: alfombra al trono, cuatro pilares, candelabros | **Combate contra el Rey Hueco**; la salida queda sellada por niebla mientras pelea y, vencido, no vuelve |

Paso: los muros y el vacío bloquean. Los muebles también bloquean, salvo `telarana`, `escombro`, `trampilla`, `cadenas` y `vitral`, que son decorado.

## Archivos

| Archivo | Formato | Contenido |
| --- | --- | --- |
| `assets/interiores/tileset-interiores.png` | PNG 128×80 | 38 tiles de 16×16 en 8 columnas: primero los 12 de `tiles.suelo` y luego los 26 de `tiles.objetos` |
| `assets/interiores/interiores.json` | JSON | `salas[]` con `nombre`, `estructura` (sprite del mundo al que pertenece), `ancho`, `alto`, capas `suelo[y][x]` y `objetos[y][x]` (-1 = vacío) y `puntos[]` |

En `puntos[]`, el `tipo` es uno de estos: `salida`, `cofre`, `secreto`, `herreria`, `estadisticas`, `subida`, `bajada`, `jefe`, `hoguera` o `enemigo` (el texto es el id de la criatura). Cada punto lleva sus coordenadas en tiles y un texto.

- Un objeto `j` es el cuadro `indiceObjetos + j` del tileset (columna `n % 8`, fila `n ÷ 8`).
- Entrar por la puerta de una estructura del mundo carga la sala con el mismo `estructura`. Las dos chozas comparten sprite: la del norte (23,15) lleva a *Choza en ruinas* y la del sur (36,25), a *Herrería abandonada*.
- Las salas de la cripta forman la primera mazmorra y se enlazan por escaleras, en el orden del JSON: antecámara → osario → galería → sala del trono.
