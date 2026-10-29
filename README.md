# Umbral

RPG de acción para móviles, de mundo semiabierto y con combate en tiempo real. Arquitectura SOA (orientada a servicios) repartida en dos partes:

| Parte | Lenguaje | Carpeta | Capas |
|---|---|---|---|
| Servidor (API REST) | TypeScript | [servidor/](servidor/README.md) | conexión, DTO, negocio, servicio |
| App móvil | Dart (Flutter + Flame) | [lib/](lib/) | contrato, api, UI |

```
App (Dart)                       Servidor (TypeScript)
ui ──► api ──── HTTP ────►  servicio ──► negocio ──► conexion ──► MongoDB Atlas
 └──────┴──► contrato                      └──► dto
```

Hay **una sola capa DTO y una sola capa de servicio**, las dos en el servidor. La app no tiene DTO ni servicios propios: consume los servicios del servidor y lee sus respuestas.

| Capa | Dónde | Responsabilidad |
|---|---|---|
| Conexión | [servidor/src/conexion](servidor/src/conexion/README.md) | Solo se conecta a Atlas: abre, entrega colecciones y cierra. |
| DTO | [servidor/src/dto](servidor/src/dto/README.md) | Réplica de las colecciones de la base (`usuarios`, con sus subdocumentos embebidos, y `clases`). |
| Negocio | [servidor/src/negocio](servidor/src/negocio/README.md) | Todas las consultas a Mongo y las reglas, usando la conexión y los DTO. Entrega cada resultado listo para exponer. |
| Servicio | [servidor/src/servicio](servidor/src/servicio/README.md) | Llama a los métodos de negocio y los expone como API REST. |
| Contrato (app) | [lib/contrato](lib/contrato/README.md) | Forma del JSON que la app envía y recibe de cada servicio. No es un DTO: no replica la base. |
| API (app) | [lib/api](lib/api/README.md) | Cliente que llama a los servicios por HTTP, más la sesión y las preferencias del teléfono. No es una capa de servicio. |
| UI | [lib/ui](lib/ui/README.md) | Pantallas, juego y validaciones locales; solo llama a `api`. |

Flutter solo admite Dart, así que la app y el juego son Dart. Todo lo que no necesita ejecutarse en el móvil está en TypeScript, en el servidor. Además, así la cadena de conexión de Atlas nunca viaja dentro de la app.

## Cómo ejecutarlo

1. **Servidor:**
   ```bash
   cd servidor
   npm install
   cp .env.ejemplo .env     # rellena MONGO_URI y JWT_SECRETO
   npm run dev
   ```
   Sin Atlas puedes usar `npm run dev:memoria`, que monta una base temporal.
2. **App** (con el emulador abierto):
   ```bash
   flutter run
   ```
   Por defecto la app busca la API en `http://10.0.2.2:3000/api` (el PC visto desde el emulador). Para otra dirección: `flutter run --dart-define=API_URL=https://tu-servidor/api`.

## Publicar la beta

API en Render contra Atlas, APK firmado y qué secretos van en cada sitio: [docs/despliegue.md](docs/despliegue.md).

## Diseño

Sistema de diseño, paleta y sprites: [docs/diseno](docs/diseno/README.md).
