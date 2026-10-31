# Cliente de la API (app)

## Qué es

La puerta de entrada de la UI a los datos: **consume los servicios de la API** (carpeta `servidor/`) y devuelve objetos del [contrato](../contrato/README.md).

**No es una capa de servicio.** La única capa de servicio del proyecto es [`servidor/src/servicio`](../../servidor/src/servicio/README.md), que expone los métodos de negocio. Esta carpeta está del otro lado: los llama por HTTP. Además guarda en el teléfono lo que la app necesita entre peticiones (sesión, preferencias y cachés).

## Qué contiene

| Archivo | Contenido |
|---|---|
| `api_cliente.dart` | Cliente HTTP: dirección de la API (`--dart-define=API_URL`), cabecera de sesión, envío en JSON y conversión de errores en `ApiExcepcion`. Si la petición no llega al servidor, la marca `sinConexion`. |
| `usuario_api.dart` | `UsuarioApi` → `/api/usuarios`: registro, login, cierre de sesión, datos del usuario (actualizan la sesión), ajustes y borrado de la cuenta. |
| `partida_api.dart` | `PartidaApi` → `/api/partidas`: listar, crear, registrar progreso, subir atributos con experiencia, mejorar el equipo con oro, borrar y elegir la partida activa. Al borrar o elegir la activa, actualiza la sesión. Sin conexión, lista las partidas del teléfono y guarda allí el progreso; lo envía al volver la red (ver abajo). |
| `clase_api.dart` | `ClaseApi` → `/api/clases`: se pide una vez al abrir la app y queda en caché (también en el teléfono). Da el catálogo para crear un personaje y `ClaseApi.clase(codigo)` para mostrar el nombre, el arma o la descripción de un personaje por su `claseCodigo`. |
| `enemigo_api.dart` | `EnemigoApi` → `/api/enemigos`: lo que da cada enemigo al ser derrotado (se pide una vez y se guarda en el teléfono). El juego lo muestra, pero quien lo suma es el servidor. |
| `almacen_local.dart` | `AlmacenLocal`: base SQLite del teléfono (`sqflite`). Tabla `cache` con la última respuesta de partidas, clases y enemigos; tabla `progreso_pendiente` con el progreso sin enviar de cada partida y usuario. Sin SQLite (pruebas, escritorio), lo guarda en memoria. |
| `progreso_pendiente.dart` | Suma de progresos pendientes de una partida y cómo se ve la partida con ellos mientras no hay conexión. |
| `sincronizacion.dart` | `Sincronizacion`: si hay conexión y cuántas partidas tienen progreso por enviar (para la UI), y el reintento cada 30 s. |
| `actualizacion_api.dart` | `ActualizacionApi`: compara la versión instalada con la última Release de GitHub y devuelve la `Actualizacion` si es más nueva (solo en Android). |
| `sesion.dart` | `Sesion`: usuario y token de la sesión. La abren y cierran las clases de esta carpeta; la UI solo la lee. Se recuerda en el teléfono hasta cerrar sesión. |
| `preferencias.dart` | `Preferencias`: lo que el teléfono guarda entre aperturas (`shared_preferences`): la última sesión, el usuario con que se entró y el volumen de música y efectos. |
| `api_excepcion.dart` | `ApiExcepcion`: error con un mensaje listo para mostrar y el código HTTP (`sesionCaducada` si es 401). |

## Jugar sin conexión

1. Cada respuesta del servidor con partidas, clases o enemigos se guarda en SQLite.
2. Si una petición no llega al servidor (sin internet), la lista de partidas y el catálogo salen de esa copia.
3. Al guardar sin conexión, el progreso se suma al pendiente de esa partida y el juego sigue con la partida como quedará.
4. Al volver la red (al listar, al guardar o en el reintento de cada 30 s), se envía el pendiente y el servidor lo valida y lo guarda en Mongo como cualquier otro progreso. La suma pasa las mismas comprobaciones que cada parte.
5. Antes de subir de nivel o mejorar el equipo se envía lo pendiente: el servidor tiene que contar esa experiencia y ese oro. Esas dos acciones, crear y borrar partidas necesitan conexión.

Guardar y sincronizar van en cola, de uno en uno, así que un progreso no se envía dos veces. Un tiempo de espera agotado no cuenta como sin conexión, porque el servidor pudo haberlo aplicado. Si el servidor rechaza un pendiente (datos no válidos o partida borrada), se descarta. Si la sesión caducó, se conserva hasta volver a entrar con esa cuenta.

## Qué NO hace

- No contiene reglas de negocio ni fórmulas: la subida de nivel y los valores de combate los calcula el servidor. Sin conexión solo suma los hechos del progreso para mostrarlos; el servidor los valida al recibirlos.
- No contiene widgets ni validaciones de formulario.
- No se conecta a la base de datos.

```
ui  ──►  api  ──HTTP──►  servicio (servidor)
```
