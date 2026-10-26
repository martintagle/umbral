# Logo de Umbral

La **U** de Umbral, dibujada como una u gótica (dos astas con cabeza en rombo, unidas abajo por un trazo diagonal que termina en un pie) en `hueso` con sombra `ceniza`. Su hueco es el umbral: desde abajo sube la luz de `brasa`, con algunas chispas. Una gota de `sangre` cae de la banderola izquierda. Pixel art de 32×32 sobre `abismo`.

## Archivos

| Archivo | Tamaño | Uso |
| --- | --- | --- |
| `logo-u-32.png` | 32×32, transparente | Original a 1x (1 píxel = 1 píxel de arte). En el juego se escala por enteros con `FilterQuality.none`. |
| `logo-u-256.png`, `logo-u-512.png` | 8x y 16x, transparentes | Pantalla de título, splash, materiales de difusión. |
| `icono-app-1024.png` | 1024×1024, opaco | Ícono de la tienda (App Store / Google Play) y fuente para generar todos los íconos de iOS. Sin transparencia, como pide Apple. |
| `icono-app-512.png`, `icono-app-192.png`, `icono-app-64.png` | opacos | Google Play (512), web/PWA (192) y favicon (64). |
| `icono-android-frente-432.png` | 432×432, transparente | Capa de frente del ícono adaptativo de Android. La U ocupa los 288 px centrales (zona segura del 66 %), así sobrevive a cualquier máscara (círculo, gota, cuadrado). |
| `icono-android-fondo-432.png` | 432×432, opaco | Capa de fondo del ícono adaptativo: `abismo` con un halo de brasa en trama. |

`vistas/presentacion.png` muestra el ícono grande, con máscara redondeada (iOS) y circular (Android), a tamaño real (32, 64 y 96 px) y la U sola.

## Reglas

- Siempre a escala entera y sin suavizado. Nunca redibujar la U en vectores ni agregarle degradados.
- Fondo `abismo` o transparente. Sobre fondos claros no se usa: la U es `hueso` y se pierde.
- Margen mínimo alrededor de la U: 4 píxeles de arte.
- La luz del hueco es parte del logo: no se quita ni se cambia de color.

## Llevarlo a la app

Con el paquete `flutter_launcher_icons` (dev_dependency), en `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/logo/icono-app-1024.png
  adaptive_icon_foreground: assets/logo/icono-android-frente-432.png
  adaptive_icon_background: assets/logo/icono-android-fondo-432.png
  remove_alpha_ios: true
```

Luego `dart run flutter_launcher_icons`. Ya está configurado: hay que volver a ejecutarlo solo si cambia el ícono.
