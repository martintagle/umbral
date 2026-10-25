# Capa DTO (servidor)

## Qué debe hacer

Cada interfaz es una **réplica de la estructura de los documentos** de la colección `usuarios`. Como MongoDB no obliga a seguir un esquema, el DTO y el validador `bd/esquema-usuarios.json` son los que lo definen.

## Colección `usuarios`

Hay una sola colección y todo va embebido en el documento del usuario. Cada subdocumento tiene su interfaz, pero ninguna es una colección aparte:

```
UsuarioDto                         usuario.dto.ts
├── estado: EstadoUsuario          estado-usuario.ts
├── ajustes: AjustesDto            ajustes.dto.ts
└── partidas: PartidaDto[]         partida.dto.ts
    └── personaje: PersonajeDto    personaje.dto.ts
        ├── atributos              atributos.dto.ts
        ├── equipo                 equipo.dto.ts
        ├── ubicacion              ubicacion.dto.ts
        ├── mundo                  mundo.dto.ts
        └── estadisticas           estadisticas.dto.ts
```

| BSON | TypeScript |
|---|---|
| `objectId` (`_id`) | `ObjectId` |
| `int`, `double` | `number` |
| `string` | `string` |
| `date` | `Date` |
| `array` | `T[]` |
| `["string", "null"]` | `string \| null` |

Solo hay réplicas de la colección. Los objetos que viajan por la API pero no se guardan (valores de combate, catálogos, progreso) los define la capa de negocio que los calcula o los recibe: `personaje.negocio.ts` y `enemigo.negocio.ts`.

## Cuidado con los tipos

El validador de Atlas es estricto y rechaza el documento entero si un tipo no coincide:

- JavaScript guarda `1.0` como entero. Los campos `double` (`ajustes.musica`, `ajustes.efectos`) se escriben envueltos en `new Double(...)`; la conversión está en `negocio/coleccion-usuarios.ts`.
- Los campos `int` son de 32 bits: la capa de servicio rechaza números con decimales o mayores de 2 147 483 647.

## Qué NO debe hacer

- No contiene lógica ni consultas: solo tipos.

## Quién la usa

Negocio y servicio.
