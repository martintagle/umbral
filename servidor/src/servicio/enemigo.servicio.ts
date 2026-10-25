import { Router } from 'express';

import { enemigoNegocio } from '../negocio/enemigo.negocio.js';

/** Lo que da cada enemigo al ser derrotado. Es público: no requiere sesión. */
export const enemigoServicio = Router();

enemigoServicio.get('/', (_req, res) => {
  res.json(enemigoNegocio.catalogo());
});
