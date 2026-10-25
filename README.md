# Umbral

RPG de acción para móviles, de mundo semiabierto y con combate en tiempo real. Arquitectura SOA (orientada a servicios) repartida en dos partes:

| Parte | Lenguaje | Carpeta | Capas |
|---|---|---|---|
| Servidor (API REST) | TypeScript | [servidor/](servidor/README.md) | conexión, DTO, negocio, servicio |
| App móvil | Dart (Flutter + Flame) | [lib/](lib/) | DTO, servicio, UI |

```
App (Dart)                         Servidor (TypeScript)
ui ──► servicio ──── HTTP ────►  servicio ──► negocio ──► conexion ──► MongoDB Atlas
  └────────┴──► dto                  └───────────┴──► dto
```

| Capa | Dónde | Responsabilidad |
|---|---|---|
| Conexión | [servidor/src/conexion](servidor/src/conexion/README.md) | Solo abre y cierra la conexión con Atlas. |
| DTO | [servidor/src/dto](servidor/src/dto/README.md), [lib/dto](lib/dto/README.md) | Réplica de la colección `usuarios` y sus subdocumentos embebidos. |
| Negocio | [servidor/src/negocio](servidor/src/negocio/README.md) | Todas las consultas a Mongo y las reglas, usando la conexión y los DTO. |
| Servicio | [servidor/src/servicio](servidor/src/servicio/README.md) | Expone negocio como API REST. |
| Servicio (app) | [lib/servicio](lib/servicio/README.md) | Llama a la API y devuelve DTO a la UI. |
| UI | [lib/ui](lib/ui/README.md) | Pantallas, juego y validaciones locales; solo llama a los servicios. |

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

## Diseño

Sistema de diseño, paleta y sprites: [docs/diseno](docs/diseno/README.md).
