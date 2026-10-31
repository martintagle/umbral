# Despliegue de la beta

Cómo publicar la API contra MongoDB Atlas y repartir el APK sin exponer ninguna credencial.

## Qué es secreto y dónde vive

| Dato | Dónde vive | ¿Se sube a GitHub? | ¿Va en el APK? |
|---|---|---|---|
| `MONGO_URI` (usuario y contraseña de Atlas) | Variables de entorno del hosting y `servidor/.env` en tu PC | No | No |
| `JWT_SECRETO` | Variables de entorno del hosting y `servidor/.env` | No | No |
| Clave de firma (`.jks`, `key.properties`) | Solo en tu PC, con copia de seguridad | No | No |
| URL de la API (`API_URL`) | En el APK | Sí, es pública | Sí |

La app nunca habla con Atlas: solo con la API. Cualquiera puede descompilar un APK, así que dentro solo va la URL de la API.

## 1. Atlas

1. **Database Access → Add New Database User**
   - Usuario nuevo solo para la API (por ejemplo, `umbral-api`), con contraseña autogenerada.
   - En *Built-in Role* no elijas *Atlas admin* ni *readWriteAnyDatabase*. En *Specific Privileges* añade `readWrite` sobre la base `rpg`.
   - Para `npm run bd:esquema` usa otro usuario con `dbAdmin` sobre `rpg`, solo en tu PC y nunca en el hosting.
2. **Network Access**
   - El plan gratis de Render no tiene IP fija, así que hay que permitir `0.0.0.0/0`. Te protegen el usuario con permisos mínimos y la contraseña larga.
   - Con un plan que tenga IP de salida fija, permite solo esa IP.
3. **Tu cuenta de Atlas**: activa la verificación en dos pasos (MFA). Es lo que impide que alguien entre a tu cuenta, no a la base.

## 2. API en Render

1. En Render: **New → Blueprint** y elige el repo. Render lee [render.yaml](../render.yaml).
2. Te pedirá los dos secretos:
   - `MONGO_URI`: la cadena del usuario `umbral-api`, terminada en `/rpg?retryWrites=true&w=majority`.
   - `JWT_SECRETO`: el resultado de `node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"`.
3. Copia la URL que Render muestra arriba del servicio. Si el nombre `umbral-api` ya estaba ocupado, Render añade un sufijo (por ejemplo, `umbral-api-x7k2.onrender.com`). Usa siempre la URL exacta del panel, no la supongas.
4. Abre `https://TU-URL.onrender.com/api/salud` en el navegador: debe responder `{"ok":true}`. Si responde otra cosa o un 401, esa URL no es tu servicio.

En el plan gratis, la API se duerme tras 15 minutos sin uso y la primera petición tarda unos 30-50 s. La app espera hasta 60 s para cubrir ese arranque.

La copia SQLite de negocio (para cuando Atlas no responde) se guarda en el disco del servicio. En el plan gratis ese disco se borra al dormirse o redesplegarse, así que lo hecho sin Atlas se pierde si no se envió antes. Para conservarla, usa un plan con disco persistente y apunta `SQLITE_RUTA` a él. Render pide Node 22.13 o superior por el campo `engines` de `servidor/package.json`.

## 3. APK de la beta

1. Crea la clave de firma (una sola vez; guárdala, porque sin ella no podrás publicar actualizaciones):
   ```bash
   keytool -genkey -v -keystore ~/umbral-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias umbral
   ```
2. Crea `android/key.properties` (está en `.gitignore`):
   ```properties
   storeFile=C:/Users/TU-USUARIO/umbral-release.jks
   storePassword=...
   keyAlias=umbral
   keyPassword=...
   ```
3. Compila apuntando a la API de producción:
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=build/simbolos --dart-define=API_URL=https://TU-URL.onrender.com/api
   ```
   El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. En release, Android solo permite HTTPS hacia la API.

## 4. Publicar versiones con GitHub Actions

[.github/workflows/release.yml](../.github/workflows/release.yml) compila el APK firmado y crea la Release al subir un tag que empiece por `v`.

**Una sola vez**, en GitHub: *Settings → Secrets and variables → Actions → New repository secret*:

| Secreto | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | El `.jks` en base64: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\ruta\umbral-release.jks"))` en PowerShell. |
| `ANDROID_KEYSTORE_PASSWORD` | La contraseña de la clave. |

**Cada versión:**
1. Sube `version` en `pubspec.yaml` (el número tras `+` debe crecer siempre).
2. Commit y push.
3. `git tag v0.1.1-beta` y `git push origin v0.1.1-beta`.

El APK queda en `https://github.com/martintagle/umbral/releases/latest/download/umbral.apk`.

**Aviso de actualización en la app.** Al abrirse, la app consulta la última Release (`api.github.com/repos/martintagle/umbral/releases/latest`) y compara su tag con la `version` instalada, número a número (`v0.1.7-beta` → `0.1.7`). Si la Release es más nueva, muestra un diálogo y una franja con **Descargar**, que abre el APK en el navegador. Por eso el número antes del `+` en `pubspec.yaml` debe coincidir con el del tag. Si solo sube el número tras el `+`, la app no avisa. La Release no puede marcarse como *pre-release*: `releases/latest` las ignora. Para otro repositorio, compila con `--dart-define=REPO_RELEASES=dueño/repo`.

## Protecciones de la API

- Contraseñas guardadas con bcrypt; `passwordHash` nunca sale del servidor.
- Sesiones JWT de 30 días. La API no arranca si `JWT_SECRETO` tiene menos de 32 caracteres.
- Límite de peticiones por IP: 120 por minuto en total y 10 intentos de login o registro cada 15 minutos.
- Cuerpos JSON de 100 KB como máximo, validados con zod, y validador `$jsonSchema` en la colección.
- Errores internos genéricos hacia la app; el detalle solo aparece en los logs del servidor.

## Si se filtra un secreto

- **`MONGO_URI`**: en Atlas, *Database Access → Edit → Edit Password*, y actualiza la variable en Render.
- **`JWT_SECRETO`**: cámbialo en Render. Todas las sesiones caducan y los jugadores vuelven a iniciar sesión.
- Borrar el commit no basta: GitHub y los clones lo conservan. Cambia siempre el secreto.
