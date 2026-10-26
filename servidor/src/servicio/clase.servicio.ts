import { Router } from 'express';

import { claseNegocio } from '../negocio/clase.negocio.js';
import { personajeNegocio } from '../negocio/personaje.negocio.js';
import { catalogoJson } from './respuestas.js';

/** Clases disponibles con sus estadísticas iniciales. Es público: no requiere sesión. */
export const claseServicio = Router();

claseServicio.get('/', (_req, res) => {
  res.json(catalogoJson(personajeNegocio.catalogo(claseNegocio.listar())));
});
