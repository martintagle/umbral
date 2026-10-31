/**
 * Demuestra la copia SQLite de negocio con una base MongoDB temporal:
 *
 * 1. Con Mongo: crea una cuenta, una partida y guarda progreso.
 * 2. Apaga Mongo: entra, guarda más progreso, crea otra partida y otra
 *    cuenta. Todo queda en SQLite, pendiente de enviar.
 * 3. Enciende Mongo: envía lo pendiente y comprueba que Mongo lo tiene.
 *
 * No necesita Atlas ni `.env`. Termina con error si algo no cuadra.
 */
import assert from 'node:assert/strict';

import { MongoMemoryServer } from 'mongodb-memory-server';

import { conexionBD } from '../conexion/conexion-bd.js';
import { claseNegocio } from '../negocio/clase.negocio.js';
import { prepararColeccionClases } from '../negocio/coleccion-clases.js';
import { prepararColeccion, usuarios } from '../negocio/coleccion-usuarios.js';
import { partidaNegocio } from '../negocio/partida.negocio.js';
import type { Progreso } from '../negocio/personaje.negocio.js';
import { respaldoLocal } from '../negocio/sqlite/respaldo-local.js';
import { sincronizacion } from '../negocio/sqlite/sincronizacion.js';
import { usuarioNegocio } from '../negocio/usuario.negocio.js';

const mongo = await MongoMemoryServer.create();
process.env.MONGO_URI = `${mongo.getUri()}rpg`;

const esperar = (ms: number) => new Promise((r) => setTimeout(r, ms));
const progreso = (x: number): Progreso => ({
  enemigosDerrotados: { 'ojo-errante': 2 },
  exp: 16,
  oro: 6,
  muertes: 0,
  segundosJugados: 4,
  vidaActual: 100,
  ubicacion: { zonaId: 'tierras-del-umbral', x, y: 10, ultimoPuntoGuardado: null },
});
const paso = (texto: string) => console.log(`\n▸ ${texto}`);

try {
  await prepararColeccion();
  await prepararColeccionClases();
  respaldoLocal.abrir(':memory:');
  await claseNegocio.cargar();
  await sincronizacion.iniciar();

  paso('Con Mongo: cuenta, partida y un guardado');
  const ana = await usuarioNegocio.registrar('ana', 'ana@umbral.test', 'contrasena-larga');
  const primera = await partidaNegocio.crearPartida(ana.id, 'Ana', 'vagabundo', 'mujer');
  const id = primera.partida.partidaId;
  await esperar(4_000); // el progreso no puede durar más que el tiempo real
  await partidaNegocio.registrarProgreso(ana.id, id, progreso(1));
  assert.equal(respaldoLocal.hayPendientes(), false, 'con Mongo no queda nada pendiente');
  assert.equal(respaldoLocal.usuario(ana.id)?.partidas[0]?.personaje.exp, primera.partida.personaje.exp + 16);
  console.log('  Mongo y SQLite tienen la partida con +16 de experiencia.');

  paso('Se apaga Mongo');
  await mongo.stop({ doCleanup: false });

  paso('Sin Mongo: login, guardado, partida nueva y cuenta nueva (en SQLite)');
  const inicio = Date.now();
  await usuarioNegocio.iniciarSesion('ana', 'contrasena-larga');
  console.log(`  El primer intento espera a Atlas ${((Date.now() - inicio) / 1000).toFixed(1)} s; los siguientes van directos a SQLite.`);
  await esperar(4_000);
  const local = await partidaNegocio.registrarProgreso(ana.id, id, progreso(2));
  await partidaNegocio.crearPartida(ana.id, 'Ana II', 'mago', 'mujer');
  const leo = await usuarioNegocio.registrar('leo', 'leo@umbral.test', 'otra-contrasena');
  assert.equal((await partidaNegocio.listarPartidas(ana.id)).length, 2);
  assert.equal(respaldoLocal.hayPendientes(), true, 'sin Mongo, los cambios quedan pendientes');
  console.log(`  Experiencia en SQLite: ${local.partida.personaje.exp}. Pendientes: ana y leo.`);

  paso('Vuelve Mongo: se envía lo pendiente');
  await mongo.start(true);
  await sincronizacion.enviarPendientes();
  assert.equal(respaldoLocal.hayPendientes(), false, 'tras sincronizar no queda nada pendiente');

  const enMongo = await (await usuarios()).findOne({ username: 'ana' });
  assert.equal(enMongo?.partidas.length, 2, 'Mongo tiene la partida creada sin conexión');
  assert.equal(enMongo?.partidas[0]?.personaje.exp, local.partida.personaje.exp);
  assert.equal(enMongo?.partidas[0]?.personaje.ubicacion.x, 2);
  assert.ok(await (await usuarios()).findOne({ username: leo.username }), 'Mongo tiene la cuenta creada sin conexión');
  console.log(`  Mongo tiene las 2 partidas de ana (experiencia ${enMongo?.partidas[0]?.personaje.exp}) y la cuenta de leo.`);

  console.log('\nTodo cuadra: SQLite cubrió la caída de Mongo y lo sincronizó al volver.');
} finally {
  sincronizacion.detener();
  respaldoLocal.cerrar();
  await conexionBD.cerrar();
  await mongo.stop();
}
