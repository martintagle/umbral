import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

import { NegocioError } from '../negocio/negocio-error.js';

const DURACION = '30d';

function secreto(): string {
  const valor = process.env.JWT_SECRETO;
  if (!valor) throw new Error('Falta JWT_SECRETO en el archivo .env.');
  return valor;
}

export function firmarToken(idUsuario: string): string {
  return jwt.sign({}, secreto(), { subject: idUsuario, expiresIn: DURACION });
}

/** Exige `Authorization: Bearer <token>` y deja el id en `res.locals.idUsuario`. */
export function requiereSesion(req: Request, res: Response, next: NextFunction): void {
  const [tipo, token] = req.headers.authorization?.split(' ') ?? [];
  if (tipo !== 'Bearer' || !token) {
    throw new NegocioError('Inicia sesión para continuar.', 'autenticacion');
  }
  try {
    const datos = jwt.verify(token, secreto());
    if (typeof datos === 'string' || !datos.sub) throw new Error('sin sujeto');
    res.locals.idUsuario = datos.sub;
  } catch {
    throw new NegocioError('La sesión caducó. Vuelve a iniciar sesión.', 'autenticacion');
  }
  next();
}

export function idDeSesion(res: Response): string {
  return res.locals.idUsuario as string;
}
