import { MongoClient, type Collection, type Db, type Document } from 'mongodb';

export const BASE_DATOS = 'rpg';

/**
 * Única puerta de acceso a MongoDB Atlas. Solo la usa la capa de negocio.
 * La cadena de conexión se lee de la variable de entorno MONGO_URI (archivo .env).
 */
class ConexionBD {
  private cliente: MongoClient | null = null;
  private abriendo: Promise<Db> | null = null;

  /** Devuelve la base de datos, conectándose la primera vez. */
  abrir(): Promise<Db> {
    if (this.cliente) return Promise.resolve(this.cliente.db(BASE_DATOS));
    // Evita abrir dos conexiones si llegan varias peticiones a la vez.
    this.abriendo ??= this.conectar().finally(() => {
      this.abriendo = null;
    });
    return this.abriendo;
  }

  private async conectar(): Promise<Db> {
    const uri = process.env.MONGO_URI;
    if (!uri) {
      throw new Error('Falta MONGO_URI. Copia .env.ejemplo como .env y rellénalo.');
    }
    const base = new URL(uri).pathname.replace(/^\//, '');
    if (base !== BASE_DATOS) {
      throw new Error(
        `MONGO_URI debe apuntar a la base "${BASE_DATOS}". Añade /${BASE_DATOS} después del host.`,
      );
    }
    const cliente = new MongoClient(uri);
    try {
      await cliente.connect();
    } catch (e) {
      throw new Error(
        'No se pudo conectar a MongoDB Atlas. Revisa usuario y contraseña en Database Access, ' +
          `la IP en Network Access y la conexión a internet. Detalle: ${(e as Error).message}`,
      );
    }
    this.cliente = cliente;
    return cliente.db(BASE_DATOS);
  }

  async coleccion<T extends Document>(nombre: string): Promise<Collection<T>> {
    const db = await this.abrir();
    return db.collection<T>(nombre);
  }

  async cerrar(): Promise<void> {
    await this.cliente?.close();
    this.cliente = null;
  }
}

export const conexionBD = new ConexionBD();
