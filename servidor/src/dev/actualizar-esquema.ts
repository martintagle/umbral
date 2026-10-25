/**
 * Aplica bd/esquema-usuarios.json como validador de rpg.usuarios en Atlas y
 * asegura los índices únicos. Necesita un usuario con permiso dbAdmin
 * (readWrite no basta para collMod).
 */
import 'dotenv/config';

import { readFile } from 'node:fs/promises';

import { conexionBD } from '../conexion/conexion-bd.js';

const esquema = JSON.parse(
  await readFile(new URL('../../bd/esquema-usuarios.json', import.meta.url), 'utf8'),
);
const db = await conexionBD.abrir();
await db.command({ collMod: 'usuarios', validator: { $jsonSchema: esquema } });
await db.collection('usuarios').createIndex({ email: 1 }, { unique: true });
await db.collection('usuarios').createIndex({ username: 1 }, { unique: true });
console.log('Validador e índices de rpg.usuarios actualizados.');
await conexionBD.cerrar();
