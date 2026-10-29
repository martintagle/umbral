# Capa de Servicio (servidor)

## Qué debe hacer

**Llama a los métodos de negocio y los pone a disposición como servicios web** (API REST con Express). Es la única capa de servicio del proyecto: la app solo los consume. Cada ruta comprueba la forma de lo que recibe, llama a un método de negocio y devuelve tal cual lo que este entrega: negocio ya lo da listo para exponer (sin `passwordHash`, con `id` en texto y cada partida con sus valores de combate). Express convierte las fechas a ISO 8601 al enviar el JSON.

## Qué contiene

| Archivo | Contenido |
|---|---|
| `app.ts` | Crea la app de Express, monta las rutas y convierte los errores en respuestas HTTP. |
| `usuario.servicio.ts` | Rutas de `/api/usuarios`. |
| `partida.servicio.ts` | Rutas de `/api/partidas` (todas requieren sesión). |
| `clase.servicio.ts` | `GET /api/clases`: las clases de la colección con lo que tendría un personaje nuevo de cada una. |
| `enemigo.servicio.ts` | `GET /api/enemigos`: lo que da cada enemigo al ser derrotado. |
| `autenticacion.ts` | Firma y comprueba el token JWT de la sesión. |
| `validacion.ts` | Esquemas `zod` con la **forma** de cada petición: tipos, campos obligatorios y enteros de 32 bits. Las reglas de dominio están en negocio. |
| `limites.ts` | Límite de peticiones por IP (general, y más estricto para login y registro). |

## Rutas

| Método | Ruta | Llama a |
|---|---|---|
| POST | `/api/usuarios/registro` | `usuarioNegocio.registrar` → `{ token, usuario }` |
| POST | `/api/usuarios/login` | `usuarioNegocio.iniciarSesion` → `{ token, usuario }` |
| GET | `/api/usuarios/yo` | `usuarioNegocio.obtenerPorId` |
| PUT | `/api/usuarios/yo/ajustes` | `usuarioNegocio.actualizarAjustes` |
| DELETE | `/api/usuarios/yo` | `usuarioNegocio.eliminar` |
| GET | `/api/clases` | `claseNegocio.catalogo` → `{ apariencias, clases: [{ clase, nivel, oroInicial, combate }] }` |
| GET | `/api/enemigos` | `enemigoNegocio.catalogo` |
| GET | `/api/partidas` | `partidaNegocio.listarPartidas` → `[{ partida, combate }]` |
| POST | `/api/partidas` | `partidaNegocio.crearPartida` (`{ nombre, claseCodigo, apariencia }`) → `{ partida, combate }` |
| PUT | `/api/partidas/activa` | `partidaNegocio.seleccionarPartidaActiva` |
| POST | `/api/partidas/:partidaId/progreso` | `partidaNegocio.registrarProgreso` → `{ partida, combate }` |
| POST | `/api/partidas/:partidaId/atributos` | `partidaNegocio.subirAtributos` (`{ vida, fuerza, destreza, inteligencia }`, se paga con experiencia) → `{ partida, combate }` |
| POST | `/api/partidas/:partidaId/mejora` | `partidaNegocio.mejorarEquipo` (`{ pieza: 'arma' \| 'armadura' }`) → `{ partida, combate }` |
| DELETE | `/api/partidas/:partidaId` | `partidaNegocio.eliminarPartida` |

Las rutas con sesión necesitan la cabecera `Authorization: Bearer <token>`.

Los errores se devuelven como `{ "error": "mensaje" }` con este código: 400 datos no válidos, 401 sin sesión o credenciales incorrectas, 403 cuenta baneada, 404 no existe, 409 duplicado, límite alcanzado o guardado simultáneo, y 500 error interno.

## Qué NO debe hacer

- No contiene consultas a Mongo ni usa la conexión.
- No contiene reglas de negocio ni calcula nada: solo comprueba la forma de los datos, llama a negocio y devuelve su resultado.
- No usa los DTO: lo que expone sale de negocio.

```
app (Flutter)  ──HTTP──►  servicio  ──►  negocio
```
