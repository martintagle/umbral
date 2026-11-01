# Oreste, el Apagador

NPC de las zonas seguras. No ataca y no se le puede atacar. Espera bajo techo, en la choza o la capilla más cercana al primer altar de brasas de cada zona: sentado mientras nadie se acerca, de pie para recibir al jugador.

| Zona | Dónde espera |
| --- | --- |
| 1 | La capilla de la aldea Cenizal. |
| 2 | El Refugio del Apagador, una choza nueva junto al altar de la Orilla de los Cirios. |
| 3 | El barracón de mineros (la choza de la herrera), cerca del altar de la Bocamina. |
| 4 | El Refugio del Apagador, en terreno ganado al agua junto al islote del altar del Atrio Inundado. |
| 5 | La choza del Campamento Caído (la de la herrera), cerca de su altar. |
| 6 | El Refugio del Apagador, junto al altar de El Borde. |

El Refugio del Apagador es una sala de `interiores.json` (`refugio-del-apagador`); las chozas que llevan a ella tienen `"interior": "refugio-del-apagador"` en el mapa. La sala exacta y la celda están en `npc-oreste.json` → `posiciones[n].interior`.

Sus diálogos llevan al jugador a querer el final oculto. Si los lee todos, se activa la misión de la **astilla de nada**, el único objeto que puede **romper la Brasa**.

## Quién es

- **Aspecto:** un viejo encapuchado con barba larga. Lleva un **apagavelas** (vara con campana de hierro), un **farol apagado** al cinto y un collar de cabos de vela.
- **Pasado:** era el Apagador del Altar Mayor. Durante siglos alimentó la Brasa con los nombres de los que despertaban junto a los altares. Conserva el suyo porque fue el único que nunca le dio.
- **Lo que quiere:** que alguien rompa la Brasa, para que los muertos puedan descansar y los vivos recuerden.
- **Lo que revela poco a poco:**
  - La Brasa no protege del Hueco: **retiene a los muertos**. Cada vez que te devuelve a la vida, quema un nombre.
  - Los custodios no se vaciaron por los ojos, sino por el fuego.
  - Los ojos son el Hueco **buscando a los suyos**.
  - El sexto custodio era una mentira de los Apagadores.
  - La Estatua sin Rostro fue el primer Sin Nombre: trajo la astilla y no se atrevió a usarla.

## Diálogos (22)

Cada zona tiene los suyos y van en orden: el siguiente no aparece hasta leer el anterior. Si no hay nada nuevo, Oreste dice su frase de espera.

### Zona 1: Tierras del Umbral (3 diálogos)

*En la capilla de la aldea Cenizal.*

**1. Al llegar** (`oreste-1-1`)

> Otro que despierta junto al fuego.  
> No te asustes. Yo también cuidaba este altar, cuando había quien encendiera velas.  
> Me llamo Oreste. Lo recuerdo porque nunca morí cerca de un altar.  
> Tú no puedes decir lo mismo, ¿verdad?  

**2. Tras encender un altar de la zona** (`oreste-1-2`)

> Descansaste. Te sientes más fuerte.  
> Dime una cosa: ¿recuerdas algo más que antes? ¿O algo menos?  
> Cada vez que el fuego te devuelve, cobra. Y siempre cobra en la misma moneda.  

**3. Tras vencer al jefe** (`oreste-1-3`)

> El Rey decía que miraba lejos. No miraba nada.  
> La Brasa le quitó el reino nombre por nombre. Primero los de sus súbditos. Al final, el suyo.  
> Dicen que los ojos lo vaciaron. Los ojos llegaron después. Buscaban algo que ya no estaba.  
> Te veré en la ciénaga. Allí las velas hablan más claro.  

*Espera:* «Descansa. El fuego no se va a ninguna parte. Por desgracia.»

### Zona 2: Ciénaga de Cera (3 diálogos)

*En el Refugio del Apagador, junto al altar de la Orilla de los Cirios.*

**1. Al llegar** (`oreste-2-1`)

> ¿Hueles? Es cera. Cada vela de esta orilla tenía un nombre escrito en la base.  
> Míralas bien. Ya no queda ninguno que se pueda leer.  

**2. Tras abrir el cofre secreto de la zona** (`oreste-2-2`)

> Estuviste en la isla de las cunas.  
> La Madre encendía una vela por cada niño, para que la Brasa no se apagara.  
> Cuando un niño enfermaba, encendía otra. El niño olvidaba a su madre. Y la Brasa ardía un poco más.  
> Ella no lo sabía. O no quería saberlo.  

**3. Tras vencer al jefe** (`oreste-2-3`)

> «¿Cuál eras tú?», preguntó al morir. Ni ella se acordaba ya.  
> El fuego no da luz, Sin Nombre. Da tiempo. Y el tiempo se paga con lo que fuimos.  

*Espera:* «Las velas siguen goteando. Ve, vuelve cuando hayas visto más.»

### Zona 3: Minas de Sal Negra (4 diálogos)

*En el barracón de mineros, cerca del altar de la Bocamina.*

**1. Al llegar** (`oreste-3-1`)

> Aquí abajo nadie ve el cielo. La Brasa se nota menos. Lo que se llevó se nota más.  
> Pregúntale a un minero cómo se llamaba. Te dirá su turno.  

**2. Tras encender un altar de la zona** (`oreste-3-2`)

> ¿Sabes por qué despiertas junto a los altares y no en otro sitio?  
> Porque el altar no te salva. Te retiene.  
> Lo que muere tendría que irse. Al Hueco. A descansar. La Brasa le cierra la puerta.  

**3. Tras abrir el cofre secreto de la zona** (`oreste-3-3`)

> Los mineros cavaron hasta tocar el borde del Hueco. ¿Sabes qué encontraron?  
> Silencio. Ningún monstruo. Un silencio que no dolía.  
> El Capataz mandó tapiar la galería. Dijo que ese silencio era malo para el trabajo.  

**4. Tras vencer al jefe** (`oreste-3-4`)

> «Turno terminado», dijo. Por fin.  
> Fíjate: ninguno de los que has matado maldijo al caer. Todos parecían... aliviados.  
> Piensa en eso la próxima vez que despiertes junto al fuego.  

*Espera:* «Aquí abajo el tiempo no pasa. Pero tú sí. Sigue.»

### Zona 4: Abadía Hundida (4 diálogos)

*En el Refugio del Apagador, junto al islote del altar del Atrio Inundado.*

**1. Al llegar** (`oreste-4-1`)

> Aquí le rezaban a la Brasa. Yo cuidaba las velas del coro.  
> Era el Apagador. Recortaba la llama cuando crecía demasiado. Y la alimentaba cuando menguaba.  

**2. Tras encender un altar de la zona** (`oreste-4-2`)

> Quieres saber con qué se alimenta.  
> Con nombres. Los nombres de los que vuelven. Cada despertar, un nombre al fuego.  
> Yo se los echaba con este apagavelas. Uno a uno. Durante siglos.  
> Por eso conservo el mío. Es el único que nunca le di.  

**3. Tras abrir el cofre secreto de la zona** (`oreste-4-3`)

> Bajo el ala oeste hay una cripta sellada. Las hermanas guardaban allí una lista.  
> Los nombres que la Abadesa pidió conservar. La Brasa se los comió igual.  
> Las mil manos no sostenían la llama. Intentaban sacar algo de ella.  

**4. Tras vencer al jefe** (`oreste-4-4`)

> Ninguna mano alcanzó. Ninguna iba a alcanzar.  
> Del fuego no se saca nada, Sin Nombre. Se puede apagar... pero lo que se apaga, alguien lo vuelve a encender.  
> Hay otra forma. Te la diré en el páramo, si sigues escuchando a un viejo.  

*Espera:* «Reza si quieres. Nadie escucha, pero calma las manos.»

### Zona 5: Páramo de Ceniza (4 diálogos)

*En la choza del Campamento Caído.*

**1. Al llegar** (`oreste-5-1`)

> Aquí juraron defender la Brasa con la vida. Y la Brasa aceptó.  
> Mira el campo. Ninguno pudo morir del todo. Llevan siglos cayendo y levantándose.  

**2. Tras encender un altar de la zona** (`oreste-5-2`)

> ¿Has notado que los ojos nunca se acercan a los altares?  
> Los ojos son el Hueco mirando por las grietas. No vienen a devorarnos.  
> Buscan a los suyos. A los muertos que la Brasa no dejó pasar.  

**3. Tras abrir el cofre secreto de la zona** (`oreste-5-3`)

> En el búnker de las trincheras hay cartas. Ninguna llegó a su destino.  
> Una dice: «Si no vuelvo, no me esperes junto al fuego. Espérame del otro lado».  
> El otro lado. Hubo un tiempo en que no era una amenaza. Era una promesa.  

**4. Tras vencer al jefe** (`oreste-5-4`)

> «Cumplí, ¿verdad?». Cumpliste demasiado, caballero.  
> Escucha bien. La Brasa no hay que apagarla. Hay que romperla. Para siempre.  
> Con algo que el fuego no pueda quemar.  
> Te espero en el borde. Allí te diré dónde está.  

*Espera:* «Levántate. Aquí todos se levantan; al menos tú sabes para qué.»

### Zona 6: El Umbral (4 diálogos)

*En el Refugio del Apagador, junto al altar de El Borde.*

**1. Al llegar** (`oreste-6-1`)

> El borde. Desde aquí se oye el Hueco. ¿Lo oyes? No grita. Respira.  
> Todos los que nos faltan están ahí abajo. Esperando a que abramos.  

**2. Tras encender un altar de la zona** (`oreste-6-2`)

> El sexto custodio nunca existió. Lo inventamos los Apagadores, para que nadie preguntara qué había bajo el Altar.  
> Bajo el Altar está El Que Mira. No es un monstruo. Es el Hueco, con los ojos de todos los que perdimos.  
> Te mirará con la cara de alguien que conociste. No sabrás de quién.  

**3. Tras abrir el cofre secreto de la zona** (`oreste-6-3`)

> La Estatua sin Rostro. ¿Nunca te preguntaste de quién era la cara que le falta?  
> Fue el primer Sin Nombre. Bajó al Hueco, volvió con algo en la mano y tuvo miedo de usarlo.  
> Se quedó junto al fuego. El fuego le quitó la cara.  

**4. Tras leer todos los anteriores** (`oreste-6-4`)

> Has escuchado todo lo que sé. Nadie lo había hecho antes.  
> Lo que el primero trajo del Hueco es una astilla de nada. Lo único que la Brasa no puede quemar.  
> La escondió en su torre, sobre el vacío, al noreste del borde. Solo se llega siendo pequeño, por los troncos.  
> Cuando caiga El Que Mira y pongas las ascuas en el Altar, no la enciendas. Clava la astilla.  
> No te prometo que despiertes. Te prometo que vas a recordar.  
> Yo me quedo aquí. Alguien tiene que apagar la última vela.  

*Espera:* «El Hueco respira. Tómate tu tiempo.»

## La misión: la astilla de nada

1. Leer los 22 diálogos. El último (`oreste-6-4`) exige haber leído los otros 21.
2. Oreste dice dónde está la astilla: en la **Torre del primer guardián**, en el islote del noreste de El Umbral.
3. Para llegar hay que **encogerse** en el portal de la isla N3 y cruzar la larga hilera de troncos sobre el vacío. Es exploración opcional: el camino principal no pasa por ahí.
4. La astilla está en el cofre `cofre-secreto-astilla` de `zona-6-umbral.json` (x 98, y 10). Ese cofre lleva `requiere: leido:oreste-6-4` y no aparece hasta entonces.
5. Con la astilla, Oreste dice: «La tienes. Pesa poco, ¿verdad? La nada nunca pesa.»

## El final

Al vencer a El Que Mira y colocar las ascuas en el Altar Mayor:

- **Sin la astilla:** solo se puede **encender la Brasa**. Es el final normal.
- **Con la astilla:** aparece también **romper la Brasa**. Es el final oculto.

Ambos finales están descritos en `docs/guion.md`.
