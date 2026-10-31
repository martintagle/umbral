# Contrato de la API (app)

## Qué es

Las clases Dart con la **forma exacta del JSON que la app envía a la API y recibe de ella**. Es el lado de la app del contrato de los servicios del servidor: si cambia una respuesta del servidor, aquí cambia su lectura.

**No es una capa DTO.** La única capa DTO del proyecto es [`servidor/src/dto`](../../servidor/src/dto/README.md), que replica las colecciones de la base de datos. La app nunca toca la base: solo ve lo que expone cada servicio, y eso no siempre coincide con lo guardado:

| En la base (DTO del servidor) | En el contrato (lo que llega a la app) |
|---|---|
| `_id: ObjectId` | `id: String` |
| `passwordHash` | No existe: negocio lo quita antes de exponer el usuario |
| Fechas `Date` | Texto ISO 8601, leído con `DateTime.parse` |
| Solo colecciones | También objetos calculados que no se guardan: `Combate`, `PartidaJugable`, `CatalogoClases`, `Recompensa`; y lo que la app envía: `Progreso` |

## Qué contiene

Lo que llega de cada servicio:

| Servicio | Clase | Archivo |
|---|---|---|
| `/api/usuarios` | `Usuario`, con `EstadoUsuario`, `Ajustes` y sus `Partida` | `usuario.dart`, `estado_usuario.dart`, `ajustes.dart`, `partida.dart` |
| `/api/partidas` | `PartidaJugable`: la `Partida` y su `Combate` (con la `Mejora` de arma y armadura) | `partida_jugable.dart`, `combate.dart` |
| `/api/clases` | `CatalogoClases`: las `Apariencia` y cada `ClaseInicial` (una `Clase` con su nivel, oro y combate iniciales) | `catalogo_clases.dart`, `clase.dart`, `atributos_base.dart`, `clase_codigo.dart`, `apariencia.dart` |
| `/api/enemigos` | `Recompensa` de cada enemigo: su `Categoria` y los rangos de exp y oro que da | `recompensa.dart` |

Partes de la partida: `Personaje` (`personaje.dart`), con `Atributos`, `Equipo`, `Ubicacion`, `Mundo` y `Estadisticas`.

Lo que la app envía: `Progreso` (`progreso.dart`) al guardar; `Atributos` al subir de nivel; `Ajustes` al cambiar el volumen.

Fuera de la API de Umbral: `Actualizacion` (`actualizacion.dart`), la versión y la descarga de la última Release de GitHub.

## Cómo es cada clase

- Constructor con todos los campos.
- `fromMap(Map<String, dynamic>)` lee el JSON; `toMap()` lo escribe (`Clase` y `AtributosBase` los llaman `fromJson` y `toJson`).
- Los valores con `enum` (`estado`, `claseCodigo`, `apariencia`) se leen con `values.byName` y se escriben con `.name`.

## Qué NO hace

- No hace peticiones (eso es [`api/`](../api/README.md)) ni contiene reglas de negocio o validaciones de interfaz.

## Quién la usa

`api/` y la UI.
