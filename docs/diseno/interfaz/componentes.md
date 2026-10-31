# Interfaz de Umbral: componentes

Catálogo visual: abre [index.html](index.html) en el navegador. Estilos: [interfaz.css](interfaz.css) (clases `ui-*`) sobre [tokens.css](tokens.css). Iconos: `assets/iconos/iconos.png` con su índice en `iconos.json`; en CSS, `<i class="ui-icono ico-espada"></i>`.

Estas piezas son la referencia visual. En Flutter/Flame se reconstruyen como widgets con los mismos tokens; los valores (bordes de 4 px, sombra dura de 4 px, alturas de 44/56 px) se toman de aquí.

## Boton

Botón rectangular con borde de 4 px, esquina astillada y sombra dura. Al presionarlo se hunde 4 px y pierde la sombra: es el único "movimiento" que hace la interfaz.

### Variantes (una sola acción principal por pantalla)

| Clase | Fondo / texto | Cuándo |
| --- | --- | --- |
| `ui-boton` (primario) | `sangre` / `hueso` (5.4:1) | La acción principal: Atacar, Comenzar, Confirmar. |
| `.secundario` | `piedra` con borde `borde` / `hueso` | Volver, Cancelar, alternativas. |
| `.acento` | `brasa` / `abismo` (7.3:1) | Gastar oro o ceniza: Mejorar, Comprar, Subir nivel. Lleva el costo en `.costo`. |
| `.magia` | `alma` / `abismo` (6.7:1) | Hechizos, encoger, todo lo que gasta PM. |
| `.peligro` | `piedra` con borde `sangre` / `hueso` | Acciones destructivas: Descartar, Borrar partida. Siempre con confirmación. |
| `.fantasma` | sin fondo, subrayado | Terciario: Saltar, Más tarde. |

### Estados

Normal, hover (brillo +12 %), foco (contorno `brasa` de 4 px), presionado (`.presionado` o `:active`: se desplaza 4 px y pierde la sombra), deshabilitado (`disabled`: fondo `piedra`, texto `ceniza`, borde punteado). Un botón deshabilitado nunca es la única pista: al lado va el motivo (por ejemplo, "Te falta 1 núcleo de brasa").

### Tamaños

`.grande` 56 px de alto (pantalla de título), normal 44 px (mínimo táctil), `.chico` 32 px visibles con área táctil ampliada a 48 px. `.ancho` ocupa todo el ancho.

### Contenido

Verbo en infinitivo o imperativo corto ("Mejorar", no "Mejorar el arma ahora"). Icono opcional a la izquierda (`ui-icono chico`). El costo va dentro, a la derecha, en `.costo` con su icono de moneda.


## BotonIcono

Botón cuadrado solo con icono, para la barra superior del juego (mochila, mapa, misiones, ajustes) y para acciones repetidas (cerrar, volver, sumar, restar).

- Normal: 48×48 con icono de 32 px. `.chico`: 36×36 con icono de 16 px y área táctil ampliada.
- Siempre lleva `aria-label`: el icono solo no se lee.
- `.insignia` muestra un número pendiente (misiones nuevas, puntos sin gastar) en `sangre`.
- Deshabilitado: opacidad 45 % y sin sombra; para algo bloqueado por progreso usa el icono `candado`.


## BotonTactil

Controles en pantalla para jugar con el pulgar en el teléfono.

- `ui-palanca`: círculo de 112 px abajo a la izquierda; la perilla sigue al dedo hasta el borde y se vuelve `hueso` mientras está activa (`.activa`).
- `ui-tactil.a` (`sangre`, 64 px): Acción. Arriba a la derecha del grupo, bajo el pulgar.
- `ui-tactil.b` (`alma`, 64 px): Encoger / Crecer o la acción especial de la zona.
- `ui-tactil.c` (`piedra`, 48 px): menú rápido.
- Al tocar se hunden 4 px. Separación mínima de 12 px entre botones y márgenes con `env(safe-area-inset-*)`.
- Solo se muestran con puntero táctil (`pointer: coarse`); con teclado se muestra la línea de atajos.


## Pestanas

Pestañas que cambian la categoría de una lista (Herrería, Inventario). Máximo 4; todas del mismo ancho.

- Inactiva: fondo `abismo`, texto `ceniza`. Activa: fondo `piedra` unido al panel de abajo, texto `brasa`.
- Etiqueta en `cifras` mayúsculas, con icono chico opcional.
- `role="tablist"` / `role="tab"` / `aria-selected`. En mando o teclado se cambian con los gatillos o Q/E.


## Interruptor

Encendido / apagado para ajustes. La etiqueta a la izquierda ocupa todo el ancho; toda la fila es tocable (44 px de alto).

- Apagado: riel `abismo` con borde `borde`, bloque `ceniza` a la izquierda.
- Encendido: borde y bloque `brasa`, bloque a la derecha. El cambio es en 2 pasos (`steps(2)`), sin deslizamiento suave.
- Es un `<input type="checkbox">` real, oculto visualmente; el foco se dibuja en el riel.


## Selector

Restar / valor / sumar. Se usa para repartir puntos de estadística y para elegir cantidades (comprar 5 pociones).

- El valor va en `cifras` 16 px. Si difiere del valor guardado se pinta `brasa` (`.sube`).
- Restar se deshabilita al llegar al valor guardado; sumar, al no alcanzar el recurso o llegar al tope (99).
- Mantener presionado repite cada 120 ms.


## MenuPrincipal

Pantalla de título: nombre del juego en `titulo-juego`, debajo un panel con la lista de opciones.

- Opciones en `ui-opcion` (48 px de alto). La seleccionada lleva cursor triangular `brasa` y fondo `brasa` al 12 %.
- "Continuar" muestra a la derecha, en `atajo`, el nivel y el último lugar de descanso.
- Lo bloqueado se ve `ceniza` con candado, nunca se oculta.
- Fondo del juego: la escena del altar de brasas con la viñeta oscura.


## MenuPausa

Menú del juego en pausa: panel `piedra` con encabezado y botón de cerrar, lista de opciones con icono a la izquierda y atajo o aviso a la derecha.

- Orden fijo: Inventario, Equipo, Estado, Mapa, Misiones, Ajustes, Volver al título.
- "Volver al título" pide confirmación (ver `Confirmacion`).
- En teléfono ocupa el centro con 16 px de margen; con mando o teclado, arriba/abajo mueve el cursor.


## MenuCombate

Barra inferior del combate por turnos, al alcance del pulgar.

- Arriba, el estado del grupo: nombre, barras de PV (`sangre`) y PM (`alma`) con su número. El personaje con el turno lleva el cursor y el nombre en `brasa`.
- Abajo, cuatro acciones en rejilla 2×2, botones `.grande`: Atacar (primario), Hechizos (magia), Objetos y Defender (secundarios).
- Huir es `.fantasma` y queda aparte para no tocarlo por error.
- Elegir Hechizos u Objetos abre una lista `ui-menu` encima de la rejilla; Volver regresa aquí.


## Inventario

Rejilla de casillas (`ui-rejilla`, 5 columnas en teléfono) y un panel de detalle del objeto elegido.

- Casilla `ui-ranura`: fondo `abismo`, borde `borde`; elegida, doble borde `brasa`.
- Esquinas: arriba a la izquierda el nivel de mejora (`+3`, `brasa`), abajo a la derecha la cantidad (`x4`), arriba a la derecha un cuadrado `brasa` si está equipado.
- Casillas vacías al 50 % para mostrar la capacidad.
- El detalle muestra icono, nombre, tipo y cantidad, una línea de descripción y las acciones posibles en botones `.chico`.


## Dialogo

Caja de diálogo en la parte baja de la pantalla, encima de los controles táctiles.

- Panel `piedra`, texto `cuerpo` (16/24). Máximo 3 líneas por página; tocar o Acción avanza.
- El nombre de quien habla va en una etiqueta `brasa` pegada al borde superior (`.orador`). Letreros y mensajes del sistema no llevan orador.
- Si hay respuestas, aparecen como botones `.secundario` de ancho completo alineados a la izquierda; la de salida es `.fantasma`.
- El texto aparece letra a letra (30 ms); tocar mientras escribe lo completa.


## Confirmacion

Ventana que interrumpe antes de algo irreversible: descartar, vender equipo mejorado, volver al título sin descansar, borrar partida.

- Título como pregunta concreta ("¿Descartar la katana?"), una línea que diga qué se pierde.
- Dos botones del mismo ancho: el seguro a la izquierda (`.secundario`, recibe el foco) y el destructivo a la derecha (`.peligro`) con el mismo verbo del título.
- Fondo del juego oscurecido al 60 %.


## PantallaEstadisticas

Pantalla para subir de nivel. Se abre al usar un **altar de brasas** (el de la aldea y el de la capilla) y gasta **ceniza**, que sueltan los enemigos.

### Estructura (teléfono vertical, 390 px)

1. Cabecera: botón Volver y título `titulo-zona`.
2. Ficha: retrato del personaje a 3x, clase, nivel actual ▶ nivel resultante (en `brasa`), ceniza disponible y una línea con lo que se gasta y lo que queda.
3. Seis atributos en filas: icono, nombre con su efecto en una línea, y `Selector`.
   - Vigor: PV máximos. Espíritu: PM máximos. Fuerza: daño físico, armas pesadas. Destreza: precisión, katanas y arcos. Intelecto: daño mágico. Fortuna: botín y críticos.
4. Tabla de valores derivados (PV, PM, Ataque, Defensa, Magia): los que cambian muestran antes ▶ después en `brasa`.
5. Pie fijo: Restablecer (`.secundario`) y Confirmar (`.acento` con el costo total).

### Reglas

- Cada punto sube un nivel. Costo del nivel n: `round(0.02·n³ + 3.06·n² + 105.6·n − 895)` de ceniza (curva tipo souls; nivel 15 ≈ 1.500).
- Restar solo baja hasta el valor guardado. Sumar se deshabilita si no alcanza la ceniza para el siguiente nivel o el atributo llega a 99.
- Nada se aplica hasta Confirmar. Salir con cambios sin confirmar pide `Confirmacion`.


## PantallaHerreria

Pantalla para mejorar armas y armaduras. Se abre en el **yunque** de la Herrería abandonada (interior de la choza del sur de la aldea). Gasta **oro** y **materiales**.

### Estructura (teléfono vertical, 390 px)

1. Cabecera: Volver, título `titulo-zona` y oro disponible.
2. `Pestanas`: Armas, Armaduras, Otros (anillos y talismanes).
3. Rejilla de equipo: cada casilla con su nivel de mejora; la equipada lleva el cuadrado `brasa`.
4. Detalle del elegido:
   - Nombre y nivel actual ▶ siguiente.
   - Pips de progreso: 10 niveles, los alcanzados en `brasa` y el siguiente en `hueso`.
   - Tabla de valores que cambian (antes ▶ después).
   - Materiales con "tengo/necesito": verde `podredumbre` si alcanza, etiqueta "FALTA" si no.
5. Aviso cuando falta algo (`ui-aviso`): qué falta y dónde conseguirlo.
6. Pie: Mejorar (`.acento`) con el costo en oro. Deshabilitado mientras falte algo.

### Reglas de mejora (propuesta)

| Nivel | Esquirla de hierro | Polvo de alma | Núcleo de brasa | Oro |
| --- | --- | --- | --- | --- |
| +1 a +3 | 2 por nivel | — | — | 20 · nivel² |
| +4 a +6 | 4 | 1 | 1 | 20 · nivel² |
| +7 a +9 | 6 | 2 | 2 | 20 · nivel² |
| +10 | 8 | 3 | 3 | 2.000 |

- Armas: +8 % de ataque por nivel y el efecto (sangrado, magia) sube un 25 %. Armaduras: +6 % de defensa por nivel.
- Mejorar siempre funciona (sin probabilidad de fallo). Al confirmar, el yunque suelta chispas y suena un golpe.


