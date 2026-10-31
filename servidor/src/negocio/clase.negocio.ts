import { CLASES_CODIGO, type ClaseCodigo } from '../dto/clase-codigo.js';
import type { ClaseDto } from '../dto/clase.dto.js';
import { clases, clasesIniciales } from './coleccion-clases.js';
import { esSinConexion, NegocioError } from './negocio-error.js';
import { respaldoLocal } from './sqlite/respaldo-local.js';
import { personajeNegocio, type CatalogoClases, type ClaseInicial } from './personaje.negocio.js';

/** Clase tal como la entrega negocio: `_id` (el código) sale como `id`. */
export type ClasePublica = Omit<ClaseDto, '_id'> & { id: ClaseCodigo };

export interface CatalogoPublico {
  apariencias: CatalogoClases['apariencias'];
  clases: (Omit<ClaseInicial, 'clase'> & { clase: ClasePublica })[];
}

function publica(c: ClaseDto): ClasePublica {
  return {
    id: c._id,
    nombre: c.nombre,
    arma: c.arma,
    descripcion: c.descripcion,
    atributosBase: c.atributosBase,
  };
}

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
  /**
   * Lee las clases de Mongo y las copia en SQLite. Sin Atlas, usa esa copia
   * y, si aún no la hay (primer arranque sin conexión), `bd/clases.json`.
   */
  async cargar(): Promise<void> {
    let documentos: ClaseDto[];
    try {
      documentos = await (await clases()).find().toArray();
      respaldoLocal.guardarClases(documentos);
    } catch (e) {
      if (!esSinConexion(e)) throw e;
      const copia = respaldoLocal.clases();
      documentos = copia.length > 0 ? copia : await clasesIniciales();
    }
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

  /** Las clases con lo que tendría un personaje nuevo de cada una. */
  catalogo(): CatalogoPublico {
    const { apariencias, clases } = personajeNegocio.catalogo([...enCache().values()]);
    return {
      apariencias,
      clases: clases.map((inicial) => ({ ...inicial, clase: publica(inicial.clase) })),
    };
  },

  obtener(codigo: string): ClaseDto {
    const clase = enCache().get(codigo as ClaseCodigo);
    if (!clase) throw new NegocioError(`La clase "${codigo}" no existe.`);
    return clase;
  },
};
