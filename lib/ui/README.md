# Capa de Interfaz (UI)

## Qué debe hacer

Muestra las pantallas, recoge lo que escribe el usuario y **solo se comunica con el cliente de la API** ([`api/`](../api/README.md)).

- Llama a los métodos de `api/` para leer o guardar datos.
- Hace las **validaciones locales** antes de llamar a la API: campos obligatorios, formato de correo, longitud mínima, solo números, rangos, fechas válidas, etc.
- Muestra los resultados, los mensajes de error y los estados de carga.

## Qué debe contener

| Carpeta / archivo | Contenido |
|---|---|
| `pantallas/` | Una pantalla por archivo: `<nombre>_pantalla.dart` (por ejemplo, `usuario_lista_pantalla.dart`, `usuario_formulario_pantalla.dart`). |
| `widgets/` | Componentes visuales reutilizables entre pantallas, según `docs/diseno/interfaz/componentes.md`: `BotonUmbral` (variantes principal, secundario, acento y peligro, con icono y costo), `BotonIcono`, `SelectorUmbral`, `confirmar` (ventana de confirmación), `IconoUmbral` (set de `assets/iconos/`, cargado en `main`), paneles, campos y sprites. `pieza_hud.dart` dibuja las piezas de `assets/hud/` a 3x (cuadros en fila, barras recortadas y botones que actúan al tocar). |
| `validaciones/validaciones.dart` | Funciones de validación locales reutilizables, pensadas para usarlas como `validator` en `TextFormField`. Devuelven `null` si el valor es válido o el texto del error si no lo es. |
| `tema/` | Tokens del sistema de diseño (`docs/diseno/tokens.json`): colores, tipografías, espaciado, radios y sombra dura. |
| `juego/` | El juego en tiempo real, hecho con Flame. Cada lugar es un `Escenario`: el mundo (`zona_tierras.dart`, el mapa de `assets/mapas/mundo.json`, de noche, con la luz del jugador y las antorchas en `iluminacion.dart`) o una sala interior (`sala_interior.dart`, de `assets/interiores/interiores.json`). Se entra por la puerta de las chozas, la capilla, la torre y la cripta; la cripta baja por una escalera a la sala del trono del Rey Hueco. También están el jugador, los enemigos, los proyectiles y los efectos. Personajes y criaturas se dibujan a la mitad de su tamaño de arte (`escalaSprites`) con un zoom de cámara par, y se animan por código al atacar, recibir daño y morir. Los ataques gastan estamina, que se recupera sola. Juega con los valores de combate que da el servidor y anota en `registro_progreso.dart` lo que pasa (exp, oro, enemigos, muertes, tiempo). Al descansar, revivir o salir, la pantalla envía ese registro con `PartidaApi` y el servidor aplica la subida de nivel. |
| `sonido.dart` | Música y efectos (`flame_audio`, archivos de `assets/audios/`) con el volumen de los ajustes. Hasta que `main` lo inicia no suena nada, y un fallo del audio nunca detiene el juego. |
| `clases_ui.dart` | Sprite, icono del arma, armadura y atributo del arma de cada clase. El nombre, el arma y la descripción vienen de la colección `clases` (`ClaseApi`); las estadísticas, del servidor. |

## Pantallas

| Archivo | Qué hace |
|---|---|
| `titulo_pantalla.dart` | Logo y título "Umbral". Se toca para continuar: si el teléfono recuerda la sesión, va directo a las partidas. |
| `ajustes_pantalla.dart` | Volumen de música y efectos. Se abre desde el título, las partidas y la pausa; se guarda en el teléfono y en la cuenta. |
| `login_pantalla.dart` | Iniciar sesión con correo o usuario, o crear cuenta. |
| `partidas_pantalla.dart` | Lista de partidas: jugar, borrar o crear una nueva. |
| `nuevo_personaje_pantalla.dart` | Elegir clase, apariencia y nombre, con las estadísticas de la clase. |
| `juego_pantalla.dart` | El juego con su HUD de `assets/hud/` (ver su README), sin paneles: barras de vida y estamina sin números, EXP y oro con icono, palanca, atacar con el arma de la clase, rodar, frasco, las acciones del lugar (descansar, entrar, abrir...) con su emblema, la vida del jefe y el menú de pausa, que muestra el nombre y el nivel. Abre las dos pantallas siguientes después de guardar. |
| `estadisticas_pantalla.dart` | Altar de brasas: gasta experiencia para subir vigor, fuerza, destreza o intelecto. Cada punto es un nivel y cuesta más que el anterior, como en Elden Ring. Muestra el costo total y lo que queda antes de confirmar. Se abre en el altar de la aldea y en el de la capilla. |
| `herreria_pantalla.dart` | Yunque de la Herrería abandonada: mejora el arma que porta el personaje o su armadura con oro. Cada mejora cuesta más que la anterior. |

La app funciona solo en horizontal y todas las pantallas están pensadas para ese formato.

En el juego también se puede usar el teclado: WASD o flechas para moverse, espacio o J para atacar, K o Mayús para rodar, Q para beber un frasco, E para la acción del lugar (descansar, entrar, usar el yunque...) y Escape para el menú.

Dificultad: como en un souls, pocos golpes bastan para caer. Rodar gasta estamina y deja unas décimas de invulnerabilidad; los frascos de brasa (3) curan casi media vida y se rellenan al descansar. Al caer, la experiencia y el oro ganados desde el último guardado quedan en el suelo como brasas: se recuperan pisándolas y se pierden si se vuelve a caer antes. Personajes, criaturas, proyectiles y efectos se animan cuadro a cuadro con las hojas de `assets/sprites/animaciones/` (`juego/animacion.dart`, datos en `hojas.json`). Cada acción dura lo que dice el juego y sus cuadros se reparten para que el cuadro del golpe, del disparo o de la cura caiga justo cuando ocurre. El Rey Hueco se detiene a enfurecerse al bajar de media vida.

Enemigos: ninguno corre más que el personaje más lento, y se ven, persiguen y disparan desde menos distancia que antes. Cada uno tiene una categoría (débil, media, fuerte o jefe) que llega del servidor con sus recompensas: en el mundo, cada punto trae de media 2 criaturas débiles, 1,2 medias o 0,6 fuertes, y los refuerzos son casi siempre débiles. A partir del nivel 10, con el nivel crecen su número (hasta un 60 % más), su vida y su daño (hasta el doble) y la frecuencia de los refuerzos.

Economía: cada enemigo da experiencia y oro al azar dentro del rango de su categoría; las más difíciles dan más. La experiencia se gasta en el altar para subir de nivel y el oro, en la herrería. El personaje no lleva objetos: solo su arma y su armadura. Respecto al diseño de `docs/diseno/interfaz/componentes.md`, el altar cobra experiencia en vez de ceniza y sube los cuatro atributos que guarda el servidor (no hay espíritu ni fortuna), y la herrería no usa materiales. El cofre de la Choza en ruinas cura del todo una vez por descanso; el de la torre está vacío; la trampilla y la escalera al mirador solo muestran un aviso.

Fogatas: los altares de brasas del mundo y las hogueras de las salas empiezan apagados; al encenderlos se puede descansar, subir de nivel y ver el mapa de la zona con las fogatas encendidas (no hay minimapa en el HUD). La sala de cada jefe tiene una fogata que aparece al vencerlo y deja salir de la mazmorra. Las criaturas que caen no vuelven hasta descansar (o caer y despertar), aunque se salga de la partida.

Grietas y palancas (`docs/exploracion.md`): los secretos de cada zona están tras un muro agrietado o una pasarela hundida, que vienen en la lista `mecanismos` del mapa (`MapaMundo.mecanismos`). Un tajo o un disparo del jugador rompe el muro (`Escenario.golpearMuros`): pasa al suelo de al lado con escombros. «Accionar la palanca» sube su pasarela tabla a tabla, convertida en puente. Lo activado se guarda (`mecanismosActivados`) y se aplica al cargar la zona, antes de pintar el suelo.

Oreste (`juego/oreste.dart`, datos en `assets/datos/npc-oreste.json`, ver `docs/npc-oreste.md`): espera bajo techo (la capilla, una choza o el Refugio del Apagador, según `posiciones[n].interior`), cerca del primer altar de cada zona en la que le queden diálogos, y siempre en la más avanzada. Las salas sirven a varias zonas, así que `SalaInterior.ponerOreste` lo pone o lo quita al entrar. Las chozas del refugio llevan `interior` en el mapa para decir a qué sala llevan. `DatosOreste` carga los 22 diálogos y evalúa sus requisitos sobre un `EstadoMundo` (lo implementa `UmbralJuego`). La acción «Hablar» abre el cuadro de diálogo (`UmbralJuego.dialogo`), con su retrato y el texto letra a letra; al terminarlo queda leído y se guarda. Al leer el último, aparece el cofre de la astilla de nada (los cofres del mapa pueden llevar `requiere`), que permite romper la Brasa en el final.

## Qué NO debe hacer

- No hace peticiones HTTP por su cuenta: siempre pasa por `api/`.
- No ejecuta operaciones de MongoDB.
- No aplica reglas de negocio que dependan de la base de datos (por ejemplo, "este correo ya existe"): eso lo resuelve la capa de negocio y llega como respuesta de la API.

## Dependencias

```
ui  ──►  api
 │
 └──►  contrato
```
