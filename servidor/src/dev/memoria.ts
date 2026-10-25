/**
 * Arranca la API con una base MongoDB temporal en memoria, con el mismo
 * validador e índices que la colección de Atlas. Sirve para probar sin
 * credenciales; los datos se pierden al cerrarla.
 */
import { readFile } from 'node:fs/promises';

import { MongoClient } from 'mongodb';
import { MongoMemoryServer } from 'mongodb-memory-server';

const servidor = await MongoMemoryServer.create();
process.env.MONGO_URI = `${servidor.getUri()}rpg`;
process.env.JWT_SECRETO ??= 'solo-para-pruebas-locales';

const esquema = JSON.parse(
  await readFile(new URL('../../bd/esquema-usuarios.json', import.meta.url), 'utf8'),
);
const cliente = await MongoClient.connect(process.env.MONGO_URI);
const db = cliente.db('rpg');
await db.createCollection('usuarios', { validator: { $jsonSchema: esquema } });
await db.collection('usuarios').createIndex({ email: 1 }, { unique: true });
await db.collection('usuarios').createIndex({ username: 1 }, { unique: true });
await cliente.close();

console.log('Base en memoria lista (rpg.usuarios con validador e índices).');
await import('../index.js');
