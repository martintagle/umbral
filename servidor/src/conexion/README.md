# Capa de Conexión (servidor)

## Qué debe hacer

Su única responsabilidad es **abrir, entregar y cerrar la conexión con MongoDB Atlas**.

- Leer la cadena de conexión de la variable `MONGO_URI` (archivo `.env`), que debe apuntar a la base `rpg`.
- Abrir un único `MongoClient` para todo el servidor y entregar colecciones con `conexionBD.coleccion('usuarios')`.
- Cerrar la conexión al terminar.
- Dar un error claro si falta la cadena, si no apunta a `rpg` o si Atlas rechaza la conexión.

## Qué NO debe hacer

- No ejecuta operaciones de negocio (`find`, `insertOne`, `updateOne`…). Eso es de la capa **negocio**.
- No conoce los DTO ni las reglas del juego.

## Qué contiene

| Archivo | Contenido |
|---|---|
| `conexion-bd.ts` | `conexionBD`, instancia única con `abrir()`, `coleccion(nombre)` y `cerrar()`. |

## Quién la usa

Solo la capa **negocio**.

```
negocio  ──►  conexion  ──►  MongoDB Atlas
```
