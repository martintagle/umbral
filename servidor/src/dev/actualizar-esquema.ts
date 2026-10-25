/**
 * Aplica bd/esquema-usuarios.json como validador de rpg.usuarios en Atlas y
 * asegura los índices únicos. Necesita un usuario con permiso dbAdmin
 * (readWrite no basta para collMod).
 */
import 'dotenv/config';

import { conexionBD } from '../conexion/conexion-bd.js';
import { prepararColeccion } from '../negocio/coleccion-usuarios.js';

await prepararColeccion();
console.log('Validador e índices de rpg.usuarios actualizados.');
await conexionBD.cerrar();
