/**
 * Inserta en rpg.clases las clases de bd/clases.json que falten, sin tocar las
 * que ya existen ni los validadores. Basta con un usuario readWrite.
 */
import 'dotenv/config';

import { conexionBD } from '../conexion/conexion-bd.js';
import { insertarClasesFaltantes } from '../negocio/coleccion-clases.js';

const insertadas = await insertarClasesFaltantes();
console.log(
  insertadas.length > 0
    ? `Clases insertadas en rpg.clases: ${insertadas.join(', ')}.`
    : 'rpg.clases ya tenía todas las clases: no se insertó nada.',
);
await conexionBD.cerrar();
