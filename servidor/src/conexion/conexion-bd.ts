import { setServers } from 'node:dns';

import { MongoClient, type Collection, type Db, type Document } from 'mongodb';

export const BASE_DATOS = 'rpg';

/** Tras un intento fallido, cuánto se espera antes de volver a intentarlo. */
const ESPERA_REINTENTO_MS = 10_000;

/** Atlas no responde (sin internet, caído o la IP no está permitida). */
export class SinConexionBD extends Error {
  constructor(mensaje: string) {
    super(mensaje);
    this.name = 'SinConexionBD';
  }
}

/**
 * Única puerta de acceso a MongoDB Atlas. Solo la usa la capa de negocio.
 * La cadena de conexión se lee de la variable de entorno MONGO_URI (archivo .env).
 *
 * Si Atlas no responde, falla pronto con [SinConexionBD]: a los 5 segundos y,
 * durante los 10 siguientes, sin volver a intentarlo. Así negocio puede
 * seguir con su copia local sin dejar las peticiones esperando.
 */
class ConexionBD {
  private cliente: MongoClient | null = null;
  private abriendo: Promise<Db> | null = null;
  private ultimoFallo = 0;

  /** Devuelve la base de datos, conectándose la primera vez. */
  abrir(): Promise<Db> {
    if (this.cliente) return Promise.resolve(this.cliente.db(BASE_DATOS));
    if (Date.now() - this.ultimoFallo < ESPERA_REINTENTO_MS) {
      return Promise.reject(new SinConexionBD('MongoDB Atlas no responde.'));
    }
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
    // En algunos Windows, Node toma 127.0.0.1 como DNS y no resuelve el registro
    // SRV de las cadenas mongodb+srv://. DNS_SERVIDORES (p. ej. "8.8.8.8,1.1.1.1")
    // le indica qué servidores usar.
    const dns = process.env.DNS_SERVIDORES;
    if (dns) setServers(dns.split(',').map((s) => s.trim()));
    const base = new URL(uri).pathname.replace(/^\//, '');
    if (base !== BASE_DATOS) {
      throw new Error(
        `MONGO_URI debe apuntar a la base "${BASE_DATOS}". Añade /${BASE_DATOS} después del host.`,
      );
    }
    // Sin respuesta en 5 s se da por caído (por defecto, el driver espera 30).
    const cliente = new MongoClient(uri, { serverSelectionTimeoutMS: 5_000 });
    try {
      await cliente.connect();
    } catch (e) {
      this.ultimoFallo = Date.now();
      await cliente.close().catch(() => {});
      throw new SinConexionBD(
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
