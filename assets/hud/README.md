# HUD de Umbral

HUD del jugador en pixel art, sin paneles ni cajas: las piezas van directamente sobre el juego.

- **Vida y estamina:** solo la barra, sin números.
- **EXP y oro:** solo un icono y el número, sin barra.
- **Botones:** emblemas de hierro con un anillo abierto y sin fondo. El frasco es el propio frasco.

Maquetas en `vistas/`: `hud-horizontal.png` (con jefe), `hud-vertical.png` y `piezas.png` (todas las piezas y sus cuadros).

## Formato

- PNG con transparencia a **1x** (1 píxel de imagen = 1 píxel de arte). Se dibujan a escala entera **3x** (`escalaRecomendada` en `hud.json`), con `FilterQuality.none` o `Paint()..filterQuality = FilterQuality.none` en Flame.
- Las piezas con varios estados tienen los **cuadros en fila**, de izquierda a derecha. El cuadro `i` está en `x = i · ancho`.
- `hud.json` lista cada pieza con `archivo`, `ancho`, `alto`, `cuadros` y `nota`. Las barras traen además `relleno` y los botones `areaTactil` (en píxeles de arte; ver Botones).

## Barras (sin números)

Cada barra se dibuja en tres capas: marco, relleno recortado y (solo la vida) el tramo perdido.

1. `vida-marco.png` (80×11): emblema de corazón y canal oscuro.
2. `vida-perdida.png`: se dibuja dentro del canal en (`relleno.x`, `relleno.y`), recortada a `ancho · vidaAnterior`, y se encoge hasta la vida real en unos 0,5 s después de recibir daño.
3. `vida-relleno.png` encima, recortado a `ancho · vida / vidaMaxima`.

`estamina-marco.png` (60×9) tiene 2 cuadros: 0 normal, 1 con el filo en `sangre` cuando no alcanza para un ataque (`sinEstamina`). `estamina-relleno.png` se recorta a `estamina / estaminaMaxima`.

`jefe-marco.png` (120×11, emblema de calavera) y `jefe-relleno.png` (cuadro 0 `sangre`, cuadro 1 `brasa` cuando está furioso). El nombre del jefe va debajo, en texto con sombra dura, sin panel.

| Marco | relleno.x | relleno.y | ancho | alto |
| --- | --- | --- | --- | --- |
| vida | 12 | 3 | 64 | 5 |
| estamina | 10 | 3 | 46 | 3 |
| jefe | 12 | 3 | 104 | 5 |

## EXP y oro (sin barra)

`icono-exp.png` (una brasa) e `icono-oro.png` (una moneda), de 9×9. A su derecha va el número en Silkscreen 12 px con sombra dura de 1 px en `abismo`:

- EXP en `hueso`.
- Oro en `brasa`.
- Miles con punto: 1.240.

Al ganar EXP u oro, el número puede parpadear en `hueso` 2 veces; no hace falta barra ni panel.

## Botones (sin caja)

| Pieza | Tamaño | Cuadros | Uso |
| --- | --- | --- | --- |
| `boton-atacar-<clase>.png` | 34×34 | normal · presionado · sin estamina | Ataque, con el arma de cada clase: vagabundo (katana), guerrero (espadón), arquero (arco), mago (grimorio), prisionero (daga). |
| `boton-rodar.png` | 24×24 | normal · presionado · sin estamina | Rodar. |
| `boton-frasco.png` | 16×20 | con frascos · presionado · vacío | Beber. La cantidad va abajo a la derecha, en `brasa`, sin caja. |
| `boton-accion-<accion>.png` | 24×24 | normal · presionado | Acción del lugar: `descansar` (altar), `entrar` (puertas), `yunque` (herrería), `leer` (letreros), `abrir` (cofres), `hablar`. El texto ("DESCANSAR") va a la izquierda del emblema, en `etiqueta` con sombra, sin panel. |
| `boton-menu.png` | 14×14 | normal · presionado | Pausa, arriba a la derecha. |
| `palanca-base.png` | 44×44 | — | Anillo de runas semitransparente. |
| `palanca-perilla.png` | 16×16 | reposo · arrastrando | Se mueve hasta `recorrido` = 14 px de arte (42 px a 3x) del centro. |

- Presionado: el anillo se vuelve `brasa` y el emblema baja 1 píxel. Sin estamina: anillo `sangre` y arma gris.
- `areaTactil` es el lado del cuadrado tocable en píxeles de arte; es mayor que el dibujo, para que los botones chicos lleguen a 44 px o más en pantalla.
- Los botones de combate actúan al tocar, sin esperar a soltar, como ahora.

## Distribución (márgenes de 6 px de arte = 18 px, más el área segura)

- **Arriba a la izquierda**, una columna: vida, a 1 px la estamina y, debajo, EXP y oro en una línea.
- **Arriba a la derecha**: menú.
- **Arriba al centro** (horizontal) o **bajo las barras** (vertical): barra del jefe mientras dura el combate.
- **Abajo a la izquierda**: palanca.
- **Abajo a la derecha**:
  - atacar en la esquina;
  - rodar a su izquierda, alineado abajo;
  - el frasco sobre rodar;
  - la acción del lugar sobre atacar, con su texto a la izquierda.

## Correspondencia con el HUD actual (`juego_pantalla.dart`)

| Ahora | Con estas piezas |
| --- | --- |
| `_Estado` (panel con nombre, nivel, PV, EST y EXP con números, oro) | Sin panel: `vida-*` y `estamina-*` sin texto; `icono-exp` + número; `icono-oro` + número. El nombre y el nivel pasan a la pantalla de pausa. |
| `_BarraEstamina` con borde rojo si `sinEstamina` | `estamina-marco` cuadro 1; además `boton-atacar` y `boton-rodar` en cuadro 2. |
| `BotonIcono('ajustes')` arriba a la derecha | `boton-menu` |
| `_Joystick` (caja de 136 px) | `palanca-base` + `palanca-perilla` (132 px a 3x; mismo recorrido de ~44 px) |
| `_BotonCombate` frasco y RODAR, botón ATACAR rojo de 96 px | `boton-frasco`, `boton-rodar`, `boton-atacar-<clase>` (102 px a 3x) |
| `juego.acciones` como `BotonUmbral` con texto | `boton-accion-<accion>` + texto suelto a la izquierda |
| `_BarraJefe` | `jefe-marco` + `jefe-relleno` (cuadro 1 si `furioso`) |
