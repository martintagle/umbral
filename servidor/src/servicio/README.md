# Capa de Servicio (servidor)

## Qué debe hacer

**Pone a disposición los métodos de negocio como servicios web** (API REST con Express). Cada ruta comprueba la forma de lo que recibe, llama al método de negocio que corresponde y devuelve el resultado en JSON.

## Qué contiene

| Archivo | Contenido |
|---|---|
| `app.ts` | Crea la app de Express, monta las rutas y convierte los errores en respuestas HTTP. |
| `usuario.servicio.ts` | Rutas de `/api/usuarios`. |
| `partida.servicio.ts` | Rutas de `/api/partidas` (todas requieren sesión). |
| `clase.servicio.ts` | `GET /api/clases`: clases para crear un personaje. |
| `enemigo.servicio.ts` | `GET /api/enemigos`: lo que da cada enemigo al ser derrotado. |
| `autenticacion.ts` | Firma y comprueba el token JWT de la sesión. |
| `validacion.ts` | Esquemas `zod` con la **forma** de cada petición: tipos, campos obligatorios y enteros de 32 bits. Las reglas de dominio están en negocio. |
| `respuestas.ts` | Cómo viaja cada DTO en JSON: fechas en ISO, `id` en texto, sin `passwordHash` y cada partida con sus valores de combate. |

## Rutas

| Método | Ruta | Llama a |
|---|---|---|
| POST | `/api/usuarios/registro` | `usuarioNegocio.registrar` → `{ token, usuario }` |
| POST | `/api/usuarios/login` | `usuarioNegocio.iniciarSesion` → `{ token, usuario }` |
| GET | `/api/usuarios/yo` | `usuarioNegocio.obtenerPorId` |
| PUT | `/api/usuarios/yo/ajustes` | `usuarioNegocio.actualizarAjustes` |
| DELETE | `/api/usuarios/yo` | `usuarioNegocio.eliminar` |
| GET | `/api/clases` | `personajeNegocio.catalogo` |
| GET | `/api/enemigos` | `enemigoNegocio.catalogo` |
| GET | `/api/partidas` | `partidaNegocio.listarPartidas` → `[{ partida, combate }]` |
| POST | `/api/partidas` | `partidaNegocio.crearPartida` → `{ partida, combate }` |
| PUT | `/api/partidas/activa` | `partidaNegocio.seleccionarPartidaActiva` |
| POST | `/api/partidas/:partidaId/progreso` | `partidaNegocio.registrarProgreso` → `{ partida, combate }` |
| POST | `/api/partidas/:partidaId/atributos` | `partidaNegocio.subirAtributos` (`{ vida, fuerza, destreza, inteligencia }`, se paga con experiencia) → `{ partida, combate }` |
| POST | `/api/partidas/:partidaId/mejora` | `partidaNegocio.mejorarEquipo` (`{ pieza: 'arma' \| 'armadura' }`) → `{ partida, combate }` |
| DELETE | `/api/partidas/:partidaId` | `partidaNegocio.eliminarPartida` |

Las rutas con sesión necesitan la cabecera `Authorization: Bearer <token>`.

Los errores se devuelven como `{ "error": "mensaje" }` con este código: 400 datos no válidos, 401 sin sesión o credenciales incorrectas, 403 cuenta baneada, 404 no existe, 409 duplicado, límite alcanzado o guardado simultáneo, y 500 error interno.

## Qué NO debe hacer

- No contiene consultas a Mongo ni usa la conexión.
- No contiene reglas de negocio: solo comprueba la forma de los datos y llama a negocio.

```
app (Flutter)  ──HTTP──►  servicio  ──►  negocio
```
