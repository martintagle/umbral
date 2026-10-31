/**
 * Arranca la API con una base MongoDB temporal en memoria, con los mismos
 * validadores, índices y clases que las colecciones de Atlas. Sirve para probar sin
 * credenciales; los datos se pierden al cerrarla.
 */
import { MongoMemoryServer } from 'mongodb-memory-server';

import { prepararColeccionClases } from '../negocio/coleccion-clases.js';
import { prepararColeccion } from '../negocio/coleccion-usuarios.js';

const servidor = await MongoMemoryServer.create();
process.env.MONGO_URI = `${servidor.getUri()}rpg`;
process.env.JWT_SECRETO ??= 'solo-para-pruebas-locales-nunca-en-produccion';
// La copia SQLite también es temporal: no se mezcla con la de Atlas.
process.env.SQLITE_RUTA ??= ':memory:';

// Usa la misma conexión que la API: index.ts la encuentra ya abierta.
await prepararColeccion();
await prepararColeccionClases();

console.log('Base en memoria lista (rpg.usuarios y rpg.clases con validador e índices).');
await import('../index.js');
