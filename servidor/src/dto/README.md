# Capa DTO (servidor)

## Qué debe hacer

Es la **única capa DTO del proyecto**. Cada interfaz es una **réplica de la estructura de los documentos** de las colecciones `usuarios` y `clases`, tal como están en la base (con `_id`, `passwordHash` y fechas `Date`). La app no tiene DTO: lee las respuestas de la API con su propio [contrato](../../../lib/contrato/README.md). Como MongoDB no obliga a seguir un esquema, los DTO y los validadores `bd/esquema-usuarios.json` y `bd/esquema-clases.json` son los que lo definen.

## Colecciones

`usuarios` lleva todo embebido: cada subdocumento tiene su interfaz, pero ninguna es una colección aparte. El personaje apunta a `clases` con `claseCodigo` (llave hacia `clases._id`):

```
UsuarioDto                         usuario.dto.ts
├── estado: EstadoUsuario          estado-usuario.ts
├── ajustes: AjustesDto            ajustes.dto.ts
└── partidas: PartidaDto[]         partida.dto.ts
    └── personaje: PersonajeDto    personaje.dto.ts
        ├── claseCodigo  ──►  ClaseDto
        ├── atributos              atributos.dto.ts
        ├── equipo                 equipo.dto.ts
        ├── ubicacion              ubicacion.dto.ts
        ├── mundo                  mundo.dto.ts
        └── estadisticas           estadisticas.dto.ts

ClaseDto                           clase.dto.ts
├── _id: ClaseCodigo               clase-codigo.ts
└── atributosBase                  atributos-base.dto.ts
```

| BSON | TypeScript |
|---|---|
| `objectId` (`_id`) | `ObjectId` |
| `int`, `double` | `number` |
| `string` | `string` |
| `date` | `Date` |
| `array` | `T[]` |
| `["string", "null"]` | `string \| null` |

Solo hay réplicas de las colecciones. Los objetos que viajan por la API pero no se guardan (valores de combate, catálogos, progreso) los define la capa de negocio que los calcula o los recibe: `personaje.negocio.ts`, `enemigo.negocio.ts`, `partida.negocio.ts` (`PartidaJugable`), `usuario.negocio.ts` (`UsuarioPublico`) y `clase.negocio.ts` (catálogo).

## Cuidado con los tipos

El validador de Atlas es estricto y rechaza el documento entero si un tipo no coincide:

- JavaScript guarda `1.0` como entero. Los campos `double` (`ajustes.musica`, `ajustes.efectos`) se escriben envueltos en `new Double(...)`; la conversión está en `negocio/coleccion-usuarios.ts`.
- Los campos `int` son de 32 bits: la capa de servicio rechaza números con decimales o mayores de 2 147 483 647.

## Qué NO debe hacer

- No contiene lógica ni consultas: solo tipos.

## Quién la usa

Solo negocio.
