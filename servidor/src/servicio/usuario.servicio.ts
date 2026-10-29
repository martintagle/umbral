import { Router } from 'express';

import { usuarioNegocio } from '../negocio/usuario.negocio.js';
import { firmarToken, idDeSesion, requiereSesion } from './autenticacion.js';
import { limiteAcceso } from './limites.js';
import * as v from './validacion.js';

export const usuarioServicio = Router();

usuarioServicio.post('/registro', limiteAcceso, async (req, res) => {
  const { username, email, password } = v.registro.parse(req.body);
  const usuario = await usuarioNegocio.registrar(username, email, password);
  res.status(201).json({ token: firmarToken(usuario.id), usuario });
});

usuarioServicio.post('/login', limiteAcceso, async (req, res) => {
  const { identificador, password } = v.login.parse(req.body);
  const usuario = await usuarioNegocio.iniciarSesion(identificador, password);
  res.json({ token: firmarToken(usuario.id), usuario });
});

usuarioServicio.get('/yo', requiereSesion, async (_req, res) => {
  res.json(await usuarioNegocio.obtenerPorId(idDeSesion(res)));
});

usuarioServicio.put('/yo/ajustes', requiereSesion, async (req, res) => {
  await usuarioNegocio.actualizarAjustes(idDeSesion(res), v.ajustes.parse(req.body));
  res.status(204).end();
});

usuarioServicio.delete('/yo', requiereSesion, async (_req, res) => {
  await usuarioNegocio.eliminar(idDeSesion(res));
  res.status(204).end();
});
