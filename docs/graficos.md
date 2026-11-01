# Gráficos: texturas, luz, niebla, partículas y vida

Esta pasada mejora cómo se ve el juego sin cambiar los mapas ni las reglas. Todo sigue siendo pixel art: nada se suaviza, y las luces caen en escalones.

**Vista previa jugable:** abre `docs/diseno/graficos/vista-previa.html` en el navegador.
- Tiene tres zonas: Tierras del Umbral, Ciénaga de Cera y Páramo de Ceniza.
- El botón «Efectos» enciende y apaga todo lo nuevo, para comparar.
- La lámina `docs/diseno/graficos/lamina.png` muestra, arriba a la izquierda, cómo se veía antes.

## 1. Texturas (`assets/tiles/`)

Los seis tilesets se redibujaron con más detalle. Tienen el mismo tamaño (128×80), el mismo orden y los mismos índices, así que los mapas no cambian.

- **Pasto:** matas de briznas con sombra al pie y manchas claras y oscuras tramadas.
- **Caminos:** piedritas, grietas y huellas de rueda.
- **Adoquines:** piedras irregulares con luz arriba y sombra abajo, y algo de musgo.
- **Losas de cripta:** losas grandes biseladas.
- **Agua:** ondas tramadas.
- **Puentes:** tablas con veta y clavos.
- **Muros de roca:** son una masa de peñascos vista desde arriba. Donde la roca termina se dibuja una corona clara arriba y la cara del acantilado abajo (ver bordes).
- **Objetos:** se redibujaron pino, árbol seco, zarza, roca, pasto alto, escombros y cofre.

Cada tileset trae tres hojas nuevas al lado:

| Hoja | Qué tiene |
| --- | --- |
| `tileset<-bioma>-variantes.png` | Una fila por suelo (13) con 4 variantes. La columna 0 es la del tileset. |
| `tileset<-bioma>-bordes.png` | Una fila por suelo con 8 columnas: N, S, O, E, NO, NE, SO, SE. Cada una es el filo que ese suelo derrama sobre su vecino. La fila de `muro-roca` tiene la corona (N), la cara del acantilado (S) y los filos (O, E). La última fila (13) es la orilla del agua: sombra de ribera y espuma. |
| `tileset<-bioma>-animados.png` | Filas de 4 cuadros: 0 ondas del agua (transparentes, con margen de 3 px), 1 pasto alto, 2 pino, 3 árbol seco y 4 zarza. |

También hay una textura de niebla nueva, `assets/tiles/niebla.png`: 256×128, blanca, sin costuras y con alfa tramado.

### Cómo se pinta el suelo (`_Suelo` en `zona_tierras.dart`)

El suelo se pinta una sola vez en una imagen del tamaño del mapa. Cada celda pasa por estos pasos:

1. **Variante:** `varianteDe(x, y)` elige una de las 4, siempre la misma para la misma celda. La 0 sale el 52 % de las veces y las otras tres, un 16 % cada una.
2. **Orilla:** si la celda es agua y un vecino es tierra (no un puente), se dibuja la orilla de ese lado.
3. **Bordes:** cada vecino con más precedencia derrama su filo sobre la celda.
   - Precedencia, de menos a más: agua y pasarela (0), adoquín y losa (1), camino (2), tierra de tumba (3), suelo de bosque (4), pasto y pasto-hierba (5).
   - Los muros y los puentes no se mezclan.
   - Una esquina solo se dibuja si ninguno de sus dos lados ya la cubre.
4. **Muro:** si la celda es muro, se dibuja la corona, la cara o el filo de cada lado que da a algo que no es muro.
5. **Sombras:**
   - Bajo un muro caen cuatro filas de sombra.
   - Junto a un muro lateral, un filo oscuro.
   - Pinos, árboles, rocas, piedras selladas y palancas tienen una sombra ovalada al pie.
   - Cada estructura tiene una sombra a lo ancho de su base.

Cuando una celda cambia (un puente que sube o un muro que se rompe), `repintar` vuelve a pintar esa celda y sus 8 vecinas.

### Lo que se mueve

- **`_Animados`** dibuja solo las celdas a la vista:
  - Ondas sobre el agua: cada celda a su propio ritmo, para que el lago no lata entero a la vez.
  - El pasto alto mecido por el viento.
- **`_FilaAlta`** dibuja pinos, árboles secos y zarzas con los cuadros de `-animados.png`.
  - `cuadroMecido(x, y)` hace que las ráfagas crucen el mapa de oeste a este.

### Interiores (`_SueloSala` en `sala_interior.dart`)

Los 6 tilesets de interiores (`assets/interiores/tileset-interiores.png` y los de las 5 mazmorras) tienen suelos y muros redibujados. Están en el mismo lugar y con los mismos índices; los muebles no cambian. Cada uno conserva los colores de su tema: cera, sal, abadía, ceniza y vacío.

- **Madera:** tablas con veta, juntas y nudos.
- **Piedra:** losas biseladas, algunas agrietadas o con musgo.
- **Cripta y tierra:** manchas tramadas, piedritas y algún hueso.
- **Alfombra:** con borde y desgaste.
- **Muros:** sillares con luz arriba y sombra abajo, y el pie más oscuro. La parte de arriba del muro tiene textura tenue.
- **Escaleras:** escalones que se oscurecen hacia abajo.
- **Agua (cera, lava...):** ondas tramadas.

Cada tileset trae `<tileset>-variantes.png`: una fila por suelo con 4 variantes. Las genera `interiores2.py`, que toma la paleta de cada tile original.

Al pintar la sala:

- Cada celda usa una de las 4 variantes de su suelo, elegida igual que en el mundo abierto.
- Bajo los muros cae sombra, y junto a los muros de los lados hay un filo oscuro.
- Los muebles que bloquean tienen sombra al pie.

## 2. Luz (`iluminacion.dart`)

- **La noche tiene color.** Cada clima (ver punto 3) trae un color de noche: azul en las Tierras del Umbral, verde pantano en la Ciénaga, rojizo en el Páramo, violeta en El Umbral.
- **Seis anillos en vez de cuatro.** La penumbra cae en escalones más finos.
- **Halo en cuatro capas**, con un corazón más vivo cerca de la llama.
- **El jugador** lleva una luz de radio 72, apenas tibia.
- **`AportaLuz`** es un mixin para componentes que alumbran mientras existen. `Iluminacion` les pregunta cada cuadro a los hijos de su escenario. Lo usan:
  - las luciérnagas;
  - los proyectiles con `efecto` (orbes, fuego, magia), con una luz de radio 18 de su color. Las flechas no alumbran.
- **`destello(en, radio:, tinte:, duracion:)`** es un fogonazo que se encoge hasta apagarse. Desde fuera se llama con `game.destello(...)`. Se usa en:
  - los golpes (brasa);
  - las muertes (alma);
  - el daño recibido (sangre);
  - el trago del frasco (brasa).
- `Luz.radio` ya no es `final`, porque los destellos lo cambian.

## 3. Clima, niebla, partículas y vida (`ambiente.dart`, nuevo)

`ponerAmbiente(escenario, clima)` pone cinco componentes en el escenario. `ZonaTierras.preparar` y `SalaInterior.onLoad` lo llaman después de añadir la iluminación.

| Componente | Prioridad | Qué hace |
| --- | --- | --- |
| `Niebla` | `prioridadEfectos - 150` | Dos capas de `niebla.png` que el viento arrastra a distinta velocidad y que respiran despacio. Van sobre los sprites y bajo la oscuridad, así que solo se ven donde hay luz. |
| `Particulas` | `- 140` | Lo que flota en el aire y lo que piden los golpes, los pasos y las muertes. |
| `VidaSuelo` | `-(1 << 19)` | Cuervos que picotean y vuelan al acercarse, ratas que cruzan y huyen, y ondas de peces en el agua. |
| `VidaAire` | `- 145` | Polillas que vuelan alrededor de las luces cercanas y luciérnagas que se encienden y apagan con su propia luz. |
| `CapaBrillo` | `- 90` | Por encima de la oscuridad: dibuja todo lo que tiene el mixin `Brilla` (chispas, brasas, luciérnagas, motas), que se ve aunque esté a oscuras. |

`Clima.de(zonaId)` y `Clima.interior(zona)` definen cada lugar:

| Lugar | Noche | Niebla | Aire | Vida |
| --- | --- | --- | --- | --- |
| Tierras del Umbral | azul | fina | ceniza que cae | luciérnagas, cuervos |
| Ciénaga de Cera | verde | espesa y amarilla | esporas que suben (algunas brillan) | muchas luciérnagas |
| Minas de Sal Negra | casi negra | tenue | sal que titila | ratas |
| Abadía Hundida | azul frío | azulada | motas de alma | luciérnagas, cuervos, ratas |
| Páramo de Ceniza | rojiza | parda | brasas y ceniza con viento fuerte | cuervos |
| El Umbral | violeta | violeta | motas oscuras y claras que suben | ninguna |
| Interiores | la de su zona | tenue | polvo que solo se ve a la luz | ratas en cripta, minas y abadía |

**Partículas.** Los atajos de `Particulas`:

- **`polvo(pies, piedra:)`:** polvo de los pasos (cada 0,3 s al caminar) y al rodar.
- **`chispas(en, hacia, critico:)`:** chispas del arma al dar en una criatura y de un proyectil al chocar con un muro.
- **`sangre(en, hacia)`:** gotas que caen.
- **`alma(en, color:)`:** motas que suben al morir algo.
- **`brasas(en)`:** brasas que suben de las fogatas y del trago.

Hay un máximo de 420 partículas vivas. El aire se repone según el área de la vista.

**Fogatas.** Las chispas de los altares (`_Brasas`) suben meciéndose, pasan de amarillo a rojo y a ceniza, y brillan. A veces sueltan una brasa que vuela más lejos. Las antorchas y las hogueras de las salas también echan brasas.

## 4. Movimiento

**Jugador (`jugador.dart`):**
- Sombra ovalada a los pies, que se achica al rodar.
- Se estira al lanzarse a rodar y se aplasta al levantarse y al recibir un golpe, un 12 % durante un instante.
- Al rodar deja una estela azulada (`Estela` en `efectos.dart`) y polvo.
- Recibir un golpe lo sacude 2,5 px, suelta sangre y da un destello rojo.
- Morir sacude la vista 5 px, congela el juego 0,25 s y suelta motas de brasa.

**Criaturas (`enemigo.dart`):**
- Sombra a los pies, del ancho de su `radio`.
- Al recibir un golpe:
  - se aplastan un instante;
  - sueltan chispas y sangre;
  - hay un destello;
  - el juego se congela 0,035 s, o 0,07 s si es crítico;
  - la vista tiembla un poco.
- Al morir suben motas de alma con un destello azul. Si es jefe: 40 motas, sacudida de 6 px y 0,3 s congelado.
- Al aterrizar de un salto tiembla el suelo y se levanta polvo; más fuerte si es jefe.

**Cámara (`umbral_juego.dart`):**
- Ya no sigue al jugador directamente: sigue a `_objetivoCamara`.
- Ese punto va 10 px por delante hacia donde camina y lo alcanza con suavidad (`_suavidad = 7`).
- Queda alineado a los píxeles de pantalla, así que no hay temblor de subpíxel.
- `_seguirConCamara()` la pone de golpe sobre el jugador al cargar y al cruzar una puerta. Reemplaza a los dos `camera.follow(jugador, snap: true)` que había.
- **`sacudir(fuerza, [duracion])`:** sacude la vista. Si ya temblaba más fuerte, sigue con eso.
- **`congelar(segundos)`:** pausa de impacto. Durante ese tiempo el mundo avanza al 6 % de su velocidad; la cámara y la sacudida siguen normales.

## Archivos

| Archivo | Cambio |
| --- | --- |
| `assets/tiles/tileset*.png` | Redibujados; mismo formato. |
| `assets/tiles/tileset*-variantes.png`, `-bordes.png`, `-animados.png` | Nuevos, 18 en total. |
| `assets/tiles/niebla.png` | Nuevo. |
| `lib/ui/juego/ambiente.dart` | Nuevo: `Clima`, `Niebla`, `Particulas`, `VidaSuelo`, `VidaAire`, `CapaBrillo`, `Brilla`. |
| `lib/ui/juego/iluminacion.dart` | Noche con color, anillos, halos, `AportaLuz`, `destello`; las chispas de las antorchas brillan. |
| `lib/ui/juego/escenario.dart` | Campos `iluminacion` y `particulas`; método `esAgua`. |
| `lib/ui/juego/mapa_mundo.dart` | `agua(x, y)` y las rutas de las hojas extra. |
| `lib/ui/juego/zona_tierras.dart` | `_Suelo` nuevo, `_Animados`, `_FilaAlta` mecida, `_Brasas` nuevas, clima. |
| `lib/ui/juego/sala_interior.dart` | Variantes de suelo, sombras, clima, brasas de la hoguera. |
| `assets/interiores/tileset-*.png` y `tileset-*-variantes.png` | Suelos y muros redibujados; 6 hojas de variantes nuevas. |
| `lib/ui/juego/jugador.dart` | Sombra, estirar y aplastar, estela, polvo, reacción a golpes. |
| `lib/ui/juego/enemigo.dart` | Sombra, aplastamiento, chispas, sangre, alma, temblor. |
| `lib/ui/juego/efectos.dart` | `Estela`; los proyectiles dejan rastro y chispean al chocar. |
| `lib/ui/juego/animacion.dart` | `ModeloAnimado.cuadro`. |
| `lib/ui/juego/umbral_juego.dart` | Cámara suave, `sacudir`, `congelar`, `destello`; carga de las hojas nuevas. |

**Lo que no cambió:** las hojas de sprites de personajes, criaturas y jefes (sus cuadros), los muebles de los interiores, el HUD y los mapas. Para ajustar la sensación, todos los números están como constantes con nombre en cada archivo.
