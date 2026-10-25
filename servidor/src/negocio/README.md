# Capa de Negocio (servidor)

## Qué debe hacer

Contiene **todas las operaciones sobre la base de datos** y **todas las reglas** del juego y de las cuentas. Es la única capa que habla con MongoDB, siempre **a través de la capa de conexión** y usando los **DTO**.

## Qué contiene

| Archivo | Responsabilidad |
|---|---|
| `usuario.negocio.ts` | Registro (hash con bcrypt), login por email o username, ajustes y borrado de la cuenta. |
| `partida.negocio.ts` | Partidas embebidas en el usuario: listar, crear, registrar progreso, borrar y elegir la activa. |
| `personaje.negocio.ts` | Reglas del personaje: estadísticas de cada clase, valores de combate, personaje inicial y aplicación del progreso (subida de nivel). |
| `enemigo.negocio.ts` | Recompensa (exp y oro) de cada enemigo y suma de lo ganado en un progreso. |
| `coleccion-usuarios.ts` | Acceso a la colección `usuarios`, conversión entre el DTO y el documento guardado (los `double` del esquema) y preparación del validador e índices que usan los scripts de `dev/`. |
| `negocio-error.ts` | `NegocioError` con su tipo, conversión de ids y `conErroresMongo`, que traduce los errores de Mongo (11000 duplicado, 121 esquema). |

## Reglas que aplica

- **Cuentas:** username de 3 a 20 caracteres sin `@`, correo válido y en minúsculas, contraseña de 8 a 72 caracteres guardada solo como hash de bcrypt. El login da el mismo mensaje si el usuario no existe o la contraseña es incorrecta, y rechaza las cuentas `baneado` o `eliminado`.
- **Personaje nuevo:** lo crea el servidor con las estadísticas de su clase; la app solo elige clase, apariencia y nombre (de 2 a 16 caracteres).
- **Progreso:** la app envía los hechos (cuántos enemigos de cada tipo derrotó, muertes, segundos, vida y posición) y aquí se calculan la experiencia y el oro con la tabla de recompensas, y se sube de nivel. Se rechaza un progreso con más segundos que el tiempo real desde el último guardado, o con más de un enemigo derrotado por segundo. Al subir de nivel el personaje gana 2 puntos y recupera toda la vida. Así el nivel y la experiencia solo los calcula el servidor.
- **Máximo de 10 partidas** por usuario.

## Escrituras atómicas

- **Crear partida:** el límite se comprueba en el filtro de la misma escritura.
- **Registrar progreso:** solo escribe si la partida sigue como se leyó (mismo `ultimaVezJugada`); si otra petición la cambió, vuelve a leer y a aplicar, hasta 3 veces.
- **Borrar partida:** quita la partida y limpia `partidaActiva` en una sola actualización con pipeline.

## Qué NO debe hacer

- No crea conexiones directas: siempre usa `conexionBD`.
- No sabe nada de HTTP (rutas, códigos, JSON): eso es de la capa **servicio**.

```
servicio  ──►  negocio  ──►  conexion
                  └──►  dto
```
