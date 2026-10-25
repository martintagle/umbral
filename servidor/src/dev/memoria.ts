/**
 * Arranca la API con una base MongoDB temporal en memoria, con el mismo
 * validador e índices que la colección de Atlas. Sirve para probar sin
 * credenciales; los datos se pierden al cerrarla.
 */
import { MongoMemoryServer } from 'mongodb-memory-server';

import { prepararColeccion } from '../negocio/coleccion-usuarios.js';

const servidor = await MongoMemoryServer.create();
process.env.MONGO_URI = `${servidor.getUri()}rpg`;
process.env.JWT_SECRETO ??= 'solo-para-pruebas-locales-nunca-en-produccion';

// Usa la misma conexión que la API: index.ts la encuentra ya abierta.
await prepararColeccion();

console.log('Base en memoria lista (rpg.usuarios con validador e índices).');
await import('../index.js');
