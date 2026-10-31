# Mazmorras de los jefes (zonas 2 a 6)

Cada jefe nuevo espera al fondo de su propia mazmorra, como el Rey Hueco en la cripta de la zona 1. Cada mazmorra tiene más salas y más superficie que la anterior. El diseño, el tileset y el tema son distintos en cada una.

| Zona | Mazmorra | Entrada en el mundo | Salas | Tiles | Enemigos |
| --- | --- | --- | --- | --- | --- |
| 1 | Cripta del Rey Hueco (ya existía) | `entrada-de-cripta` | 4 | 845 | 14 |
| 2 | Santuario de la Madre | `santuario-de-cera` | 4 | 1104 | 10 |
| 3 | La Veta Profunda | `bocamina-profunda` | 5 | 1484 | 13 |
| 4 | La Nave Mayor | `portico-de-la-nave` | 5 | 1704 | 13 |
| 5 | Salón del Juramento | `puerta-del-juramento` | 6 | 2280 | 18 |
| 6 | El Altar Mayor | `altar-mayor` | 7 | 2828 | 17 |

Láminas con todas las salas: `docs/diseno/mazmorras/mazmorra-<zona>.png`. Entradas: `docs/diseno/mazmorras/entradas.png`.

## Recorrido de cada mazmorra

### 2. Santuario de la Madre: cera y velas

1. **Vestíbulo de los cirios (14×12):** pasillo de alfombra entre hileras de velas y vitrales.
2. **Sala de las cunas (18×14):** filas de cunas de piedra con velas entre ellas. Hay un cofre en la esquina.
3. **Galería goteante (24×12):** charcos de cera derretida, que no se pueden pisar, te obligan a zigzaguear. Altar de brasas a la entrada.
4. **Altar de la Madre (22×18):** sala redonda rodeada de cera, con un anillo de velas abierto en cuatro pasos. **Jefe: La Madre Cirio.**

### 3. La Veta Profunda: mina de sal

1. **Pozo de bajada (14×14):** puntales, raíles y una vagoneta.
2. **Galería de los raíles (26×12):** túnel largo con roca irregular arriba y abajo, raíles que se pueden pisar y vagonetas.
3. **Caverna de cristales (22×16):** una sima en el centro. Tres pasarelas de madera llevan a un islote con el cofre.
4. **Comedor de los mineros (16×12):** mesas, camas de paja, hoguera y un cofre.
5. **Frente de la veta (24×18):** caverna de bordes irregulares con cristales y puntales. **Jefe: El Capataz de Sal.**

### 4. La Nave Mayor: abadía bajo el agua

1. **Nártex (16×12):** un canal de agua lo cruza, con dos pasarelas de madera. Hay bancos y vitrales.
2. **Scriptorium (22×16):** hileras de estanterías forman un pasillo en zigzag, con atriles. Cofre al fondo.
3. **Cripta de las hermanas (20×18):** inundada. Se cruza por pasarelas en retícula entre sarcófagos.
4. **Campanario (14×20):** sala alta con campanas y cadenas. Hay altar de brasas.
5. **La nave mayor (20×26):** nave larga con dos filas de pilares, bancos, alfombra y el altar al fondo. **Jefe: La Abadesa de las Mil Manos.**

### 5. Salón del Juramento: cuartel bajo el páramo

1. **Puerta del cuartel (16×14):** armaduras vacías, braseros y estandartes.
2. **Armería (24×14):** pasillos entre bastidores de armaduras y cajas. Cofre con arma.
3. **Patio de armas (26×18):** un campo abierto de tierra entre dos filas de braseros, con muchos enemigos.
4. **Barracones (20×14):** camas en dos filas y hoguera.
5. **Sala de los estandartes (20×20):** un laberinto en serpentina. Cofre en un rincón del último tramo.
6. **Salón del juramento (26×22):** sala redonda con anillo de braseros y trono. **Jefe: El Caballero de Ceniza.**

### 6. El Altar Mayor: el vacío

1. **Escalinata de hueso (16×14):** escalinata con el vacío a los lados.
2. **Pasarela sobre el Hueco (28×14):** un solo camino que serpentea sobre el vacío.
3. **Jardín de ojos (22×18):** ojos y raíces por todas partes.
4. **Sala de los espejos (20×20):** retícula simétrica de pilares, con el cofre en el centro.
5. **Islas del Hueco (26×20):** islotes unidos por puentes de una casilla de ancho. Cofre en la isla más lejana.
6. **Antesala (16×14):** el último altar de brasas.
7. **El Altar Mayor (28×24):** un anillo sobre el vacío y una plataforma central, unidos por cuatro puentes. **Jefe final: El Que Mira.**

## Archivos

- **`assets/interiores/mazmorra-<zona>.json`:** las salas.
  - Tiene el mismo formato que `interiores.json`: `tiles`, `reglas` y `salas`.
  - Cada sala trae `suelo`, `objetos`, `puntos` y `slug`.
  - Campos nuevos arriba: `id`, `nombre`, `zona`, `jefe` (el id de `TipoEnemigo`), `estructura` y `tema`.
- **`assets/interiores/tileset-mazmorra-<zona>.png`:** el tileset de esa mazmorra.
  - Los 37 tiles del tileset de interiores, recoloreados para el tema.
  - **Suelos nuevos:**
    - `agua` (bloquea; según el tema es cera derretida, agua o brasas);
    - `suelo-tierra`.
  - **Objetos nuevos:**
    - `velas`, `cera`, `cuna`, `riel`, `vagoneta`, `cristal`, `puntal`, `campana`, `atril`;
    - `armadura`, `estandarte`, `brasero`, `ojo`, `raiz`, `hueso`.
    - `riel` y `hueso` se pueden pisar.
  - Como hay suelos nuevos, `indiceObjetos` cambia: léelo siempre del JSON de cada mazmorra.
- **`assets/sprites/estructuras/<entrada>.png`:** las 5 entradas, a 8x. También están añadidas a `hoja-estructuras.png/json`. Miden 64×48 (4×3 tiles), con `huellaFilas` 2, y la puerta son las dos casillas centrales de abajo.

## Cómo encajan en las zonas

- **La arena es ahora un patio.** Sigue cerrado con la reja de la llave y tiene en el centro la entrada a la mazmorra (una estructura con `puerta`).
- **`jefe` en el mapa** apunta a esa puerta, como en `mundo.json`. Lleva:
  - `x`/`y` y `disparador` en la puerta;
  - `mazmorra`, el id del JSON;
  - `entrada`, el sprite.
- **Al vencer al jefe** se vuelve al patio por las escaleras y se abren las rejas de `salida.rejaSalida`.

## Recorrido de las salas

Las salas se encadenan igual que la cripta: cada sala baja a la siguiente por `bajada` (escalera-baja) y vuelve a la anterior por `salida` (escalera-sube, en el muro de abajo). La `salida` de la primera sala devuelve al mundo.

Cada sala se validó con búsqueda de alcance desde su entrada: se llega a la bajada, al jefe, a los cofres, a las hogueras y a todos los enemigos.

## Lo que el código tiene que adaptar

No toqué el código Dart. Para usar las mazmorras hace falta lo siguiente:

1. **Cargar el archivo de la mazmorra.** `MapaInteriores.cargar()` lee solo `assets/interiores/interiores.json`. Hay que darle la ruta de `mazmorra-<zona>.json`, que tiene el mismo esquema.
2. **Elegir el jefe.** `SalaInterior` crea siempre a `Enemigos.reyHueco` en el punto `jefe`. Hay que leer el campo `jefe` del JSON de la mazmorra y buscarlo con `Enemigos.porId`, después de añadir los jefes de `assets/datos/enemigos-nuevos.json`.
3. **Ambiente.** El sonido de cripta se activa solo con `estructura == 'entrada-de-cripta'`. Las mazmorras nuevas pueden usar el mismo sonido u otro por `tema`.
4. **Puntos `enemigo`.** Su `texto` es el id del enemigo, como en la cripta. Los enemigos nuevos tienen que estar en `Enemigos.porId`.
