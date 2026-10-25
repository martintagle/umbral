# Capa DTO (app)

## Qué debe hacer

Cada clase es una **réplica de los documentos de la colección `usuarios`**, tal como los envía la API en JSON. Son la misma estructura que los DTO del servidor (`servidor/src/dto/`), con dos diferencias:

- `_id` llega como `id` (texto).
- `passwordHash` no existe: nunca sale del servidor.

## Colección `usuarios`

Hay una sola colección y todo va embebido en el usuario. Cada subdocumento tiene su clase, pero ninguno es una colección aparte:

```
UsuarioDto                         usuario_dto.dart
├── estado: EstadoUsuario          estado_usuario.dart
├── ajustes: AjustesDto            ajustes_dto.dart
└── partidas: List<PartidaDto>     partida_dto.dart
    └── personaje: PersonajeDto    personaje_dto.dart
        ├── atributos: AtributosDto        atributos_dto.dart
        ├── equipo: EquipoDto              equipo_dto.dart
        ├── ubicacion: UbicacionDto        ubicacion_dto.dart
        ├── mundo: MundoDto                mundo_dto.dart
        └── estadisticas: EstadisticasDto  estadisticas_dto.dart
```

| Archivo | Campos |
|---|---|
| `usuario_dto.dart` | `String id`, `String username`, `String email`, `EstadoUsuario estado`, `DateTime creadoEn`, `DateTime? ultimoLogin`, `DateTime actualizadoEn`, `int versionEsquema`, `AjustesDto ajustes`, `String? partidaActiva`, `List<PartidaDto> partidas` |
| `estado_usuario.dart` | `enum EstadoUsuario { activo, baneado, eliminado }` |
| `ajustes_dto.dart` | `String idioma`, `double musica`, `double efectos` |
| `partida_dto.dart` | `String partidaId`, `DateTime creadaEn`, `DateTime ultimaVezJugada`, `PersonajeDto personaje` |
| `personaje_dto.dart` | `String nombre`, `String clase`, `String apariencia` (`hombre`/`mujer`), `int nivel`, `int exp`, `int puntosLibres`, `int oro`, `AtributosDto atributos`, `int vidaActual`, `int estaminaActual`, `EquipoDto equipo`, `UbicacionDto ubicacion`, `MundoDto mundo`, `EstadisticasDto estadisticas` |
| `atributos_dto.dart` | `int vida`, `int fuerza`, `int destreza`, `int inteligencia` |
| `equipo_dto.dart` | `int nivelArma`, `int nivelArmadura` |
| `ubicacion_dto.dart` | `String zonaId`, `int x`, `int y`, `String? ultimoPuntoGuardado` |
| `mundo_dto.dart` | `List<String> zonasDesbloqueadas`, `List<String> cofresAbiertos`, `List<String> jefesDerrotados` |
| `estadisticas_dto.dart` | `int enemigosDerrotados`, `int muertes`, `int tiempoJugadoSeg` |

### Objetos de la API

No replican una colección: se calculan en el servidor o se le envían.

| Archivo | Uso |
|---|---|
| `combate_dto.dart` | Valores de combate de un personaje (vida máxima, exp para subir, daño, defensa, críticos). |
| `partida_jugable_dto.dart` | Lo que devuelve la API por cada partida: `partida` y `combate`. |
| `clase_dto.dart` | Catálogo de clases de `GET /api/clases`. |
| `progreso_dto.dart` | Lo que envía el juego al guardar: lo ocurrido desde el último guardado. |

## Qué debe contener cada DTO

- Constructor con todos los campos.
- `fromMap(Map<String, dynamic>)`: convierte el JSON de la API en el objeto. Las fechas llegan en ISO 8601 y se leen con `DateTime.parse`.
- `toMap()`: convierte el objeto en JSON. Las réplicas lo tienen todas, aunque hoy solo se envían `AjustesDto` y `ProgresoDto`.

## Qué NO debe hacer

- No hace peticiones ni contiene reglas de negocio o validaciones de interfaz.

## Quién la usa

Servicio y UI.
