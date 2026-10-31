/**
 * Forma de lo que acepta cada ruta: tipos, campos obligatorios y enteros que
 * caben en un `int` de 32 bits. Las reglas de dominio (longitudes, formatos,
 * rangos del juego) las comprueba la capa de negocio.
 */
import { z } from 'zod';

// Mensajes de error por defecto en español.
z.config(z.locales.es());

const entero = (min: number) => z.number().int().min(min).max(2_147_483_647);
const texto = z.string().max(1000);

export const registro = z.object({ username: texto, email: texto, password: texto });

export const login = z.object({ identificador: texto, password: texto });

export const ajustes = z.object({ idioma: texto, musica: z.number(), efectos: z.number() });

export const crearPartida = z.object({ nombre: texto, claseCodigo: texto, apariencia: texto });

export const partidaActiva = z.object({ partidaId: texto.nullable() });

export const subirAtributos = z.object({
  vida: entero(0),
  fuerza: entero(0),
  destreza: entero(0),
  inteligencia: entero(0),
});

export const mejora = z.object({ pieza: z.enum(['arma', 'armadura']) });

export const progreso = z.object({
  enemigosDerrotados: z.record(z.string().max(64), entero(0)),
  exp: entero(0),
  oro: entero(0),
  muertes: entero(0),
  segundosJugados: entero(0),
  vidaActual: entero(0),
  ubicacion: z.object({
    zonaId: z.string().min(1).max(64),
    x: entero(-100_000),
    y: entero(-100_000),
    ultimoPuntoGuardado: z.string().max(64).nullable(),
  }),
  cofresAbiertos: z.array(z.string().max(64)).max(100).optional(),
});
