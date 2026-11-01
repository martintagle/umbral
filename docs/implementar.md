# Implementar lo que falta (para Claude Code)

Esta es la guía de trabajo. Las tareas van en orden: cada una deja el juego compilando y funcionando, y la siguiente se apoya en ella. Los nombres de clases y archivos están comprobados contra el código del 31-10-2026. Si algo cambió desde entonces, sigue la intención de la tarea, no la línea exacta.

Los datos ya están en `assets/`; aquí solo hay código. Los documentos de diseño son la referencia del *qué*:

| Documento | Para qué |
| --- | --- |
| `docs/guion.md` | La historia, los dos finales y el tono. |
| `docs/npc-oreste.md` | Los diálogos de Oreste, legibles. |
| `docs/zonas.md` | El formato de los mapas de las zonas 2 a 6. |
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

---

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
- Tras leerlo, aparece un cofre que solo se alcanza encogido, por los troncos desde el portal de la isla N3.
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

## Tarea 9: Comprobación final

- [ ] `flutter analyze` sin avisos nuevos. Pasan las pruebas de la app y las del servidor (`npm test` en `servidor/`, si existen).
- [ ] **Partida nueva con el usuario admin** (`UmbralJuego.admin`: golpes ×10 y estamina infinita):
  - [ ] hablar con Oreste en las 6 zonas;
  - [ ] cumplir los requisitos de cada diálogo (encender altar, abrir el cofre secreto, vencer al jefe);
  - [ ] leer los 22 diálogos.
- [ ] Salir y volver a entrar: los diálogos leídos siguen leídos y Oreste no repite ninguno.
- [ ] Repetir un guardado sin conexión y comprobar que se sincroniza.
- [ ] En la zona 6, encogerse en el portal de N3, cruzar los troncos y abrir el cofre de la astilla junto a la torre.
- [ ] Vencer a El Que Mira, cruzar la salida y ver las dos opciones; elegir «Romper la Brasa».
- [ ] **En otra partida, sin leer todo:** el cofre de la astilla no existe y el final solo ofrece «Encender».
- [ ] En ninguna zona aparece un enemigo junto a Oreste nada más llegar.
- [ ] Actualizar los README de `lib/ui/`, `lib/contrato/`, `servidor/src/dto/` y `servidor/src/negocio/` con los campos y clases nuevos.
