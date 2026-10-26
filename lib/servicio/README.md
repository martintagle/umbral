# Capa de Servicio (app)

## Qué debe hacer

Es la puerta de entrada de la UI a los datos: **llama a los servicios de la API** (carpeta `servidor/`) y devuelve DTO. No contiene reglas de negocio: todas están en el servidor.

## Qué contiene

| Archivo | Contenido |
|---|---|
| `api_cliente.dart` | Cliente HTTP: dirección de la API (`--dart-define=API_URL`), cabecera de sesión, envío en JSON y conversión de errores en `ServicioExcepcion`. |
| `sesion_servicio.dart` | Usuario y token de la sesión. Lo abren y cierran los servicios; la UI solo lo lee. Se recuerda en el teléfono hasta cerrar sesión. |
| `preferencias_servicio.dart` | Lo que el teléfono guarda entre aperturas (`shared_preferences`): la última sesión, el usuario con que se entró y el volumen de música y efectos. |
| `usuario_servicio.dart` | Registro, login, cierre de sesión, datos del usuario (actualizan la sesión), ajustes y borrado de la cuenta. |
| `partida_servicio.dart` | Listar, crear, registrar progreso, subir atributos con experiencia, mejorar el equipo con oro, borrar y elegir la partida activa. Cada partida llega con sus valores de combate. Al borrar o elegir la activa, actualiza la sesión. |
| `clase_servicio.dart` | Colección `clases`: se pide una vez al abrir la app y queda en caché. Da el catálogo para crear un personaje y `ClaseServicio.clase(codigo)` para mostrar el nombre, el arma o la descripción de un personaje por su `claseCodigo`. |
| `enemigo_servicio.dart` | Lo que da cada enemigo al ser derrotado (se pide una vez). El juego lo muestra, pero quien lo suma es el servidor. |
| `modelos/` | Objetos de la API que no replican ninguna colección: `Combate` (con el costo en experiencia de los próximos niveles y la `Mejora` de arma y armadura), `PartidaJugable`, `ClaseInicial` (la `ClaseDto` con el nivel, el oro y el combate con que empieza) y `CatalogoClases`, `Progreso` y `Recompensa`. Las réplicas de las colecciones están en [`dto/`](../dto/README.md). |
| `servicio_excepcion.dart` | Error con un mensaje listo para mostrar y el código HTTP (`sesionCaducada` si es 401). |

## Qué NO debe hacer

- No contiene reglas de negocio ni fórmulas: la subida de nivel y los valores de combate los calcula el servidor.
- No contiene widgets ni validaciones de formulario.
- No se conecta a la base de datos.

```
ui  ──►  servicio  ──HTTP──►  API (servidor)
```
