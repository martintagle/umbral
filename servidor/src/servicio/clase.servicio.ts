import { Router } from 'express';

import { personajeNegocio } from '../negocio/personaje.negocio.js';

/** Clases disponibles con sus estadísticas iniciales. Es público: no requiere sesión. */
export const claseServicio = Router();

claseServicio.get('/', (_req, res) => {
  res.json(personajeNegocio.catalogo());
});
