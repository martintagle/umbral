import { MongoServerError, ObjectId } from 'mongodb';

export type TipoError =
  | 'validacion'
  | 'autenticacion'
  | 'prohibido'
  | 'no-encontrado'
  | 'conflicto';

/** Error de negocio con un mensaje que se puede mostrar al usuario. */
export class NegocioError extends Error {
  constructor(
    mensaje: string,
    readonly tipo: TipoError = 'validacion',
  ) {
    super(mensaje);
    this.name = 'NegocioError';
  }
}

/** Convierte el id en texto que llega de la app al ObjectId de Mongo. */
export function idMongo(id: string): ObjectId {
  if (!ObjectId.isValid(id) || id.length !== 24) {
    throw new NegocioError(`El id "${id}" no es válido.`);
  }
  return new ObjectId(id);
}

/**
 * Ejecuta una operación de Mongo y traduce sus errores de escritura a errores
 * de negocio. Los NegocioError lanzados dentro pasan sin cambios.
 */
export async function conErroresMongo<T>(operacion: () => Promise<T>): Promise<T> {
  try {
    return await operacion();
  } catch (e) {
    throw traducir(e);
  }
}

function traducir(e: unknown): unknown {
  if (!(e instanceof MongoServerError)) return e;
  if (e.code === 11000) {
    const campo = Object.keys(e.keyPattern ?? {})[0];
    if (campo === 'email') return new NegocioError('El correo ya está registrado.', 'conflicto');
    if (campo === 'username') {
      return new NegocioError('El nombre de usuario ya está en uso.', 'conflicto');
    }
    return new NegocioError('El registro ya existe.', 'conflicto');
  }
  if (e.code === 121) {
    return new NegocioError('Los datos no cumplen el esquema de la colección.');
  }
  return e;
}
