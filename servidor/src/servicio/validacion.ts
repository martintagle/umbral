/**
 * Forma de lo que acepta cada ruta: tipos, campos obligatorios y enteros que
 * caben en un `int` de 32 bits. Las reglas de dominio (longitudes, formatos,
 * rangos del juego) las comprueba la capa de negocio.
 */
import type { NextFunction, Request, Response } from 'express';
import { z } from 'zod';

import { NegocioError } from '../negocio/negocio-error.js';

/**
 * Rechaza los cuerpos con claves de operador de Mongo (`$gt`, `$where`...) o
 * con caracteres nulos, a cualquier profundidad: así ningún dato del cliente
 * puede convertirse en parte de una consulta. Las consultas de SQLite ya van
 * con parámetros (`?`) y nunca pegan texto del cliente.
 */
export function sinInyeccion(req: Request, _res: Response, next: NextFunction): void {
  const pendientes: unknown[] = [req.body];
  while (pendientes.length > 0) {
    const valor = pendientes.pop();
    if (typeof valor === 'string') {
      if (valor.includes('\0')) throw new NegocioError('Datos no válidos.');
    } else if (valor !== null && typeof valor === 'object') {
      for (const [clave, hijo] of Object.entries(valor)) {
        if (clave.startsWith('$') || clave.includes('\0')) {
          throw new NegocioError('Datos no válidos.');
        }
        pendientes.push(hijo);
      }
    }
  }
  next();
}

// Mensajes de error por defecto en español.
z.config(z.locales.es());

const entero = (min: number) => z.number().int().min(min).max(2_147_483_647);
const texto = z.string().max(1000);

export const registro = z.object({ username: texto, email: texto, password: texto });

export const login = z.object({ identificador: texto, password: texto });

/** El token que da Google al elegir la cuenta en el teléfono. */
export const google = z.object({ idToken: z.string().min(1).max(4096) });

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
  fogatasEncendidas: z.array(z.string().max(64)).max(100).optional(),
  enemigosCaidos: z.record(z.string().max(80), entero(0)).optional(),
  dialogosLeidos: z.array(z.string().max(32)).max(40).optional(),
  mecanismosActivados: z.array(z.string().max(48)).max(200).optional(),
});
