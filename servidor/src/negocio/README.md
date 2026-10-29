# Capa de Negocio (servidor)

## Qué debe hacer

Contiene **todas las operaciones sobre la base de datos** y **todas las reglas** del juego y de las cuentas. Es la única capa que habla con MongoDB, siempre **a través de la capa de conexión** y usando los **DTO**.

Cada método entrega su resultado **listo para que la capa servicio lo exponga** sin tocarlo:

- `usuarioNegocio` devuelve `UsuarioPublico`: el `UsuarioDto` sin `passwordHash` y con `_id` como `id` en texto.
- `partidaNegocio` devuelve `PartidaJugable`: la `PartidaDto` con sus valores de combate.
- `claseNegocio.catalogo` devuelve cada clase (`_id` como `id`) con el nivel, el oro y el combate con que empieza.

## Qué contiene

| Archivo | Responsabilidad |
|---|---|
| `usuario.negocio.ts` | Registro (hash con bcrypt), login por email o username, ajustes y borrado de la cuenta. Entrega `UsuarioPublico`. |
| `partida.negocio.ts` | Partidas embebidas en el usuario: listar, crear, registrar progreso, subir atributos, mejorar equipo, borrar y elegir la activa. Entrega `PartidaJugable`. |
| `clase.negocio.ts` | Colección `clases`: la lee una vez al arrancar (`cargar`, desde `index.ts`) y después la sirve desde memoria (`catalogo`, `obtener`). |
| `personaje.negocio.ts` | Reglas del personaje: oro, armadura y atributo del arma de cada clase, valores de combate (con el costo y efecto de la siguiente mejora de equipo), personaje inicial, aplicación del progreso, subida de atributos con experiencia (curva de Elden Ring) y mejora de equipo. |
| `enemigo.negocio.ts` | Recompensa (exp y oro) de cada enemigo, incluido el jefe Rey Hueco, y suma de lo ganado en un progreso. |
| `coleccion-clases.ts` | Acceso a la colección `clases` y preparación de su validador y de las clases iniciales (`bd/clases.json`) que usan los scripts de `dev/`. |
| `coleccion-usuarios.ts` | Acceso a la colección `usuarios`, conversión entre el DTO y el documento guardado (los `double` del esquema) y preparación del validador e índices que usan los scripts de `dev/`. |
| `negocio-error.ts` | `NegocioError` con su tipo, conversión de ids y `conErroresMongo`, que traduce los errores de Mongo (11000 duplicado, 121 esquema). |

## Reglas que aplica

- **Cuentas:** username de 3 a 20 caracteres sin `@`, correo válido y en minúsculas, contraseña de 8 a 72 caracteres guardada solo como hash de bcrypt. El login da el mismo mensaje si el usuario no existe o la contraseña es incorrecta, y rechaza las cuentas `baneado` o `eliminado`.
- **Personaje nuevo:** lo crea el servidor; la app solo elige `claseCodigo`, apariencia y nombre (de 2 a 16 caracteres). Los atributos se copian de `atributosBase` de su clase en `rpg.clases` y a partir de ahí evolucionan en el personaje: no se vuelven a leer de la colección. El nombre, el arma y la descripción no se copian. Como en Elden Ring, cada atributo parte en 1 y cada punto por encima es un nivel (nivel = 1 + suma de atributos − 4). Las clases empiezan en nivel 10 con 9 puntos repartidos según su estilo (valores de `bd/clases.json`):

  | Clase | Vigor | Fuerza | Destreza | Intelecto | Nivel |
  | --- | --- | --- | --- | --- | --- |
  | Vagabundo | 4 | 3 | 5 | 1 | 10 |
  | Guerrero | 5 | 6 | 1 | 1 | 10 |
  | Arquero | 3 | 1 | 7 | 2 | 10 |
  | Mago | 2 | 1 | 2 | 8 | 10 |
  | Prisionero | 1 | 1 | 1 | 1 | 1 |

- **Combate:** PV máximos = 80 + 12·vigor. Daño = 6 + 2·(atributo del arma) + 3·(nivel del arma); el nivel por sí solo no da daño. Defensa = 2·(nivel de la armadura). Crítico = 5 % + 0,8 % por punto de destreza.
- **Progreso:** la app envía los hechos (cuántos enemigos de cada tipo derrotó, muertes, segundos, vida y posición) y aquí se calculan la experiencia y el oro con la tabla de recompensas, y se sube de nivel. Se rechaza un progreso con más segundos que el tiempo real desde el último guardado, o con más de un enemigo derrotado por segundo. La experiencia y el oro solo se acumulan: guardar no sube de nivel.
- **Subir de nivel (como las runas de Elden Ring):** en un altar de brasas se gasta experiencia para subir atributos. Cada punto sube un nivel y cuesta lo que el nivel actual: la fórmula de Elden Ring (`(x + 0,1)·(nivel + 81)² + 1`, con `x = max((nivel − 11)·0,02, 0)`) dividida por 10. Va de 67 en el nivel 1 a 592 en el 30 y siempre crece. Ningún atributo pasa de 50 y, si sube el vigor, la vida actual sube lo mismo que la máxima. `combate.costoNiveles` trae el costo de los 30 niveles siguientes para que la app muestre el total. Los `puntosLibres` que dejó la regla anterior se gastan primero, sin costo y sin subir el nivel.
- **Herrería:** el personaje solo porta su arma y su armadura, y las dos suben de nivel con oro, hasta el nivel 10. Cada mejora cuesta más que la anterior: llevar una pieza al nivel n cuesta 150·n de oro hasta el 6, 200·n del 7 al 9 y 2.500 el 10. Cada nivel de arma suma 3 de daño y cada nivel de armadura, 2 de defensa. No hay materiales.
- **Máximo de 10 partidas** por usuario.

## Escrituras atómicas

- **Crear partida:** el límite se comprueba en el filtro de la misma escritura.
- **Registrar progreso, repartir puntos y mejorar equipo:** solo escriben si la partida sigue como se leyó (mismo `ultimaVezJugada`, que cada escritura renueva); si otra petición la cambió, vuelven a leer y a aplicar, hasta 3 veces.
- **Borrar partida:** quita la partida y limpia `partidaActiva` en una sola actualización con pipeline.

## Qué NO debe hacer

- No crea conexiones directas: siempre usa `conexionBD`.
- No sabe nada de HTTP (rutas, códigos, JSON): eso es de la capa **servicio**.

```
servicio  ──►  negocio  ──►  conexion
                  └──►  dto
```
