/**
 * Aplica bd/esquema-usuarios.json y bd/esquema-clases.json como validadores de
 * rpg.usuarios y rpg.clases en Atlas, asegura los índices únicos e inserta las
 * clases de bd/clases.json que falten. Necesita un usuario con permiso dbAdmin
 * (readWrite no basta para collMod).
 */
import 'dotenv/config';

import { conexionBD } from '../conexion/conexion-bd.js';
import { prepararColeccionClases } from '../negocio/coleccion-clases.js';
import { prepararColeccion } from '../negocio/coleccion-usuarios.js';

await prepararColeccion();
await prepararColeccionClases();
console.log('Validadores e índices de rpg.usuarios y rpg.clases actualizados.');
await conexionBD.cerrar();
