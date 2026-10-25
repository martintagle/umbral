import { Router } from 'express';

import { partidaNegocio } from '../negocio/partida.negocio.js';
import { idDeSesion, requiereSesion } from './autenticacion.js';
import { partidaJugableJson } from './respuestas.js';
import * as v from './validacion.js';

export const partidaServicio = Router();

partidaServicio.use(requiereSesion);

partidaServicio.get('/', async (_req, res) => {
  const partidas = await partidaNegocio.listarPartidas(idDeSesion(res));
  res.json(partidas.map(partidaJugableJson));
});

partidaServicio.post('/', async (req, res) => {
  const { nombre, clase, apariencia } = v.crearPartida.parse(req.body);
  const partida = await partidaNegocio.crearPartida(idDeSesion(res), nombre, clase, apariencia);
  res.status(201).json(partidaJugableJson(partida));
});

partidaServicio.put('/activa', async (req, res) => {
  const { partidaId } = v.partidaActiva.parse(req.body);
  await partidaNegocio.seleccionarPartidaActiva(idDeSesion(res), partidaId);
  res.status(204).end();
});

/** Guarda lo ocurrido desde el último guardado; el servidor aplica las reglas. */
partidaServicio.post('/:partidaId/progreso', async (req, res) => {
  const partida = await partidaNegocio.registrarProgreso(
    idDeSesion(res),
    req.params.partidaId,
    v.progreso.parse(req.body),
  );
  res.json(partidaJugableJson(partida));
});

partidaServicio.delete('/:partidaId', async (req, res) => {
  await partidaNegocio.eliminarPartida(idDeSesion(res), req.params.partidaId);
  res.status(204).end();
});
