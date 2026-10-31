# SQLite de negocio (servidor)

Todo el SQLite del proyecto está en esta carpeta, dentro de la capa **negocio**. Guarda una copia de la base para que la API siga funcionando cuando MongoDB Atlas no responde, y envía a Mongo lo hecho mientras tanto en cuanto Atlas vuelve.

## Qué contiene

| Archivo | Responsabilidad |
|---|---|
| `respaldo-local.ts` | `respaldoLocal`: la base SQLite (`node:sqlite`, archivo `SQLITE_RUTA`, por defecto `datos/umbral.sqlite`). Tablas `usuarios` (cada documento en JSON, con índices únicos de email y username, y una `version` que marca los cambios sin enviar), `usuarios_eliminados` (bajas sin enviar) y `clases`. |
| `sincronizacion.ts` | `sincronizacion.conRespaldo`, que hace cada operación en Mongo o, si Atlas no responde, sobre la copia. También envía lo pendiente a Mongo y copia toda la base al arrancar. |

## Cómo funciona

Cada operación de `usuario.negocio.ts` y `partida.negocio.ts` pasa por `sincronizacion.conRespaldo`:

1. **Con Atlas:** primero envía a Mongo lo que quedara pendiente y después hace la operación en Mongo, como siempre. Luego copia el usuario de Mongo en SQLite. Al arrancar se copia toda la base.
2. **Sin Atlas:** la conexión falla a los 5 segundos (`SinConexionBD`) y negocio aplica **las mismas reglas** sobre el documento de SQLite: login, registro, ajustes, partidas, progreso, subir de nivel y herrería. El cambio queda marcado como pendiente. Durante los 10 segundos siguientes ni se intenta Atlas, para no hacer esperar a cada petición.
3. **Al volver Atlas:** en la siguiente petición, o en el reintento de cada 30 segundos, cada documento pendiente sustituye al de Mongo (`replaceOne` con `upsert`) y se borran las cuentas dadas de baja sin conexión. Un cambio hecho mientras se enviaba sigue pendiente y se envía en la vuelta siguiente.

`clase.negocio.ts` carga las clases de Mongo y las copia aquí. Si el servidor arranca sin Atlas, usa la copia y, la primera vez, `bd/clases.json`.

`npm run probar:sin-conexion` lo demuestra con una base temporal: guarda con Mongo, lo apaga, sigue guardando en SQLite y, al volver Mongo, comprueba que recibió todo.

## Límites

- Mientras Atlas no responde, el validador de la colección no comprueba nada. Las reglas de negocio sí se aplican.
- Una cuenta creada sin conexión con un correo o username que mientras tanto se registró en Mongo no se puede enviar: se avisa en el registro del servidor y queda pendiente.
- La copia vive en el disco del servidor. En un hosting con disco efímero (el plan gratis de Render), lo pendiente se pierde si el servidor se reinicia antes de que vuelva Atlas.
- Cubre que el **servidor** pierda Atlas. Un móvil sin internet no llega al servidor y, por lo tanto, tampoco a esta copia.

```
servicio  ──►  negocio  ──►  conexion  ──►  MongoDB Atlas
                  ├──►  dto
                  └──►  sqlite/  ──►  datos/umbral.sqlite
```
