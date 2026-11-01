# Implementar lo que falta (para Claude Code)

Esta es la guía de trabajo. Las tareas van en orden: cada una deja el juego compilando y funcionando, y la siguiente se apoya en ella. Los nombres de clases y archivos están comprobados contra el código del 31-10-2026. Si algo cambió desde entonces, sigue la intención de la tarea, no la línea exacta.

Los datos ya están en `assets/`; aquí solo hay código. Los documentos de diseño son la referencia del *qué*:

| Documento | Para qué |
| --- | --- |
| `docs/guion.md` | La historia, los dos finales y el tono. |
| `docs/npc-oreste.md` | Los diálogos de Oreste, legibles. |
| `docs/zonas.md` | El formato de los mapas de las zonas 2 a 6. |
| `docs/exploracion.md` | Muros agrietados y palancas: cómo funcionan y dónde están. |
| `docs/mazmorras.md` | El formato de las mazmorras. |
| `assets/sprites/animaciones/README.md` | Las hojas de sprites y sus animaciones. |

## Lo que ya funciona (no tocar)

- **Zonas 2 a 6.**
  - `MapaMundo.cargar` lee `assets/mapas/zona-<n>-<id>.json`.
  - `UmbralJuego.cruzarFrontera` carga la zona siguiente o la anterior.
  - Las rejas de `salida.rejaSalida` se abren al vencer al jefe.
- **Mazmorras.** `MapaInteriores` carga `mazmorra-<zona>.json` (lista `_mazmorras`), y `SalaInterior` toma el jefe de `mapa.jefe`.
- **Enemigos y jefes nuevos.** Están en `lib/ui/juego/tipos_enemigo.dart`, con sus `ultimasPalabras` y `ascua`.
- **Minimapa.** Se abre desde las fogatas (`UmbralJuego.verMapa`) con `assets/minimapa/minimapa-zona-<n>.png`.
- **El final.** La salida de la zona 6 (`destino == 'final'`) llama a `alFinal`, y `JuegoPantalla._capaFinal` muestra la elección. **Hay que cambiarla:** tarea 8.

## Datos que cambiaron en esta entrega

Solo hay que recargarlos; el formato no cambia salvo donde se indica.

- **`assets/mapas/zona-2-cienaga.json` … `zona-6-umbral.json`:**
  - Ningún enemigo aparece a menos de 10 casillas de un altar de brasas: son las zonas seguras.
  - La abadía tiene una pasarela de tablas al altar del atrio (antes quedaba aislado por el agua).
  - En `zona-6-umbral.json` hay un cofre nuevo, `cofre-secreto-astilla`, con dos campos nuevos: `requiere` y `nota`. Ver tarea 3.
- **`assets/sprites/animaciones/hojas.json`:** nuevo grupo `npcs`, con `npcs.oreste`.
- **`assets/sprites/animaciones/npcs/`:** `oreste.png` (hoja) y `oreste-retrato.png` (32×32). Ya están en `pubspec.yaml`.
- **`assets/iconos/iconos.png` / `iconos.json`:** icono `astilla-de-nada` (índice 34).
- **`assets/datos/npc-oreste.json`:** todo lo de Oreste. Diálogos, requisitos, posiciones, frases de espera y la misión.
- **Encogerse ya no existe** (entrega del 31-10, por la noche). En los 6 mapas (`mundo.json` incluido):
  - `hueco` pasa a ser `muro-agrietado`;
  - los troncos sobre el agua pasan a ser `pasarela-hundida`;
  - los tocones de runas pasan a ser `palanca`, o desaparecen si no tenían una pasarela cerca.

  Cada mapa trae una lista nueva, `mecanismos`. Los tiles nuevos van al final de cada lista: `indiceObjetos` pasa a 13 e `indiceEntidades` a 28. Los 6 tilesets miden ahora 128×80. `reglas.sueloSoloDiminuto` se queda vacío y `portales` también, para que el código actual siga cargando. Ver tarea 10 y `docs/exploracion.md`.

## Cambio ya hecho en el código: botones de acción del HUD (01-11)

Lo hizo Claude en el chat, sin compilar: **pasa `flutter analyze` y pruébalo** antes de seguir con otra tarea.

- **Fogatas: un solo botón, «Descansar».** Al pulsarlo, se descansa (igual que antes) y se abre el **menú de la fogata**. El menú es una capa a pantalla completa, con el estilo de la pausa, que reúne lo que antes eran varios botones apilados:
  - Subir de nivel (resaltado si se puede);
  - Ver mapa;
  - Salir de la mazmorra o Bajar por el pasadizo, en las hogueras de los custodios;
  - Levantarse.

  Mientras se guarda el descanso, las opciones esperan. El botón «Descansar» se resalta cuando se puede subir de nivel.
  - **`umbral_juego.dart`:** `accionesFogata` devuelve una sola acción, y hay nuevos `menuFogata`, `_descansarEnFogata` y `cerrarMenuFogata`.
  - **`juego_pantalla.dart`:** la capa del menú, y el botón atrás la cierra.
- **Como mucho dos botones de acción a la vez** (por ejemplo, Hablar y Descansar junto a Oreste): `_maximoAcciones`.
- **Los botones ya no parpadean ni saltan.** `_ponerAcciones` solo cambia los botones si el cambio dura 0,25 s, o 0,05 s si antes no había ninguno. Antes, en la sala del custodio, la hoguera y el pasadizo se alternaban cada cuadro al moverse entre ellos.
- **`sala_interior.dart`:** el pasadizo tras el trono del Rey Hueco va dentro del menú de la hoguera cuando está cerca, en lugar de competir con ella.

---

## Cambio ya hecho en el código: cinemáticas (01-11)

Lo hizo Claude en el chat, sin compilar: **pasa `flutter analyze`** y mira las tres cinemáticas en el teléfono.

- **Nuevo** `lib/ui/pantallas/cinematica_pantalla.dart`. Lee `assets/cinematicas/cinematicas.json`; los datos están en `assets/cinematicas/`, que ya está en `pubspec.yaml`.
- **`partidas_pantalla.dart`:** `_nueva` muestra la cinemática `inicio` antes de `_jugar`.
- **`juego_pantalla.dart`:** `_elegirFinal` muestra `final-encender` o `final-romper` y vuelve a la lista de partidas.
- **Detalles:** `docs/cinematicas.md`.

## Tarea 1: Guardar qué diálogos leyó el jugador

Hay que añadir un campo nuevo `dialogosLeidos: string[]` (ids como `oreste-3-2`) que recorra **exactamente el mismo camino que `fogatasEncendidas`**. Es un conjunto que solo crece: el servidor lo une, nunca lo reemplaza.

**App (Dart):**

| Archivo | Cambio |
| --- | --- |
| `lib/contrato/mundo.dart` | Campo `dialogosLeidos` en `Mundo`. En `fromMap` debe tolerar su ausencia (`?? const []`, como `fogatasEncendidas`); va también en `toMap`. |
| `lib/contrato/progreso.dart` | Campo `dialogosLeidos` en `Progreso` y en `toMap`. |
| `lib/ui/juego/registro_progreso.dart` | Un `Set<String> dialogos`, igual que `fogatas`. Lo pasa a `Progreso` y lo descuenta al confirmar el envío, en el mismo sitio donde hace `fogatas.removeAll(...)`. |
| `lib/api/progreso_pendiente.dart` | Sumar y aplicar `dialogosLeidos` igual que `fogatasEncendidas`, con un helper como `_fogatas`. |
| `lib/ui/juego/umbral_juego.dart` | Un `Set<String> _dialogosLeidos` como `_fogatasEncendidas`. Un getter `dialogosLeidos` que una lo guardado (`personaje.mundo.dialogosLeidos`) y lo de la sesión. Un método `leerDialogo(String id)` que lo anota en `_registro` y en el set. Al reiniciar la partida (`_reiniciarTodo`) **no** se borra: no caen al morir. |

**Servidor (TypeScript, `servidor/src/`):**

| Archivo | Cambio |
| --- | --- |
| `dto/mundo.dto.ts` | `dialogosLeidos?: string[]` en `MundoDto`. |
| `servicio/validacion.ts` | En el esquema del progreso: `dialogosLeidos: z.array(z.string().max(32)).max(40).optional()`. |
| `negocio/mundo.negocio.ts` | Nuevo parámetro `dialogos: string[] = []` en `aplicar`. Valida cada id con `/^oreste-[1-6]-[1-9]$/` (si no cumple, `NegocioError`) y une: `dialogosLeidos: [...new Set([...(mundo.dialogosLeidos ?? []), ...dialogos])]`. |
| `negocio/personaje.negocio.ts` | Pasar `progreso.dialogosLeidos ?? []` a `mundoNegocio.aplicar`, junto a las fogatas. Al crear un personaje, `dialogosLeidos: []`. |
| `negocio/sqlite/respaldo-local.ts` | Revisar si copia el mundo campo a campo. Si es así, añadir `dialogosLeidos`. |

**Hecho cuando:**
- Llamar a `leerDialogo('oreste-1-1')`, guardar y volver a entrar deja el id en `personaje.mundo.dialogosLeidos`.
- Lo mismo funciona sin conexión: queda en el pendiente y se envía al volver la red.
- El servidor rechaza un id como `hola`.

## Tarea 2: El cofre de la astilla en el servidor

En `servidor/src/negocio/mundo.negocio.ts`, añade a `COFRES`:

```ts
'umbral/cofre-secreto-astilla': 0,
```

Abrir ese cofre es lo que marca que el jugador tiene la Astilla de nada. No hace falta inventario: `cofreAbierto('umbral/cofre-secreto-astilla')` responde si la tiene.

**Hecho cuando:** guardar con ese cofre abierto no da error y queda en `mundo.cofresAbiertos`.

## Tarea 3: Cofres con requisito

Un cofre del mapa puede traer `requiere`, con el mismo formato que los requisitos de Oreste (ver tarea 4). Hoy solo lo usa `cofre-secreto-astilla`, con `"requiere": "leido:oreste-6-4"`. Mientras el requisito no se cumpla, el cofre **no existe**: no se dibuja, no bloquea el paso y no ofrece «Abrir el cofre».

1. **`lib/ui/juego/mapa_mundo.dart`**
   - Añade `requiere` (`String?`) al registro de `CofreMapa` y léelo en el constructor (`c['requiere'] as String?`).
   - En el bucle que marca `_fijo` con los cofres, salta los que tengan `requiere`.
2. **`lib/ui/juego/zona_tierras.dart`**
   - En `preparar`, no pongas el cofre con requisito.
   - En `accionesEn`, ignóralo mientras no se cumpla.
   - Cuando se cumpla (comprueba en `update`, o llama a un método `mostrarCofresNuevos()` después de cada `leerDialogo`), dibújalo con `_ponerCofre`.
   - **No bloquea aunque esté visible:** sigue sin marcarse en `_fijo`. Es una casilla de un islote; no hace falta que bloquee.
3. **Contenido `astilla-de-nada`:** si `_abrirCofre` trata el contenido de alguna forma especial, este no da oro. Muestra su `texto` con `mostrarAviso`, como los demás cofres.

**Hecho cuando:**
- Con `oreste-6-4` sin leer, la casilla (98, 10) de la zona 6 está vacía.
- Tras leerlo, aparece un cofre que solo se alcanza por el puente que sube la palanca `palanca-1` de la isla N3 (tarea 10).
- Al abrirlo, se anota `umbral/cofre-secreto-astilla`.

## Tarea 4: Cargar los datos de Oreste y evaluar requisitos

Crea `lib/ui/juego/oreste.dart`. Debe cargar `assets/datos/npc-oreste.json` una vez, en `UmbralJuego.onLoad`, y exponer:

```dart
class DialogoOreste { final String id; final int zona; final int orden; final List<String> requiere; final List<String> lineas; }
class DatosOreste {
  static Future<DatosOreste> cargar();
  final List<DialogoOreste> dialogos;
  final Map<int, String> espera;          // frase cuando no hay nada nuevo, por número de zona
  final List<String> trasAstilla;
  final Map<int, (int, int)> posiciones;  // celda (x, y) por número de zona
}
```

**Requisitos.** Cada diálogo trae una lista; todos deben cumplirse. Implementa `bool cumple(String r, UmbralJuego juego, int zona)`:

| Requisito | Se cumple si |
| --- | --- |
| `llegada` | Siempre (basta con estar hablándole en esa zona). |
| `fogata:<zonaId>` | Algún id de las fogatas encendidas (las guardadas y las de la sesión) empieza por `altar:<zonaId>:`. Usa lo mismo que `UmbralJuego.fogataEncendida`. |
| `cofre:<zonaId>/<cofreId>` | `juego.cofreAbierto('<zonaId>/<cofreId>')`. |
| `jefe:<id>` | `juego.jefesDerrotados.contains(id)`. |
| `leido:<id>` | `juego.dialogosLeidos.contains(id)`. |
| `todos` | Los otros 21 diálogos están leídos. |

**Dos consultas para el resto del juego:**
- `DialogoOreste? siguiente(zona)`: el primer diálogo de esa zona no leído cuyos requisitos se cumplen.
- `bool tienePendientes(zona)`: queda algún diálogo no leído en esa zona, se pueda leer ya o no.

**Hecho cuando:** una prueba unitaria con un estado falso (sets de fogatas, cofres, jefes y leídos) comprueba el orden de cada zona y que `todos` solo se cumple con los 21 restantes.

## Tarea 5: Oreste en el mundo

1. **Hoja.** En `UmbralJuego._cargarRecursos` (o en `onLoad`), añade `'npcs/oreste'` a `Hojas.preparar`. El grupo `npcs` ya está en `hojas.json`, así que `Hojas.de('npcs/oreste')` funciona sin más.
2. **Componente.** Crea `class Oreste extends PositionComponent with HasGameReference<UmbralJuego>` en `oreste.dart`. Usa un `ModeloAnimado(Hojas.de('npcs/oreste'), paint: ...)` hijo, anclado en los pies como los enemigos.
   - **Posición:** `MapaMundo.piesEnCelda(x, y)` con la celda de `posiciones[numeroDeZona]`.
   - **Dirección:** mira al jugador volteando en horizontal (`scale.x = -1`), igual que los enemigos.
   - **No es un enemigo y no se le puede golpear.** No lo añadas a las listas de enemigos ni a sus colisiones. No bloquea el paso.
3. **Cuándo está presente.** En `ZonaTierras.preparar`, se añade si se cumple alguna de estas:
   - `datos.tienePendientes(mapa.numero)`;
   - la zona es la más avanzada que el jugador ha desbloqueado (`personaje.mundo.zonasDesbloqueadas`);
   - la zona es la 6 y el jugador ya tiene la astilla (para decir `trasAstilla`).

   Si al cerrar un diálogo no le quedan pendientes en esa zona y no es la más avanzada, reproduce `desvanecerse` y quítalo al terminar. Las salas interiores no tienen Oreste.
4. **Animaciones** (los nombres están en `npc-oreste.json` → `comportamiento.animaciones`):

| Momento | Animación |
| --- | --- |
| Esperando | `quieto` en bucle. Cada 6 a 10 s, `mirar` una vuelta y de nuevo `quieto`. |
| Jugador a menos de 48 px | Se gira hacia él. Si estaba sentado: `levantarse`, luego `quieto`. |
| Jugador descansando en el altar | `sentarse`, luego `sentado` (bucle) hasta que el jugador se mueva. |
| Hablando | `hablar` en bucle mientras el cuadro de diálogo esté abierto. |
| De vez en cuando, sin jugador cerca | `apagar-vela` (no es bucle; vuelve a `quieto` al acabar). |
| Entrar o salir | `aparecer` / `desvanecerse`. |

Las animaciones sin bucle avisan al acabar con `Animacion.cuadroEn`, o lleva tú la cuenta de su duración sumando los `ms`.

**Hecho cuando:**
- En cada zona, Oreste espera bajo techo (capilla, choza o Refugio del Apagador) cerca del primer altar; ver `docs/npc-oreste.md`.
- Se gira hacia el jugador y mira alrededor de vez en cuando.
- Desaparece en ceniza al agotar los diálogos de una zona que ya quedó atrás.

## Tarea 6: La acción «Hablar»

En `ZonaTierras.accionesEn(pies)`, si Oreste está presente y a menos de 24 px de `pies`, añade:

```dart
AccionContexto('Hablar', () => game.hablarConOreste(), boton: 'hablar')
```

El emblema `assets/hud/boton-accion-hablar.png` ya existe. `UmbralJuego.hablarConOreste()` decide qué decir:

| Situación | Qué dice |
| --- | --- |
| Hay `siguiente(zona)` | Ese diálogo completo. |
| Zona 6, con la astilla | `trasAstilla`. |
| Ninguno de los dos | La frase de `espera[zona]`, una sola línea. |

## Tarea 7: El cuadro de diálogo

1. **En `UmbralJuego`:** añade `final dialogo = ValueNotifier<({String nombre, String retrato, List<String> lineas, String? id})?>(null);`. `hablarConOreste` lo rellena, y además:
   - llama a `soltarControles()`;
   - pausa el control del jugador (los enemigos no llegan: es zona segura);
   - pone a Oreste en `hablar`.
2. **En `JuegoPantalla`:** añade un `ValueListenableBuilder` sobre `juego.dialogo`, encima del HUD, como el de `juego.aviso`. Debe tener:
   - **Abajo**, un panel con el estilo de `PanelUmbral` (`lib/ui/widgets/panel_umbral.dart`);
   - **A la izquierda**, el retrato `assets/sprites/animaciones/npcs/oreste-retrato.png` escalado ×3 con `FilterQuality.none`;
   - **Arriba del texto**, el nombre «Oreste» en color `brasa`;
   - **El texto:** una línea cada vez, que aparece letra a letra (unos 30 caracteres por segundo). Tocar la pantalla completa la línea y, si ya estaba completa, pasa a la siguiente;
   - **Al pasar de la última línea:** se cierra y, si `id != null`, llama a `juego.leerDialogo(id)`.
3. **Al cerrar:** se reanuda el control, Oreste vuelve a `quieto` y se comprueba si debe desvanecerse (tarea 5) o si aparece el cofre de la astilla (tarea 3).
4. **Botón atrás de Android:** con el diálogo abierto, lo cierra sin marcarlo como leído.

**Hecho cuando:**
- Los 22 diálogos se pueden leer en orden en una partida completa.
- Cada uno queda guardado al descansar.
- El diálogo 22 (`oreste-6-4`) solo aparece cuando los otros 21 están leídos.

## Tarea 8: El final (sin «apagar»)

En `lib/ui/pantallas/juego_pantalla.dart`:

1. Cambia `enum _Final { eleccion, encender, apagar }` por `enum _Final { eleccion, encender, romper }`.
2. **En `_Final.eleccion`:**
   - El botón «Encender la Brasa» se queda como está.
   - **Quita** «Apagar la Brasa».
   - Añade «Romper la Brasa» (`EstiloBoton.peligro`) **solo si** `_juego.cofreAbierto('umbral/cofre-secreto-astilla')`.
   - «Todavía no» se queda.
   - **Texto de la elección:**
     - sin la astilla: «Las seis ascuas arden en tus manos. La Brasa Primera espera, apagada.»;
     - con la astilla: «Las seis ascuas arden en tus manos. En tu bolsillo, la astilla de nada no pesa.»
3. **`_Final.encender`:**
   - Título: «El Umbral se cierra».
   - Texto: «Enciendes la Brasa y el Umbral se cierra. Te sientas junto al Altar. Primero olvidas el camino, luego las caras, luego la palabra "yo".\n\nEn la aldea Cenizal, las chozas vuelven a tener luz. Junto al altar hay una estatua nueva. No tiene rostro.»
4. **`_Final.romper`:**
   - Título: «El Umbral se abre», en `Colores.sangre`.
   - Texto: «Clavas la astilla en la llama. La Brasa no se apaga: se agrieta, sin ruido, como hielo. Por todo el mundo, los altares se apagan uno a uno, y los que se levantaban se sientan y se quedan quietos. Al borde, Oreste apaga la última vela y dice su nombre en voz alta.\n\nEntras en el Hueco.»
   - Después, en pantalla negra, **el nombre del personaje** (`_juego.personaje.nombre`), letra a letra, centrado. Luego el botón «Volver a las partidas».
   - Sonido: el mismo que hoy usa `apagar` (silencio).

Los textos largos de los dos finales están en `docs/guion.md` → «Los dos finales», por si se quiere hacer una secuencia más elaborada.

**Hecho cuando:**
- Sin la astilla solo se ve «Encender».
- Con la astilla se ven las dos opciones.
- El final de romper muestra el nombre del personaje.

## Tarea 10: Grietas y palancas (sustituyen al encogimiento)

Hazla antes de la comprobación final (tarea 9). La especificación completa está en `docs/exploracion.md`. Los mapas ya traen los datos; aquí se quita el encogimiento y se implementan los dos mecanismos.

### 10.1 Quitar el encogimiento

| Archivo | Qué quitar |
| --- | --- |
| `lib/ui/juego/jugador.dart` | El campo `diminuto`, el `diminuto:` que se pasa a `game.zona.libre(...)` y la escala `* (diminuto ? 0.5 : 1)`. |
| `lib/ui/juego/zona_tierras.dart` | La acción «Encoger/Crecer» de `accionesEn` (bloque `mapa.portales.contains(celda)`), `_cambiarTamano`, las luces azules de los tocones (bucle sobre `mapa.portales`) y el parámetro `diminuto` de `libre`. |
| `lib/ui/juego/escenario.dart` | El parámetro `diminuto` de `libre`, si está en la clase base. |
| `lib/ui/juego/umbral_juego.dart` | `jugador.diminuto = false` en `_cambiarA`. |
| `lib/ui/juego/mapa_mundo.dart` | `_sueloSoloDiminuto`, `_tronco`, `_solidoDiminuto` y `solidoDiminuto()`, y el caso `cruzaDiminuto` de `_calcular`. Se puede mantener la lectura de `portales` (llega vacía) o quitarla. `_portal` sigue existiendo en la lista de objetos, pero ningún mapa lo usa. |

### 10.2 Datos de mecanismos (`mapa_mundo.dart`)

- **Leer `m['mecanismos']`:**

  ```dart
  typedef Mecanismo = ({String id, String tipo, int? x, int? y, List<(int, int)> celdas, String texto});
  ```

  Expón `final List<Mecanismo> mecanismos;`.
- **`cambiarSuelo(x, y, suelo)`:** como `cambiarObjeto`, cambia `suelo[y][x]` y llama a `_calcular(x, y)`.
- **Paso:** `muro-agrietado` y `pasarela-hundida` ya están en `reglas.sueloBloquea`, así que bloquean sin código nuevo. `palanca` y `palanca-activa` bloquean como cualquier objeto que no esté en la lista de transitables. Comprueba que `_calcular` trata los objetos así; si solo bloquean los de `objetosBloquean`, añádelos allí en el código.

### 10.3 Guardar los mecanismos activados

Es el mismo camino que `dialogosLeidos` en la tarea 1: un campo `mecanismosActivados: string[]`, que solo crece, con ids `<zonaId>/<id>` (por ejemplo `umbral/palanca-1`).

- **App:** `Mundo`, `Progreso`, `RegistroProgreso` (un `Set<String> mecanismos`), `progreso_pendiente.dart` y `UmbralJuego`.
  - En `UmbralJuego`: `mecanismoActivado(String id)`, que mira lo guardado más la sesión, y `activarMecanismo(String id)`.
- **Servidor:** `MundoDto`, `validacion.ts` (`z.array(z.string().max(48)).max(200).optional()`), `mundoNegocio.aplicar` (valida con `/^[a-z-]{1,40}\/(palanca|grieta)-\d{1,2}$/` y une) y `personaje.negocio.ts`.
- **Al morir no se deshacen**, igual que las fogatas.

### 10.4 Al preparar la zona (`ZonaTierras.preparar`)

Para cada mecanismo ya activado en la partida, aplica su resultado **antes** de pintar el suelo:

- **Palanca:** `cambiarObjeto(x, y, objeto('palanca-activa'))`, y cada celda a `puente`.
- **Grieta:** cada celda pasa al suelo de una vecina transitable (la primera de arriba, abajo, izquierda o derecha que no bloquee) y lleva el objeto `escombros`.

Añade una luz tenue color brasa (`Luz(..., radio: 14, tinte: Colores.brasa, parpadeo: 1)`) en cada grieta **sin** romper, como antes tenían los tocones.

### 10.5 Palancas

- En `accionesEn`, si a menos de `_distanciaObjeto` hay una palanca sin activar: `AccionContexto('Accionar la palanca', () => _accionarPalanca(m), boton: 'abrir')`.
- **`_accionarPalanca`:**
  1. `game.activarMecanismo('$zonaId/${m.id}')`.
  2. El objeto pasa a `palanca-activa`.
  3. Las `celdas` pasan a `puente` en el orden en que vienen, una cada 60 ms (con un `TimerComponent`), con un `Estallido` pequeño (`Colores.alma` y `Colores.hueso`) en cada una.
  4. `game.mostrarAviso(m.texto)`.
- Cada cambio de suelo tiene que repintar la casilla. Si `_Suelo` dibuja el suelo una sola vez en una imagen, añádele un método que repinte una celda, o vuelve a generar la imagen al terminar la pasarela.

### 10.6 Muros agrietados

- **Cuerpo a cuerpo** (`Jugador._impactar`, rama del tajo): además de los enemigos, mira las celdas de las grietas sin romper de la zona. Si el centro de alguna celda está dentro de `estilo.alcance + 8` y dentro del arco (el mismo cálculo de `diferencia` que con los enemigos), llama a `zona.romperGrieta(m)`.
- **Proyectil del jugador** (`Proyectil`, con `delJugador: true`): al chocar con un sólido, si la celda del choque es de una grieta sin romper, llama a `zona.romperGrieta(m)`.
- **`ZonaTierras.romperGrieta(m)`:**
  1. `game.activarMecanismo('$zonaId/${m.id}')`.
  2. Aplica el cambio de 10.4.
  3. Hace un `Estallido(centro, [Colores.ceniza, Colores.hueso])` y una pequeña sacudida de cámara si ya existe una.
  4. Quita la luz de la grieta y llama a `game.mostrarAviso(m.texto)`.
- Rodar contra la pared no la rompe. Los enemigos tampoco.

### 10.7 Minimapa

`assets/minimapa/` está regenerado: la pasarela hundida se ve como agua y el muro agrietado como muro, así que los secretos no se delatan. `zonas.json` trae marcadores `palanca` y `grieta` en lugar de `portal`. Si `verMapa` dibuja marcadores de portales, cámbialos por palancas.

**Hecho cuando:**
- En la zona 1, un golpe al muro de (56,5) abre la arboleda del bosque, y la palanca de (12,17) sube la pasarela hasta la isla de la Llave.
- En la zona 6, la palanca de (75,16) levanta tabla a tabla un puente de 22 casillas hasta la torre.
- Al guardar, salir y volver, todo sigue abierto.

## Tarea 9: Comprobación final

- [ ] `flutter analyze` sin avisos nuevos. Pasan las pruebas de la app y las del servidor (`npm test` en `servidor/`, si existen).
- [ ] **Partida nueva con el usuario admin** (`UmbralJuego.admin`: golpes ×10 y estamina infinita):
  - [ ] hablar con Oreste en las 6 zonas;
  - [ ] cumplir los requisitos de cada diálogo (encender altar, abrir el cofre secreto, vencer al jefe);
  - [ ] leer los 22 diálogos.
- [ ] Salir y volver a entrar: los diálogos leídos siguen leídos y Oreste no repite ninguno.
- [ ] Repetir un guardado sin conexión y comprobar que se sincroniza.
- [ ] En la zona 6, accionar la palanca de N3 (75,16), cruzar el puente que sube y abrir el cofre de la astilla junto a la torre.
- [ ] **En cada zona:**
  - [ ] romper los muros agrietados con un ataque;
  - [ ] accionar las palancas y ver subir sus pasarelas;
  - [ ] salir y volver a entrar: siguen rotos y levantadas;
  - [ ] los secretos de `docs/exploracion.md` → «Dónde está cada mecanismo» se alcanzan.
- [ ] No queda ningún rastro de encogerse: `rg -i "diminut|encog|portal" lib` solo encuentra comentarios históricos o nada.
- [ ] Vencer a El Que Mira, cruzar la salida y ver las dos opciones; elegir «Romper la Brasa».
- [ ] **En otra partida, sin leer todo:** el cofre de la astilla no existe y el final solo ofrece «Encender».
- [ ] En ninguna zona aparece un enemigo junto a Oreste nada más llegar.
- [ ] Actualizar los README de `lib/ui/`, `lib/contrato/`, `servidor/src/dto/` y `servidor/src/negocio/` con los campos y clases nuevos.
