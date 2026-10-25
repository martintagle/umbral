# Umbral — sistema de diseño

Guía visual de **Umbral** (nombre provisional): RPG de acción para móviles, mundo semiabierto, combate por turnos, pixel art de fantasía oscura. Este documento es la referencia para construir el juego: interfaz, colores, tipografía y todos los sprites disponibles.

- Valores exactos de colores, tipografía, espaciado y radios: [`tokens.json`](tokens.json).
- Vistas previas ampliadas de todo el arte: [`vistas/`](vistas/).
- Sprites listos para el juego: `assets/sprites/` en la raíz del proyecto.

## Pilares

- **Oscuridad legible.** El mundo es sombrío, pero la información de juego (vida, maná, turno, botín) se lee de un vistazo en un teléfono a pleno sol.
- **El píxel manda.** Todo se alinea a la cuadrícula del arte. Nada de degradados suaves, desenfoques ni bordes suavizados.
- **Pocos colores, con significado.** Cada color de acento significa una sola cosa en combate.

## Voz

Sobria y algo arcaica, nunca grandilocuente. Frases cortas en los diálogos; menús directos ("Equipar", "Huir", "Descansar"). Tuteo.

## Píxel y escala

- Todo el arte está a **1x** (1 píxel de imagen = 1 píxel de arte). En pantalla se dibuja a escala entera **4x**. Nunca escalar a factores no enteros.
- Filtrado **vecino más cercano** siempre. En Flutter: `filterQuality: FilterQuality.none` en `Image.asset`/`RawImage`, y `isAntiAlias = false` en `Paint` si se dibuja en `Canvas`.
- Contornos de 1 píxel de arte en `abismo` (#0d0b10), nunca #000.
- Luz desde arriba a la izquierda; sombra en el borde derecho e inferior.

## Paleta (interfaz)

| Token | Hex | Significado | ¿Puede ser texto? |
| --- | --- | --- | --- |
| `abismo` | #0d0b10 | Fondo de pantalla, noche | — |
| `piedra` | #1c1820 | Paneles, menús, diálogos, barra de acciones | — |
| `borde` | #756a7c | Contorno de paneles, botones y casillas (3.4:1 sobre piedra) | — |
| `hueso` | #e8dcc4 | Texto principal (12.9:1 sobre piedra) | Sí |
| `ceniza` | #9a8f86 | Texto secundario (5.5:1) | Sí |
| `sangre` | #a3242a | Marca, vida (PV), botón atacar | No: solo relleno, con texto `hueso` encima (5.4:1) |
| `brasa` | #e08a2c | Oro, botín, turno activo, selección, crítico | Sí |
| `alma` | #5aa0b8 | Maná / energía (PM), magia | Sí |
| `podredumbre` | #7f9e45 | Estados alterados y curación | Sí, siempre con icono |

Un estado nunca se comunica solo por color: siempre lleva icono o forma.

## Tipografía

Tres fuentes de Google Fonts, todas pixel. Tamaños en múltiplos de 8px, salvo `etiqueta` (12px), mínimo en móvil.

| Estilo | Fuente | Tamaño / interlineado | Uso |
| --- | --- | --- | --- |
| `titulo-juego` | Jacquard 12 | 64 / 64 | Logo y pantalla de inicio (nunca < 32px) |
| `titulo-zona` | Jacquard 12 | 32 / 40 | Nombre de zona, nombre de jefe |
| `encabezado` | Pixelify Sans 600 | 24 / 32 | Títulos de menú y panel |
| `cuerpo` | Pixelify Sans 400 | 16 / 24 | Diálogo, descripciones, misiones |
| `etiqueta` | Silkscreen | 12 / 16 | Etiquetas de barras, estadísticas, botones pequeños |
| `dano` | Silkscreen 700 | 32 / 32 | Números de daño flotantes (`hueso`; críticos en `brasa`) |
| `contador` | Silkscreen | 16 / 16 | Cantidades en inventario, turnos restantes |

Las fuentes no están incluidas en el proyecto: hay que descargarlas de Google Fonts (o usar el paquete `google_fonts`).

## Espaciado, radios y sombra

- Espaciado: `paso-1` 4px (un píxel de arte a 4x), `paso-2` 8px, `paso-4` 16px, `paso-6` 24px.
- Radios: `radio-0` 0px (por defecto), `radio-astilla` 4px (botones y paneles), `radio-sello` 8px (sellos de rareza y nivel).
- Única sombra: `sombra-dura` = desplazada 4px a la derecha y 4px abajo, color `abismo`, sin desenfoque.

## Interfaz de combate por turnos

- Barra PV en `sangre`, barra PM en `alma`, fondo `abismo`, contorno `borde`; número en estilo `etiqueta`.
- Turno activo marcado en `brasa`; acciones en una barra inferior al alcance del pulgar.
- Daño flotante en `dano` color `hueso`; críticos en `brasa`.

## Iconografía

Cuadrícula de 16×16 píxeles de arte, contorno `abismo`, máximo tres colores de la paleta más un brillo. Pendiente: aún no hay set de iconos.

---

## Sprites

Todos en PNG con transparencia, a 1x. Cada carpeta tiene:

- un PNG por sprite (`<nombre>.png`), y
- una hoja con todos (`hoja-<grupo>.png`) más su `hoja-<grupo>.json`, que da la posición de cada cuadro (`x`, `y`, `w`, `h`). En las hojas, los sprites están alineados por la base.

### Personajes — `assets/sprites/personajes/` (32×40, de frente, en reposo)

| Archivo | Clase | Rasgos | Arma |
| --- | --- | --- | --- |
| `vagabundo-hombre.png`, `vagabundo-mujer.png` | Vagabundo | Capucha, ropa andrajosa con parches, pies vendados. Ella: pelo rojizo. | Katana (vaina al costado) |
| `guerrero-hombre.png`, `guerrero-mujer.png` | Guerrero | Armadura negra con barro. Él: yelmo cerrado. Ella: yelmo abierto y pelo largo. | Espadón |
| `arquero-hombre.png`, `arquero-mujer.png` | Arquero | Jubón vino con ribetes dorados, capa, sombrero con pluma, carcaj. | Arco largo |
| `mago-hombre.png`, `mago-mujer.png` | Mago | Gran túnica, sombrero puntiagudo. Él: barba blanca hasta la cintura. Ella: pelo blanco hasta los pies. | Libro de hechizos |
| `prisionero-hombre.png`, `prisionero-mujer.png` | Prisionero | Solo ropa interior, desnutrido, grillete roto. | Daga |

### Enemigos — `assets/sprites/enemigos/` (32×32; jefe 64×64)

| Archivo | Criatura | Idea de combate (propuesta) |
| --- | --- | --- |
| `ojo-errante.png` | Ojo flotante con tentáculos | Débil y esquivo; marca a un objetivo para que reciba más daño. |
| `fauce.png` | Boca dentada sobre patas de araña | Mordida fuerte; puede tragarse a alguien por un turno. |
| `polilla-osaria.png` | Polilla con cabeza de calavera y alas con ojos | Polvo que ciega; vuela (débil al arco). |
| `larva-cirio.png` | Gusano de cera con velas encendidas | Lento y resistente; cada vela apagada le quita un ataque de fuego. |
| `manojo.png` | Bulto de carne con ojos y manos | Agarra y retiene; varios ataques débiles. |
| `ahorcado-fungico.png` | Hongo humanoide con farol de esporas | Envenena; se cura si no lo matan rápido. |
| `jefe-rey-hueco.png` | **Jefe: el Rey Hueco.** Sin rostro, corona rota, pecho hueco lleno de ojos, brazos largos con garras. | Cada ojo del pecho es un punto débil; pega más fuerte con menos ojos. |

### Estructuras — `assets/sprites/estructuras/` (tamaños variables)

| Archivo | Tamaño | Qué es | Uso (propuesta) |
| --- | --- | --- | --- |
| `altar-de-brasas.png` | 32×32 | Pedestal con brasero encendido | Punto de descanso y guardado |
| `pozo.png` | 32×32 | Pozo de piedra con balde | Decorado de aldea |
| `lapidas.png` | 32×32 | Cruz, lápida agrietada, huesos | Cementerios, caminos |
| `estatua-sin-rostro.png` | 32×48 | Figura encapuchada sin cara con cuenco | Hito del mapa, puzle |
| `choza-en-ruinas.png` | 64×64 | Casa de tablas con techo hundido | Aldea abandonada, interior |
| `capilla.png` | 64×64 | Capilla con campanario y rosetón roto | Misión, vendedor o jefe |
| `torre-derruida.png` | 48×64 | Torre rota con aspillera iluminada | Mirador, interior |
| `entrada-de-cripta.png` | 64×48 | Arco en una loma, escalera a la oscuridad | Entrada a mazmorra |
| `arbol-de-la-jaula.png` | 48×64 | Árbol muerto con jaula colgante | Marca de peligro o zona de jefe |

Las luces cálidas (`brasa`) en estructuras marcan solo lugares que vale la pena visitar.

## Uso en Flutter

Declarar las carpetas en `pubspec.yaml` (no se agregó automáticamente):

```yaml
flutter:
  assets:
    - assets/sprites/personajes/
    - assets/sprites/enemigos/
    - assets/sprites/estructuras/
```

Dibujar un sprite a 4x sin suavizado:

```dart
Image.asset(
  'assets/sprites/personajes/vagabundo-hombre.png',
  width: 32 * 4,
  height: 40 * 4,
  filterQuality: FilterQuality.none,
)
```

## Pendiente

Animaciones (caminar, atacar, recibir daño, morir) de personajes y enemigos; retratos para diálogos; set de iconos; suelos y caminos en mosaico (tiles); muros modulares para interiores; variantes de élite de los enemigos.
