# Capa DTO (app)

## Qué debe hacer

Cada clase es una **réplica de los documentos de las colecciones `usuarios` y `clases`**, tal como los envía la API en JSON. Son la misma estructura que los DTO del servidor (`servidor/src/dto/`), con dos diferencias:

- `_id` llega como `id` (texto).
- `passwordHash` no existe: nunca sale del servidor.

## Colecciones

`usuarios` lleva todo embebido: cada subdocumento tiene su clase, pero ninguno es una colección aparte. `clases` es la otra colección; el personaje apunta a ella con `claseCodigo` (llave hacia `clases._id`):

```
UsuarioDto                         usuario_dto.dart
├── estado: EstadoUsuario          estado_usuario.dart
├── ajustes: AjustesDto            ajustes_dto.dart
└── partidas: List<PartidaDto>     partida_dto.dart
    └── personaje: PersonajeDto    personaje_dto.dart
        ├── claseCodigo: ClaseCodigo  ──►  ClaseDto (colección clases)
        ├── apariencia: Apariencia         apariencia.dart
        ├── atributos: AtributosDto        atributos_dto.dart
        ├── equipo: EquipoDto              equipo_dto.dart
        ├── ubicacion: UbicacionDto        ubicacion_dto.dart
        ├── mundo: MundoDto                mundo_dto.dart
        └── estadisticas: EstadisticasDto  estadisticas_dto.dart

ClaseDto                           clase_dto.dart
├── id: ClaseCodigo                clase_codigo.dart
└── atributosBase: AtributosBaseDto  atributos_base_dto.dart
```

Al crear un personaje, el servidor copia `atributosBase` de su clase en `personaje.atributos`; después los atributos del personaje evolucionan solos. El nombre, el arma y la descripción no se copian: se buscan en la clase con `ClaseServicio.clase(personaje.claseCodigo)`.

| Archivo | Campos |
|---|---|
| `usuario_dto.dart` | `String id`, `String username`, `String email`, `EstadoUsuario estado`, `DateTime creadoEn`, `DateTime? ultimoLogin`, `DateTime actualizadoEn`, `int versionEsquema`, `AjustesDto ajustes`, `String? partidaActiva`, `List<PartidaDto> partidas` |
| `estado_usuario.dart` | `enum EstadoUsuario { activo, baneado, eliminado }` |
| `ajustes_dto.dart` | `String idioma`, `double musica`, `double efectos` |
| `partida_dto.dart` | `String partidaId`, `DateTime creadaEn`, `DateTime ultimaVezJugada`, `PersonajeDto personaje` |
| `personaje_dto.dart` | `String nombre`, `ClaseCodigo claseCodigo`, `Apariencia apariencia`, `int nivel`, `int exp`, `int puntosLibres`, `int oro`, `AtributosDto atributos`, `int vidaActual`, `int estaminaActual`, `EquipoDto equipo`, `UbicacionDto ubicacion`, `MundoDto mundo`, `EstadisticasDto estadisticas` |
| `atributos_dto.dart` | `int vida`, `int fuerza`, `int destreza`, `int inteligencia` |
| `equipo_dto.dart` | `int nivelArma`, `int nivelArmadura` |
| `ubicacion_dto.dart` | `String zonaId`, `int x`, `int y`, `String? ultimoPuntoGuardado` |
| `mundo_dto.dart` | `List<String> zonasDesbloqueadas`, `List<String> cofresAbiertos`, `List<String> jefesDerrotados` |
| `estadisticas_dto.dart` | `int enemigosDerrotados`, `int muertes`, `int tiempoJugadoSeg` |
| `apariencia.dart` | `enum Apariencia { hombre, mujer }` |
| `clase_codigo.dart` | `enum ClaseCodigo { vagabundo, guerrero, arquero, mago, prisionero }` |
| `clase_dto.dart` | `ClaseCodigo id` (el `_id`), `String nombre`, `String arma`, `String descripcion`, `AtributosBaseDto atributosBase` |
| `atributos_base_dto.dart` | `int vida`, `int fuerza`, `int destreza`, `int inteligencia` |

Solo hay réplicas de las colecciones. Los objetos de la API que no replican ninguna colección (valores de combate, catálogos, progreso) están en [`servicio/modelos/`](../servicio/README.md).

## Qué debe contener cada DTO

- Constructor con todos los campos.
- `fromMap(Map<String, dynamic>)`: convierte el JSON de la API en el objeto. Las fechas llegan en ISO 8601 y se leen con `DateTime.parse`.
- `toMap()`: convierte el objeto en JSON. Las réplicas lo tienen todas, aunque hoy solo se envía `AjustesDto`.
- `ClaseDto` y `AtributosBaseDto` los llaman `fromJson` y `toJson`.
- Los valores con `enum` (`estado`, `claseCodigo`, `apariencia`) se leen con `values.byName` y se escriben con `.name`.

## Qué NO debe hacer

- No hace peticiones ni contiene reglas de negocio o validaciones de interfaz.

## Quién la usa

Servicio y UI.
