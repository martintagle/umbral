import { readFile } from 'node:fs/promises';

import { conexionBD } from '../conexion/conexion-bd.js';
import type { ClaseDto } from '../dto/clase.dto.js';

const COLECCION = 'clases';

export const clases = () => conexionBD.coleccion<ClaseDto>(COLECCION);

const leerJson = async (ruta: string) =>
  JSON.parse(await readFile(new URL(ruta, import.meta.url), 'utf8'));

/**
 * Aplica `bd/esquema-clases.json` como validador de la colección (la crea si no
 * existe) e inserta las clases de `bd/clases.json` que falten. Las que ya
 * están no se tocan. Lo usan los scripts de `dev/`; en Atlas necesita un
 * usuario con permiso dbAdmin.
 */
export async function prepararColeccionClases(): Promise<void> {
  const validator = { $jsonSchema: await leerJson('../../bd/esquema-clases.json') };
  const db = await conexionBD.abrir();
  if (await db.listCollections({ name: COLECCION }).hasNext()) {
    await db.command({ collMod: COLECCION, validator });
  } else {
    await db.createCollection(COLECCION, { validator });
  }
  const iniciales: ClaseDto[] = await leerJson('../../bd/clases.json');
  await (await clases()).bulkWrite(
    iniciales.map(({ _id, ...clase }) => ({
      updateOne: { filter: { _id }, update: { $setOnInsert: clase }, upsert: true },
    })),
  );
}
