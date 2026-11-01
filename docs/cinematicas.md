# Cinemáticas

Hay tres cinemáticas con cuadros de texto: una al empezar una partida nueva y una para cada final. Son escenas de pixel art, cada una con dos a ocho cuadros animados, y textos que se leen de uno en uno.

**Vista previa jugable:** abre `docs/diseno/cinematicas/vista-previa.html` en el navegador. Tiene un botón por cinemática y un campo para probar el nombre del personaje.

## Las tres cinemáticas

### Inicio: «El despertar» (7 escenas)

Se muestra al crear un personaje, justo antes de entrar al juego.

1. **La Brasa Primera** arde sobre el Altar Mayor. *«Antes de todo, hubo una llama.»*
2. **Seis ascuas.** Las siluetas de los custodios: el Rey, la Madre, el Capataz, la Abadesa, el Caballero… y un sexto, que es solo un contorno vacío.
3. **El Hueco:** los ojos se abren en la oscuridad, sobre una grieta roja.
4. **El Rey Hueco**, con el pecho lleno de ojos, entre ceniza que cae.
5. **La aldea Cenizal** de noche. Solo arde el altar.
6. **Un Sin Nombre** tumbado junto al altar. En el último cuadro abre los ojos. *«Así despiertas tú.»*
7. **El logo de la U** sobre una brasa, con el título **UMBRAL**. *«Recupera las seis ascuas.»*

### Final normal: «La Llama» (7 escenas)

Se muestra al elegir **Encender la Brasa**.

1. Las seis ascuas giran sobre el Altar Mayor apagado.
2. La Brasa vuelve a arder. Tiembla la pantalla y los ojos del fondo se cierran.
3. El Sin Nombre se sienta junto al fuego.
4. La misma escena pierde el color cuadro a cuadro: *«Primero olvidas el camino. Luego las caras. Luego la palabra "yo".»*
5. La aldea Cenizal al amanecer, con luz en las ventanas y humo en las chimeneas.
6. Junto al altar, una estatua nueva sin rostro.
7. Fundido a negro: **La Llama — Fin**.

### Final oculto: «El Nombre» (11 escenas)

Se muestra al elegir **Romper la Brasa**, lo que solo es posible con la astilla de nada.

1. Una mano sostiene la astilla frente a la llama. Es lo único que no refleja la luz.
2. La Brasa se agrieta. Tiembla la pantalla y las grietas blancas crecen.
3. Las seis ascuas caen hechas ceniza fría.
4. **El mapa del mundo:** los altares de brasas se apagan uno a uno, zona por zona. Son las posiciones reales, sacadas de `assets/minimapa/zonas.json`.
5. Las criaturas del camino se van agachando hasta quedarse sentadas.
6. Los ojos del Hueco se cierran.
7. Oreste, al borde, apaga la última vela con su apagavelas. Es su animación `apagar-vela`. *«Me llamo Oreste», dice. Por última vez.*
8. El Umbral se abre a una niebla gris y la silueta del personaje camina hacia ella.
9. En negro, **el nombre del personaje** aparece letra a letra.
10. Un solo ojo se abre, mira y se cierra.
11. **El Nombre — Fin**.

## Archivos

| Archivo | Qué es |
| --- | --- |
| `assets/cinematicas/cinematicas.json` | Las tres cinemáticas: escenas, cuadros, tiempos y textos. |
| `assets/cinematicas/<escena>-<n>.png` | 84 cuadros de 256×144 a 1x. |
| `lib/ui/pantallas/cinematica_pantalla.dart` | `CinematicaPantalla(id:, nombre:, alTerminar:)`: el reproductor. |
| `docs/diseno/cinematicas/vista-previa.html` | La misma lógica en el navegador, para revisar textos y ritmo. |
| `docs/diseno/cinematicas/lamina.png` | Último cuadro de cada escena. |

## Formato de `cinematicas.json`

```json
"inicio": { "nombre": "El despertar", "escenas": [
  { "id": "inicio-1", "cuadros": ["assets/cinematicas/inicio-1-0.png", "…"], "ms": 160, "bucle": true,
    "textos": ["Antes de todo, hubo una llama.", "…"], "fundido": true }
]}
```

- **`ms`:** duración de cada cuadro.
- **`bucle`:** si es verdadero, los cuadros se repiten; si no, la escena se queda en el último.
- **`textos`:** se muestran de uno en uno en el cuadro de abajo, letra a letra.
- **`titulo`** y **`subtitulo`:** texto grande en el centro. `{nombre}` se cambia por el nombre del personaje. Con `letraALetra`, el título se escribe solo y la escena avanza sola.
- **`fundido`:** la escena entra desde negro.
- **`temblor`:** la imagen tiembla un momento al empezar.
- Una escena sin `cuadros` es una pantalla negra; la usan los títulos finales.
- Una escena sin textos ni título avanza sola al terminar sus cuadros.

## Cómo se usa en el juego

Los textos salen de `docs/guion.md`. Para cambiar uno basta con editar el JSON: el reproductor no tiene textos propios.

**Controles:**
- **Tocar la pantalla:** si la línea no ha terminado de escribirse, la completa; si ya está completa, pasa a la siguiente línea o escena.
- **«Saltar»** (arriba a la derecha) o el **botón atrás**: termina la cinemática.

**Dónde se llama:**
- **`PartidasPantalla._nueva`:** tras crear el personaje se muestra `inicio` y luego se entra al juego. Las partidas que ya existían no la ven.
- **`JuegoPantalla._elegirFinal`:** al elegir un final se muestra `final-encender` o `final-romper` y luego se vuelve a la lista de partidas.

  Las capas de texto que había antes para cada final (`_Final.encender`, `_Final.romper`, `_Final.nombre`) quedan sin usar. Se pueden borrar.
