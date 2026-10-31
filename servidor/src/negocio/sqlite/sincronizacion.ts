import { ObjectId } from 'mongodb';

import { documentoUsuario, usuarioDto, usuarios } from '../coleccion-usuarios.js';
import { esSinConexion } from '../negocio-error.js';
import { respaldoLocal } from './respaldo-local.js';

/** Tras un fallo de red con Atlas, cuánto se usa solo la copia local. */
const PAUSA_TRAS_FALLO_MS = 10_000;
/** Cada cuánto se intenta enviar a Mongo lo hecho sin conexión. */
const INTERVALO_ENVIO_MS = 30_000;

let caidaHasta = 0;
let enviando: Promise<void> | null = null;
let temporizador: NodeJS.Timeout | null = null;

/** Envía a Mongo los cambios y bajas hechos sin conexión, uno a uno. */
async function enviar(): Promise<void> {
  const coleccion = await usuarios();
  for (const id of respaldoLocal.eliminacionesPendientes()) {
    await coleccion.deleteOne({ _id: new ObjectId(id) });
    respaldoLocal.marcarEliminado(id);
  }
  for (const { usuario, version } of respaldoLocal.usuariosPendientes()) {
    try {
      // El documento local tiene todo lo hecho sin conexión: sustituye al de Mongo.
      await coleccion.replaceOne({ _id: usuario._id }, documentoUsuario(usuario), { upsert: true });
      respaldoLocal.marcarEnviado(usuario._id.toHexString(), version);
    } catch (e) {
      if (esSinConexion(e)) throw e;
      // Por ejemplo, una cuenta creada sin conexión con un correo que ya existe
      // en Mongo. Queda pendiente para revisarla a mano; no frena a las demás.
      console.error(`No se pudo enviar a Mongo el usuario ${usuario.username}: ${(e as Error).message}`);
    }
  }
}

/**
 * Mantiene la copia SQLite ([respaldoLocal]) y Mongo de acuerdo. Con Atlas
 * disponible, todo va a Mongo y se copia en SQLite; sin él, negocio trabaja
 * sobre SQLite y los cambios se envían a Mongo en cuanto vuelve.
 */
export const sincronizacion = {
  /**
   * Hace [enLinea] contra Mongo o, si Atlas no responde, [local] contra la
   * copia. Antes de ir a Mongo le envía lo pendiente, para que tenga todo lo
   * hecho sin él. Si se indica [idCopiar], después copia de Mongo ese usuario.
   */
  async conRespaldo<T>(
    enLinea: () => Promise<T>,
    local: () => T | Promise<T>,
    idCopiar?: string,
  ): Promise<T> {
    if (Date.now() < caidaHasta) return local();
    let resultado: T;
    try {
      if (respaldoLocal.hayPendientes()) await this.enviarPendientes();
      resultado = await enLinea();
    } catch (e) {
      if (!esSinConexion(e)) throw e;
      caidaHasta = Date.now() + PAUSA_TRAS_FALLO_MS;
      return local();
    }
    if (idCopiar) await this.copiarUsuario(idCopiar).catch(() => {});
    return resultado;
  },

  /** Una sola vez a la vez, aunque lo pidan varias peticiones. */
  enviarPendientes(): Promise<void> {
    enviando ??= enviar().finally(() => {
      enviando = null;
    });
    return enviando;
  },

  /** Copia en SQLite la versión de Mongo de un usuario (o lo quita si ya no está). */
  async copiarUsuario(id: string): Promise<void> {
    const documento = await (await usuarios()).findOne({ _id: new ObjectId(id) });
    if (documento) respaldoLocal.guardarDeMongo(usuarioDto(documento));
    else respaldoLocal.eliminarUsuario(id, false);
  },

  /** Copia en SQLite todos los usuarios de Mongo, para poder entrar sin conexión. */
  async copiarTodo(): Promise<void> {
    const ids = new Set<string>();
    for await (const documento of (await usuarios()).find()) {
      const usuario = usuarioDto(documento);
      ids.add(usuario._id.toHexString());
      try {
        respaldoLocal.guardarDeMongo(usuario);
      } catch (e) {
        console.error(`No se pudo copiar el usuario ${usuario.username}: ${(e as Error).message}`);
      }
    }
    respaldoLocal.conservarSolo(ids);
  },

  /**
   * Al arrancar: envía lo pendiente y copia la base. Después, cada 30
   * segundos, vuelve a intentar enviar lo que quede.
   */
  async iniciar(): Promise<void> {
    try {
      await this.enviarPendientes();
      await this.copiarTodo();
    } catch (e) {
      if (!esSinConexion(e)) throw e;
      console.warn('MongoDB Atlas no responde: se trabaja con la copia local (SQLite).');
    }
    temporizador ??= setInterval(() => {
      if (!respaldoLocal.hayPendientes()) return;
      this.enviarPendientes().then(
        () => console.log('Cambios hechos sin conexión enviados a MongoDB Atlas.'),
        (e: unknown) => {
          if (!esSinConexion(e)) console.error(e);
        },
      );
    }, INTERVALO_ENVIO_MS);
    temporizador.unref();
  },

  detener(): void {
    if (temporizador) clearInterval(temporizador);
    temporizador = null;
  },
};
