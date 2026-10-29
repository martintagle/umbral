# Cliente de la API (app)

## Qué es

La puerta de entrada de la UI a los datos: **consume los servicios de la API** (carpeta `servidor/`) y devuelve objetos del [contrato](../contrato/README.md).

**No es una capa de servicio.** La única capa de servicio del proyecto es [`servidor/src/servicio`](../../servidor/src/servicio/README.md), que expone los métodos de negocio. Esta carpeta está del otro lado: los llama por HTTP. Además guarda en el teléfono lo que la app necesita entre peticiones (sesión, preferencias y cachés).

## Qué contiene

| Archivo | Contenido |
|---|---|
| `api_cliente.dart` | Cliente HTTP: dirección de la API (`--dart-define=API_URL`), cabecera de sesión, envío en JSON y conversión de errores en `ApiExcepcion`. |
| `usuario_api.dart` | `UsuarioApi` → `/api/usuarios`: registro, login, cierre de sesión, datos del usuario (actualizan la sesión), ajustes y borrado de la cuenta. |
| `partida_api.dart` | `PartidaApi` → `/api/partidas`: listar, crear, registrar progreso, subir atributos con experiencia, mejorar el equipo con oro, borrar y elegir la partida activa. Al borrar o elegir la activa, actualiza la sesión. |
| `clase_api.dart` | `ClaseApi` → `/api/clases`: se pide una vez al abrir la app y queda en caché. Da el catálogo para crear un personaje y `ClaseApi.clase(codigo)` para mostrar el nombre, el arma o la descripción de un personaje por su `claseCodigo`. |
| `enemigo_api.dart` | `EnemigoApi` → `/api/enemigos`: lo que da cada enemigo al ser derrotado (se pide una vez). El juego lo muestra, pero quien lo suma es el servidor. |
| `sesion.dart` | `Sesion`: usuario y token de la sesión. La abren y cierran las clases de esta carpeta; la UI solo la lee. Se recuerda en el teléfono hasta cerrar sesión. |
| `preferencias.dart` | `Preferencias`: lo que el teléfono guarda entre aperturas (`shared_preferences`): la última sesión, el usuario con que se entró y el volumen de música y efectos. |
| `api_excepcion.dart` | `ApiExcepcion`: error con un mensaje listo para mostrar y el código HTTP (`sesionCaducada` si es 401). |

## Qué NO hace

- No contiene reglas de negocio ni fórmulas: la subida de nivel y los valores de combate los calcula el servidor.
- No contiene widgets ni validaciones de formulario.
- No se conecta a la base de datos.

```
ui  ──►  api  ──HTTP──►  servicio (servidor)
```
