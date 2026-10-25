import express, { type NextFunction, type Request, type Response } from 'express';
import { ZodError } from 'zod';

import { NegocioError, type TipoError } from '../negocio/negocio-error.js';
import { claseServicio } from './clase.servicio.js';
import { partidaServicio } from './partida.servicio.js';
import { usuarioServicio } from './usuario.servicio.js';

const ESTADO_HTTP: Record<TipoError, number> = {
  validacion: 400,
  autenticacion: 401,
  prohibido: 403,
  'no-encontrado': 404,
  conflicto: 409,
};

export function crearApp() {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '100kb' }));

  app.get('/api/salud', (_req, res) => {
    res.json({ ok: true });
  });
  app.use('/api/usuarios', usuarioServicio);
  app.use('/api/partidas', partidaServicio);
  app.use('/api/clases', claseServicio);

  app.use((_req, res) => {
    res.status(404).json({ error: 'Ruta no encontrada.' });
  });

  // Express 5 pasa aquí también los errores de las rutas async.
  app.use((e: unknown, _req: Request, res: Response, _next: NextFunction) => {
    if (e instanceof NegocioError) {
      res.status(ESTADO_HTTP[e.tipo]).json({ error: e.message });
    } else if (e instanceof ZodError) {
      res.status(400).json({ error: e.issues[0]?.message ?? 'Datos no válidos.' });
    } else if (e instanceof SyntaxError) {
      res.status(400).json({ error: 'El cuerpo de la petición no es JSON válido.' });
    } else {
      console.error(e);
      res.status(500).json({ error: 'Error interno del servidor.' });
    }
  });

  return app;
}
