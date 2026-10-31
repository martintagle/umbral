# Servidor de Umbral (TypeScript)

API REST que usa la app. Contiene las capas que hablan con la base de datos: **conexión**, **DTO**, **negocio** y **servicio**. Cada carpeta de `src/` tiene su README.

```
src/
├── conexion/   Conexión a MongoDB Atlas
├── dto/        Réplica de las colecciones usuarios y clases
├── negocio/    Consultas a Mongo, reglas del juego y copia en SQLite
├── servicio/   API REST (Express)
├── dev/        Utilidades de desarrollo
└── index.ts    Arranque
bd/esquema-usuarios.json   Validador de la colección usuarios
bd/esquema-clases.json     Validador de la colección clases
bd/clases.json             Las cinco clases, para crearlas si faltan
```

## Requisitos

Node.js 22.13 o superior: trae SQLite (`node:sqlite`), que negocio usa como copia local.

## Puesta en marcha

```bash
cd servidor
npm install
cp .env.ejemplo .env      # y rellena MONGO_URI y JWT_SECRETO
npm run dev               # API en http://localhost:3000 con recarga automática
```

## Scripts

| Script | Qué hace |
|---|---|
| `npm run dev` | Arranca la API contra Atlas y la reinicia al guardar cambios. |
| `npm run dev:memoria` | Arranca la API con una base temporal en memoria (mismos validadores, índices y clases). No necesita Atlas ni `.env`; los datos se pierden al cerrarla. |
| `npm run probar:sin-conexion` | Demuestra la copia SQLite con una base temporal: guarda con Mongo, lo apaga, sigue guardando en SQLite y, al volver Mongo, comprueba que recibió todo. |
| `npm run tipos` | Comprueba los tipos sin compilar. |
| `npm run build` / `npm start` | Compila a `dist/` y lo ejecuta (producción). |
| `npm run bd:esquema` | Aplica `bd/esquema-usuarios.json` y `bd/esquema-clases.json` como validadores de `rpg.usuarios` y `rpg.clases` en Atlas e inserta las clases de `bd/clases.json` que falten (no toca las que ya existen). Necesita un usuario con permiso `dbAdmin`. |
| `npm run bd:clases` | Solo inserta en `rpg.clases` las clases de `bd/clases.json` que falten, sin tocar validadores. Basta con un usuario `readWrite`. |

## Conectar la app

- **Emulador de Android:** la app usa por defecto `http://10.0.2.2:3000/api`, que es el PC visto desde el emulador.
- **Móvil físico en la misma red Wi-Fi:** ejecuta la app con `--dart-define=API_URL=http://IP-DEL-PC:3000/api` y añade esa IP en `android/app/src/main/res/xml/network_security_config.xml`.
- **Producción:** despliega el servidor con HTTPS y usa esa URL en `API_URL`. Pasos en [docs/despliegue.md](../docs/despliegue.md).

La cadena de Atlas y la clave JWT viven solo en el `.env` del servidor; nunca van dentro de la app.

Al arrancar, la API lee `rpg.clases` una vez y la guarda en memoria: si se cambia una clase en Atlas hay que reiniciarla. Si falta alguna de las cinco clases, no arranca.

## Sin conexión con Atlas

Si Atlas no responde, la API sigue funcionando con la copia SQLite de negocio y, al volver, envía a Mongo lo hecho mientras tanto. Esto vale también al arrancar. La copia se guarda en `SQLITE_RUTA` (por defecto `datos/umbral.sqlite`, fuera de git). Todo el código está en [src/negocio/sqlite/](src/negocio/sqlite/README.md).
