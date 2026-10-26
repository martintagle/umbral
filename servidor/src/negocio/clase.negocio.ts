import { CLASES_CODIGO, type ClaseCodigo } from '../dto/clase-codigo.js';
import type { ClaseDto } from '../dto/clase.dto.js';
import { clases } from './coleccion-clases.js';
import { NegocioError } from './negocio-error.js';

let cache: ReadonlyMap<ClaseCodigo, ClaseDto> | null = null;

function enCache(): ReadonlyMap<ClaseCodigo, ClaseDto> {
  if (!cache) throw new Error('Las clases no están cargadas: llama a claseNegocio.cargar() al arrancar.');
  return cache;
}

/**
 * Colección `clases`. Son datos que no cambian mientras la API está en marcha:
 * se leen una vez al arrancar y después se sirven desde memoria.
 */
export const claseNegocio = {
  async cargar(): Promise<void> {
    const documentos = await (await clases()).find().toArray();
    const porCodigo = new Map(documentos.map((c) => [c._id, c]));
    const faltan = CLASES_CODIGO.filter((codigo) => !porCodigo.has(codigo));
    if (faltan.length > 0) {
      throw new Error(
        `Faltan clases en rpg.clases: ${faltan.join(', ')}. Ejecuta "npm run bd:esquema" para crearlas.`,
      );
    }
    // En el orden de CLASES_CODIGO, que es el que muestra la app.
    cache = new Map(CLASES_CODIGO.map((codigo) => [codigo, porCodigo.get(codigo)!]));
  },

  listar(): ClaseDto[] {
    return [...enCache().values()];
  },

  obtener(codigo: string): ClaseDto {
    const clase = enCache().get(codigo as ClaseCodigo);
    if (!clase) throw new NegocioError(`La clase "${codigo}" no existe.`);
    return clase;
  },
};
