# Exploración: grietas y palancas

El jugador ya no se encoge. Los secretos de las seis zonas se abren con dos mecanismos del mundo, propios de un souls: **muros agrietados** que se rompen a golpes y **palancas** que levantan pasarelas hundidas. Los dos se quedan resueltos para siempre: una pared rota sigue rota y una pasarela levantada sigue arriba.

Por qué así:

- **No hace falta un segundo modo de juego.** Se acaban el sprite a mitad de tamaño, la otra caja de colisión, la cámara más cerca y los cofres que no se pueden abrir siendo pequeño. El jugador explora siempre con el mismo personaje.
- **Premia mirar con atención.** Una pared con grietas que dejan escapar luz de brasa invita a probar un golpe. Una palanca junto al agua hace preguntarse qué hay al otro lado.
- **Encaja con el tono.** Ruinas, mecanismos viejos y pasadizos olvidados.

## Muro agrietado (`muro-agrietado`)

- **Qué es:** un suelo que sustituye al antiguo `hueco`. Es un muro de roca con grietas por las que sale luz de brasa. Bloquea el paso y los proyectiles, igual que `muro-roca`.
- **Cómo se abre:** cualquier ataque del jugador cuya zona de golpe toque la casilla la rompe.
  - Sirven los cuerpo a cuerpo y los proyectiles de arquero y mago.
  - Rodar contra ella no la rompe.
  - Los enemigos tampoco la rompen.
- **Al romperse:**
  - La casilla pasa al suelo de la casilla vecina transitable (normalmente `camino`, `losa-cripta` o `pasto`) y lleva encima el objeto `escombros`, que se puede pisar.
  - Hay un estallido de polvo de roca (`Estallido` con `ceniza` y `hueso`) y un aviso con el `texto` del mecanismo: «La pared se desmorona. Detrás hay un paso.»
- **Pistas:**
  - Las grietas brillan un poco: un punto de luz de brasa de radio pequeño, con la misma luz de `iluminacion.dart` que usan las fogatas, pero tenue.
  - Algunos letreros lo insinúan.
  - En la zona 1, el letrero del altar dice ahora: «Las paredes agrietadas ceden a un buen golpe.»

## Palanca y pasarela hundida (`palanca` → `pasarela-hundida`)

- **`pasarela-hundida`** es un suelo que sustituye a los antiguos troncos sobre el agua.
  - Se ve como agua con tablas apenas visibles bajo la superficie.
  - Bloquea como el agua.
- **`palanca`** es un objeto que bloquea el paso y está donde antes había un tocón de runas.
  - Al acercarse aparece la acción **«Accionar»** (emblema `assets/hud/boton-accion-abrir.png` hasta que haya uno propio).
- **Al accionar la palanca:**
  1. El objeto pasa a `palanca-activa`.
  2. Cada casilla de su lista `celdas` pasa de `pasarela-hundida` a `puente`, en orden, una cada 60 ms: la pasarela sube tabla a tabla desde la palanca.
  3. Sale un aviso con el `texto` de la palanca. Cada zona tiene el suyo: cera, cabrestante de mina, relicario, asedio, hueso…
- Una palanca solo se acciona una vez. Si el jugador vuelve, la ve accionada y la pasarela arriba.

## Datos en los mapas

Cada mapa (`mundo.json` y `zona-<n>-<id>.json`) trae una lista nueva, **`mecanismos`**:

```json
"mecanismos": [
  { "id": "palanca-1", "tipo": "palanca", "x": 12, "y": 17,
    "celdas": [[10, 18], [10, 19], [10, 20]],
    "texto": "Una palanca de hierro, comida por el óxido. Bajo el agua algo cruje." },
  { "id": "grieta-1", "tipo": "grieta",
    "celdas": [[56, 5]],
    "texto": "La pared se desmorona. Detrás hay un paso." }
]
```

- **Palancas:** `x`, `y` es la casilla de la palanca y `celdas` son las de su pasarela, ordenadas de la orilla al otro extremo.
- **Grietas:** `celdas` son las casillas de muro agrietado que se rompen juntas. Hoy cada grieta tiene una o dos.
- El id que se guarda en la partida es `<zonaId>/<id>`, por ejemplo `cienaga/palanca-2`.

**Tiles nuevos.** Se añadieron al final de cada lista, así que los índices viejos no cambian:

| Lista | Nuevos | Índices |
| --- | --- | --- |
| `tiles.suelo` | `muro-agrietado`, `pasarela-hundida` | 11 y 12 |
| `tiles.objetos` | `palanca`, `palanca-activa` | 13 y 14 |

`indiceObjetos` pasa a 13 e `indiceEntidades` a 28. Los 6 tilesets (`assets/tiles/tileset*.png`) se regeneraron con los 34 tiles y miden ahora 128×80.

**Lo que se conserva por compatibilidad** (el código actual sigue cargando los mapas):

- `reglas.sueloSoloDiminuto` existe, pero vacío.
- `portales` está vacío.
- Los nombres `hueco`, `tronco` y `portal` siguen en las listas, aunque ya ningún mapa los usa.
- `muro-agrietado` y `pasarela-hundida` están en `reglas.sueloBloquea`. Mientras el código no implemente los mecanismos, los secretos quedan cerrados, pero el juego no se rompe.

**Fragmentos.** Los antiguos `soloDiminuto: true` se llaman ahora `oculto: true`. Solo indican que están detrás de un mecanismo; no cambian cómo se recogen.

## Dónde está cada mecanismo

| Zona | Mecanismo | Abre |
| --- | --- | --- |
| 1 Tierras del Umbral | `palanca-1` (12,17) | Pasarela de 7 casillas a la isla del lago, con el cofre de la Llave de hueso |
| 1 | `grieta-1` (56,5) | Arboleda del bosque: fragmento `frag-bosque` |
| 1 | `grieta-2` (4,35) | Alcoba del lago: fragmento `frag-alcoba` |
| 1 | `grieta-3` (25,27) | Jardín amurallado de la aldea: fragmento `frag-jardin` |
| 2 Ciénaga de Cera | `palanca-1` (6,24) | Pasarela de 14 casillas al islote del nido: `frag-nido` |
| 2 | `palanca-2` (31,41) | Islote de las Cunas: `cofre-secreto-cunas` |
| 3 Minas de Sal Negra | `grieta-1` (27,8–9) | Cámara sellada: `frag-camara-sellada` |
| 3 | `palanca-1` (33,34) | Isla del Lago Salobre: `cofre-secreto-lago` |
| 4 Abadía Hundida | `grieta-1` (25,46) | Cripta sellada del ala oeste: `frag-cripta-sellada` |
| 4 | `palanca-1` (10,35) | Plataforma del atrio: `cofre-secreto-atrio` |
| 5 Páramo de Ceniza | `grieta-1` (17,66) | Búnker de las trincheras: `frag-bunker` |
| 5 | `palanca-1` (82,45) | Islote de la charca: `cofre-secreto-charca` |
| 6 El Umbral | `palanca-1` (75,16) | Puente de 22 casillas sobre el vacío hasta la Torre del primer guardián: `frag-torre` y el cofre de la astilla |
| 6 | `palanca-2` (11,34) | Islote del norte de El Borde: `cofre-secreto-islote` |

**Comprobado con búsqueda de alcance en cada mapa:**

- todas las palancas y grietas se alcanzan sin activar nada;
- cada secreto queda cerrado sin el mecanismo y abierto con él.

## Guardado

Los mecanismos activados se guardan en el mundo de la partida como `mecanismosActivados: string[]`, con ids `<zonaId>/<id>`. Siguen el mismo camino que `fogatasEncendidas` y `dialogosLeidos`, y el servidor valida cada id con `/^[a-z-]{1,40}\/(palanca|grieta)-\d{1,2}$/`. Al cargar una zona, se aplican los activados antes de calcular la rejilla de paso.
