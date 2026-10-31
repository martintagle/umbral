# Animaciones de Umbral

Hojas de sprites cuadro a cuadro para los 5 personajes (hombre y mujer), los 21 enemigos, los 6 jefes y los efectos. Están hechas a partir de los mismos sprites, piezas y pivotes de `../animaciones.json`, así que encajan con el arte actual.

## Formato

- PNG con transparencia a **1x**; se dibujan a escala entera (3x recomendada) sin suavizado.
- **Una fila por animación, un cuadro por columna**, de izquierda a derecha. Las celdas que sobran al final de una fila están vacías.
- Celdas: personajes y enemigos de **48×48**, el Rey Hueco de **96×96**, efectos de 32×32 y la onda expansiva de 128×128.
- **Ancla**: el punto de la celda que va sobre la posición del personaje (los pies). Personajes y enemigos: (24, 43). Rey: (48, 91). Efectos: el centro.
- Los personajes miran de frente y actúan **hacia la derecha**, como los sprites actuales. Para la izquierda se refleja en horizontal.
- `hojas.json` trae, por hoja y animación:
  - `fila` y `cuadros`;
  - `ms` (duración de cada cuadro);
  - `bucle`;
  - `eventos`: el índice del cuadro en que ocurre algo, como `impacto`, `soltar`, `disparo`, `cura`, `golpe1`/`golpe2`/`golpe3`, `despega`/`aterriza`, `cambio` o `danio`;
  - `nota`.
- `vistas/` tiene un GIF por hoja con todas sus animaciones en movimiento, para revisarlas.

## Hojas

| Archivo | Celda | Filas: animación (cuadros) |
| --- | --- | --- |
| `personajes/vagabundo-hombre.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (7), 3 rodar (7), 4 beber (6), 5 golpe (3), 6 morir (6) |
| `personajes/vagabundo-mujer.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (7), 3 rodar (7), 4 beber (6), 5 golpe (3), 6 morir (6) |
| `personajes/guerrero-hombre.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (9), 3 rodar (7), 4 beber (6), 5 golpe (3), 6 morir (6) |
| `personajes/guerrero-mujer.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (9), 3 rodar (7), 4 beber (6), 5 golpe (3), 6 morir (6) |
| `personajes/arquero-hombre.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (5), 3 disparo (3), 4 rodar (7), 5 beber (6), 6 golpe (3), 7 morir (6) |
| `personajes/arquero-mujer.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (5), 3 disparo (3), 4 rodar (7), 5 beber (6), 6 golpe (3), 7 morir (6) |
| `personajes/mago-hombre.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (5), 3 disparo (3), 4 rodar (7), 5 beber (6), 6 golpe (3), 7 morir (6) |
| `personajes/mago-mujer.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (5), 3 disparo (3), 4 rodar (7), 5 beber (6), 6 golpe (3), 7 morir (6) |
| `personajes/prisionero-hombre.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (7), 3 rodar (7), 4 beber (6), 5 golpe (3), 6 morir (6) |
| `personajes/prisionero-mujer.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 atacar (7), 3 rodar (7), 4 beber (6), 5 golpe (3), 6 morir (6) |
| `enemigos/ojo-errante.png` | 48×48 | 0 quieto (8), 1 volar (8), 2 morder (8), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/fauce.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 agazaparse (4), 3 salto (4), 4 morder (5), 5 herido (2), 6 aturdido (6), 7 morir (6) |
| `enemigos/polilla-osaria.png` | 48×48 | 0 quieto (8), 1 aletear (8), 2 escupir (5), 3 retroceder (6), 4 herido (2), 5 aturdido (6), 6 morir (6) |
| `enemigos/larva-cirio.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 fuego (6), 3 herido (2), 4 morir (7) |
| `enemigos/manojo.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 agarrar (9), 3 herido (2), 4 aturdido (6), 5 morir (7) |
| `enemigos/ahorcado-fungico.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 farol (7), 3 curarse (6), 4 herido (2), 5 aturdido (6), 6 morir (6) |
| `enemigos/jefe-rey-hueco.png` | 96×96 | 0 quieto (8), 1 caminar (8), 2 barrido (8), 3 salto (9), 4 lluvia (7), 5 enfurecerse (10), 6 quieto-furioso (8), 7 caminar-furioso (8), 8 morir (12) |
| `enemigos/efectos.png` | 32×32 | 0 flecha (2), 1 hechizo (4), 2 polvo (4), 3 fuego (4), 4 ojo (4), 5 impacto (4) |
| `enemigos/onda-expansiva.png` | 128×128 | 0 onda (8) |

## Qué hace cada animación

**Personajes** (iguales para las 5 clases; solo cambian el arma y el brazo):

- `quieto`: respira y baja la cabeza de vez en cuando (en bucle).
- `caminar`: piernas alternas, brazos que se adelantan por turnos, rebote del cuerpo. Un ciclo dura 0,52 s, como el paso actual.
- `atacar`: anticipación, golpe con estela y recuperación. El evento `impacto` marca el cuadro del golpe.
  - **Vagabundo, tajo:** sube el filo sobre el hombro y lo baja en un tajo.
  - **Guerrero, mandoble:** echa el espadón atrás y por encima, y lo deja caer delante. Tiene 9 cuadros: es el más lento.
  - **Prisionero, estocada:** apunta la daga, la recoge y la clava.
  - **Arquero, arco:** lleva el arco al frente y tensa la cuerda con la flecha.
  - **Mago, libro:** alza el libro abierto y tiembla juntando brillo de alma.
- `disparo` (arquero y mago): soltar la flecha o el hechizo con retroceso. El evento `soltar` va en el cuadro 0. Encadénalo tras `atacar`.
- `rodar`: se agacha, rueda en ovillo con 4 giros y se levanta. Los eventos `inmuneDesde`/`inmuneHasta` coinciden con la ventana de invulnerabilidad actual. El desplazamiento lo sigue haciendo el código.
- `beber`: lleva el frasco a la boca con el brazo libre (1 s). El evento `cura` en el cuadro 3 equivale a 0,6 s.
- `golpe`: destello blanco y sacudida (0,2 s). Reemplaza el temblor y el tinte por código.
- `morir`: retrocede, se dobla y cae de lado hacia atrás; suelta el arma. El último cuadro queda fijo.

**Enemigos.** Todos tienen `quieto`, `herido` (destello), `aturdido` (se tambalea con estrellas) y `morir`. Además:

- **Ojo errante:** `volar` en zigzag con los tentáculos colgando; úsala también al desplazarse. `morder` es un combo de dos golpes en que el párpado se cierra como una boca.
- **Fauce:**
  - `caminar` con las patas;
  - `agazaparse` antes del salto;
  - `salto` con el cuerpo estirado;
  - `morder` con las mandíbulas.
- **Polilla osaria:** `aletear` (y `quieto` en el aire); `escupir`, que suelta tres proyectiles de polvo en el evento `disparo`; `retroceder`.
- **Larva cirio:** `caminar` es la ondulación vertical; `fuego` lanza desde las velas. **No tiene `aturdido`**: en su lugar, `herido` es solo el destello.
- **Manojo:** `agarrar`, un combo de tres golpes con los eventos `golpe1-3`. Las siete piezas se balancean en `quieto` y `caminar`.
- **Ahorcado fúngico:** `farol`, dos golpes con el farol; `curarse` (opcional), con esporas verdes. La cabeza y el cuerpo se balancean.

**Rey Hueco:**

- `quieto` y `caminar`: brazos, cabeza y capa en onda.
- `barrido`: echa los brazos atrás y da un golpe amplio inclinando el cuerpo.
- `salto`: se agazapa, salta y aplasta. Los eventos son `despega` y `aterriza`.
- `lluvia`: levanta los brazos, los ojos del pecho se encienden y suelta 7 ojos en abanico (evento `disparo`).
- `enfurecerse`: la transición al bajar de media vida. Tiembla, se hincha, los ojos pasan a brasa y la corona se enciende. Desde el evento `cambio`, usa `quieto-furioso` y `caminar-furioso`.
- `morir`: animación propia. Se tambalea, la corona cae, los ojos se cierran y se desploma en un montón de tela.

**Efectos:**

- `efectos.png`: `flecha`, `hechizo`, `polvo` (polilla), `fuego` (larva), `ojo` (proyectil del rey) e `impacto`. Los proyectiles apuntan a la derecha; se giran hacia su dirección.
- `onda-expansiva.png`: el anillo de brasa con 9 ojos que suelta el rey furioso al aterrizar. Llega a 60 px de radio; el evento `danio` va en el cuadro 2.

## Usarlas en Flame

```dart
final datos = hojas['personajes']['vagabundo-hombre'];
final hoja = await images.load('../sprites/animaciones/${datos['archivo']}');
final a = datos['animaciones']['atacar'];
final anim = SpriteAnimation.variableSpriteList(
  [for (var i = 0; i < a['cuadros']; i++)
    Sprite(hoja, srcPosition: Vector2(i * 48.0, a['fila'] * 48.0), srcSize: Vector2.all(48))],
  stepTimes: [for (final ms in a['ms']) ms / 1000],
  loop: a['bucle'],
);
```

Si una duración del código no coincide (el ataque dura entre 0,24 y 0,42 s según la recarga), escala los `ms` de esa animación para que sumen la duración real.

El juego ya usa estas hojas (`lib/ui/juego/animacion.dart`). `../animaciones.json`, el recorte en piezas de antes, ya no se incluye en la app: se conserva solo como fuente de estas hojas.

## Zonas 2 a 6: enemigos y jefes nuevos

Mismo formato y mismo motor que las hojas anteriores. Sus datos ya están en `hojas.json` (`enemigos` y `efectos`). Las estadísticas sugeridas están en `assets/datos/enemigos-nuevos.json`, y la zona de cada uno en `docs/guion.md`.

**El ancla cambia según la criatura.** Las voladoras y las bajas no apoyan los pies en la misma fila. Léela siempre de `hojas.json`.

| Archivo | Celda | Filas: animación (cuadros) |
| --- | --- | --- |
| `enemigos/enjambre.png` | 48×48 | 0 quieto (8), 1 volar (8), 2 picar (10), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/sapo-lapida.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 agazaparse (3), 3 salto (5), 4 herido (2), 5 aturdido (6), 6 morir (6) |
| `enemigos/ahogado-de-cera.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 golpe (5), 3 herido (2), 4 morir (6) |
| `enemigos/minero-hueco.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 picazo (9), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/gusano-de-sal.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 agazaparse (3), 3 embestir (5), 4 herido (2), 5 aturdido (6), 6 morir (6) |
| `enemigos/cristal-vivo.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 esquirlas (5), 3 herido (2), 4 morir (6) |
| `enemigos/gargola-rota.png` | 48×48 | 0 quieto (8), 1 volar (8), 2 picado (6), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/monja-sin-rostro.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 rezo (5), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/campanero.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 campanada (6), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/estandarte-poseido.png` | 48×48 | 0 quieto (8), 1 volar (8), 2 brasas (5), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/caballo-sin-jinete.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 agazaparse (3), 3 embestida (5), 4 herido (2), 5 aturdido (6), 6 morir (6) |
| `enemigos/soldado-de-ceniza.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 tajos (13), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/boca-del-hueco.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 morder (4), 3 herido (2), 4 morir (6) |
| `enemigos/vigia.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 rayo (5), 3 herido (2), 4 morir (6) |
| `enemigos/sombra-sin-nombre.png` | 48×48 | 0 quieto (8), 1 caminar (8), 2 tajos (9), 3 herido (2), 4 aturdido (6), 5 morir (6) |
| `enemigos/jefe-madre-cirio.png` | 96×96 | 0 quieto (8), 1 caminar (8), 2 barrido (8), 3 salto (9), 4 lluvia (7), 5 enfurecerse (10), 6 quieto-furioso (8), 7 caminar-furioso (8), 8 morir (12) |
| `enemigos/jefe-capataz-de-sal.png` | 96×96 | 0 quieto (8), 1 caminar (8), 2 barrido (8), 3 salto (9), 4 lluvia (7), 5 enfurecerse (10), 6 quieto-furioso (8), 7 caminar-furioso (8), 8 morir (12) |
| `enemigos/jefe-abadesa.png` | 96×96 | 0 quieto (8), 1 caminar (8), 2 barrido (8), 3 salto (9), 4 lluvia (7), 5 enfurecerse (10), 6 quieto-furioso (8), 7 caminar-furioso (8), 8 morir (12) |
| `enemigos/jefe-caballero-de-ceniza.png` | 96×96 | 0 quieto (8), 1 caminar (8), 2 barrido (8), 3 salto (9), 4 lluvia (7), 5 enfurecerse (10), 6 quieto-furioso (8), 7 caminar-furioso (8), 8 morir (12) |
| `enemigos/jefe-el-que-mira.png` | 96×96 | 0 quieto (8), 1 caminar (8), 2 barrido (8), 3 salto (9), 4 lluvia (7), 5 enfurecerse (10), 6 quieto-furioso (8), 7 caminar-furioso (8), 8 morir (12) |
| `enemigos/efectos-2.png` | 32×32 | 0 esquirla (4), 1 brasa (4), 2 rayo (4) |

**Enemigos.** Todos tienen `quieto`, `herido` y `morir`, y casi todos `aturdido`. No lo tienen el ahogado de cera, el cristal vivo, la boca del Hueco y el vigía: son firmes y no se tambalean. Los voladores usan `volar` en lugar de `caminar`. Ataques:

- **Enjambre:** `picar`, tres picotazos (`golpe1-3`).
- **Sapo lápida:** `agazaparse` y `salto`, que aplasta (`golpe`).
- **Ahogado de cera:** `golpe` lento y firme.
- **Minero hueco:** `picazo`, dos golpes.
- **Gusano de sal:** `agazaparse` y `embestir`.
- **Cristal vivo:** `esquirlas`, que suelta un abanico en `disparo` y usa el efecto `esquirla`.
- **Gárgola rota:** `picado`.
- **Monja sin rostro:** `rezo` (`disparo`).
- **Campanero:** `campanada`, con una onda que aturde.
- **Estandarte poseído:** `brasas` (`disparo`, efecto `brasa`).
- **Caballo sin jinete:** `agazaparse` y `embestida`.
- **Soldado de ceniza:** `tajos`, tres golpes.
- **Boca del Hueco:** `morder`, y no se mueve.
- **Vigía:** `rayo` (`disparo`, efecto `rayo`).
- **Sombra sin nombre:** `tajos`, dos golpes.

**Jefes.** Los 5 tienen las mismas 9 filas que el Rey Hueco: `quieto`, `caminar`, `barrido`, `salto` (`despega`/`aterriza`), `lluvia` (`disparo`), `enfurecerse` (`cambio`), `quieto-furioso`, `caminar-furioso` y `morir`. Así el mismo código de jefe sirve para todos. `onda-expansiva.png` también vale para ellos.

**Efectos nuevos:** `efectos-2.png` (32×32) trae `esquirla`, `brasa` y `rayo`, y apuntan a la derecha.
