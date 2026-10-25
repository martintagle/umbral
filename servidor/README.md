# Servidor de Umbral (TypeScript)

API REST que usa la app. Contiene las capas que hablan con la base de datos: **conexión**, **DTO**, **negocio** y **servicio**. Cada carpeta de `src/` tiene su README.

```
src/
├── conexion/   Conexión a MongoDB Atlas
├── dto/        Réplica de la colección usuarios
├── negocio/    Consultas a Mongo y reglas del juego
├── servicio/   API REST (Express)
├── dev/        Utilidades de desarrollo
└── index.ts    Arranque
bd/esquema-usuarios.json   Validador de la colección
```

## Requisitos

Node.js 20 o superior.

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
| `npm run dev:memoria` | Arranca la API con una base temporal en memoria (mismo validador e índices). No necesita Atlas ni `.env`; los datos se pierden al cerrarla. |
| `npm run tipos` | Comprueba los tipos sin compilar. |
| `npm run build` / `npm start` | Compila a `dist/` y lo ejecuta (producción). |
| `npm run bd:esquema` | Aplica `bd/esquema-usuarios.json` como validador de `rpg.usuarios` en Atlas. Necesita un usuario con permiso `dbAdmin`. |

## Conectar la app

- **Emulador de Android:** la app usa por defecto `http://10.0.2.2:3000/api`, que es el PC visto desde el emulador.
- **Móvil físico en la misma red Wi-Fi:** ejecuta la app con `--dart-define=API_URL=http://IP-DEL-PC:3000/api` y añade esa IP en `android/app/src/main/res/xml/network_security_config.xml`.
- **Producción:** despliega el servidor con HTTPS (por ejemplo, en Render o Railway) y usa esa URL en `API_URL`.

La cadena de Atlas y la clave JWT viven solo en el `.env` del servidor; nunca van dentro de la app.
