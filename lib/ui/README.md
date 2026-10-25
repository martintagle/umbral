# Capa de Interfaz (UI)

## Qué debe hacer

Muestra las pantallas, recoge lo que escribe el usuario y **solo se comunica con la capa de servicio**.

- Llama a los métodos de `servicio` para leer o guardar datos.
- Hace las **validaciones locales** antes de llamar al servicio: campos obligatorios, formato de correo, longitud mínima, solo números, rangos, fechas válidas, etc.
- Muestra los resultados, los mensajes de error y los estados de carga.

## Qué debe contener

| Carpeta / archivo | Contenido |
|---|---|
| `pantallas/` | Una pantalla por archivo: `<nombre>_pantalla.dart` (por ejemplo, `usuario_lista_pantalla.dart`, `usuario_formulario_pantalla.dart`). |
| `widgets/` | Componentes visuales reutilizables entre pantallas (botones, campos de texto, tarjetas). |
| `validaciones/validaciones.dart` | Funciones de validación locales reutilizables, pensadas para usarlas como `validator` en `TextFormField`. Devuelven `null` si el valor es válido o el texto del error si no lo es. |
| `tema/` | Tokens del sistema de diseño (`docs/diseno/tokens.json`): colores, tipografías, espaciado, radios y sombra dura. |
| `juego/` | El juego en tiempo real, hecho con Flame: la zona (el mapa de `assets/mapas/mundo.json`, de noche, con la luz del jugador y las antorchas en `iluminacion.dart`), jugador, enemigos, proyectiles y efectos. Juega con los valores de combate que da el servidor y anota en `registro_progreso.dart` lo que pasa (exp, oro, enemigos, muertes, tiempo). Al descansar, revivir o salir, la pantalla envía ese registro con `PartidaServicio` y el servidor aplica la subida de nivel. |
| `clases_ui.dart` | Nombre, arma, descripción y sprite de cada clase. Las estadísticas vienen del servicio. |

## Pantallas

| Archivo | Qué hace |
|---|---|
| `titulo_pantalla.dart` | Título "Umbral". Se toca para continuar. |
| `login_pantalla.dart` | Iniciar sesión con correo o usuario, o crear cuenta. |
| `partidas_pantalla.dart` | Lista de partidas: jugar, borrar o crear una nueva. |
| `nuevo_personaje_pantalla.dart` | Elegir clase, apariencia y nombre, con las estadísticas de la clase. |
| `juego_pantalla.dart` | El juego con su HUD: vida, experiencia, oro, cruceta, ataque, descansar y menú de pausa. |

En el juego también se puede usar el teclado: WASD o flechas para moverse, espacio o J para atacar, E para descansar en el altar y Escape para el menú.

## Qué NO debe hacer

- No hace peticiones HTTP por su cuenta: siempre pasa por `servicio`.
- No ejecuta operaciones de MongoDB.
- No aplica reglas de negocio que dependan de la base de datos (por ejemplo, "este correo ya existe"): eso lo resuelve la capa de negocio y llega como respuesta del servicio.

## Dependencias

```
ui  ──►  servicio
 │
 └──►  dto
```
