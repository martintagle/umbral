# Capa de Servicio (app)

## Qué debe hacer

Es la puerta de entrada de la UI a los datos: **llama a los servicios de la API** (carpeta `servidor/`) y devuelve DTO. No contiene reglas de negocio: todas están en el servidor.

## Qué contiene

| Archivo | Contenido |
|---|---|
| `api_cliente.dart` | Cliente HTTP: dirección de la API (`--dart-define=API_URL`), cabecera de sesión, envío en JSON y conversión de errores en `ServicioExcepcion`. |
| `sesion_servicio.dart` | Usuario y token de la sesión. Lo abren y cierran los servicios; la UI solo lo lee. |
| `usuario_servicio.dart` | Registro, login, cierre de sesión, datos del usuario, ajustes y borrado de la cuenta. |
| `partida_servicio.dart` | Listar, crear, registrar progreso, borrar y elegir la partida activa. Cada partida llega con sus valores de combate. |
| `clase_servicio.dart` | Catálogo de clases para crear un personaje (se pide una vez). |
| `servicio_excepcion.dart` | Error con un mensaje listo para mostrar y el código HTTP (`sesionCaducada` si es 401). |

## Qué NO debe hacer

- No contiene reglas de negocio ni fórmulas: la subida de nivel y los valores de combate los calcula el servidor.
- No contiene widgets ni validaciones de formulario.
- No se conecta a la base de datos.

```
ui  ──►  servicio  ──HTTP──►  API (servidor)
```
