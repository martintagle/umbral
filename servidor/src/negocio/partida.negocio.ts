import { ObjectId } from 'mongodb';

import type { PartidaDto } from '../dto/partida.dto.js';
import { usuarios } from './coleccion-usuarios.js';
import { conErroresMongo, idMongo, NegocioError } from './negocio-error.js';
import { personajeNegocio, type Progreso } from './personaje.negocio.js';

const MAXIMO_PARTIDAS = 10;
/** Reintentos si otra petición guarda la misma partida a la vez. */
const INTENTOS_GUARDADO = 3;

const noExisteUsuario = () => new NegocioError('El usuario no existe.', 'no-encontrado');
const noExistePartida = () => new NegocioError('La partida no existe.', 'no-encontrado');

async function listarPartidas(idUsuario: string): Promise<PartidaDto[]> {
  const usuario = await (await usuarios()).findOne(
    { _id: idMongo(idUsuario) },
    { projection: { partidas: 1 } },
  );
  if (!usuario) throw noExisteUsuario();
  return usuario.partidas;
}

/**
 * Operaciones sobre el array `partidas` embebido en cada usuario. Las partidas
 * no tienen colección propia: cada operación es una sola escritura atómica
 * sobre el documento del usuario.
 */
export const partidaNegocio = {
  listarPartidas,

  async crearPartida(
    idUsuario: string,
    nombre: string,
    clase: string,
    apariencia: string,
  ): Promise<PartidaDto> {
    const ahora = new Date();
    const partida: PartidaDto = {
      partidaId: new ObjectId().toHexString(),
      creadaEn: ahora,
      ultimaVezJugada: ahora,
      personaje: personajeNegocio.personajeInicial(nombre, clase, apariencia),
    };
    const coleccion = await usuarios();
    // El límite se comprueba en el propio filtro: no puede colarse una partida
    // de más entre la comprobación y la escritura.
    const resultado = await conErroresMongo(() =>
      coleccion.updateOne(
        { _id: idMongo(idUsuario), [`partidas.${MAXIMO_PARTIDAS - 1}`]: { $exists: false } },
        { $push: { partidas: partida }, $set: { actualizadoEn: ahora } },
      ),
    );
    if (resultado.matchedCount === 0) {
      await listarPartidas(idUsuario); // distingue "no existe" de "límite"
      throw new NegocioError(`No puedes tener más de ${MAXIMO_PARTIDAS} partidas.`, 'conflicto');
    }
    return partida;
  },

  /**
   * Aplica el progreso con las reglas del personaje. La escritura solo ocurre
   * si la partida sigue como se leyó (mismo `ultimaVezJugada`); si otra
   * petición la cambió entre medias, se vuelve a leer y a aplicar.
   */
  async registrarProgreso(
    idUsuario: string,
    partidaId: string,
    progreso: Progreso,
  ): Promise<PartidaDto> {
    const id = idMongo(idUsuario);
    const coleccion = await usuarios();
    for (let intento = 0; intento < INTENTOS_GUARDADO; intento++) {
      const anterior = (await listarPartidas(idUsuario)).find(
        (p) => p.partidaId === partidaId,
      );
      if (!anterior) throw noExistePartida();

      const ahora = new Date();
      const segundosDesdeGuardado =
        (ahora.getTime() - anterior.ultimaVezJugada.getTime()) / 1000;
      const personaje = personajeNegocio.aplicarProgreso(
        anterior.personaje,
        progreso,
        segundosDesdeGuardado,
      );
      const resultado = await conErroresMongo(() =>
        coleccion.updateOne(
          {
            _id: id,
            partidas: {
              $elemMatch: { partidaId, ultimaVezJugada: anterior.ultimaVezJugada },
            },
          },
          {
            $set: {
              'partidas.$.personaje': personaje,
              'partidas.$.ultimaVezJugada': ahora,
              actualizadoEn: ahora,
            },
          },
        ),
      );
      if (resultado.matchedCount === 1) {
        return { ...anterior, ultimaVezJugada: ahora, personaje };
      }
    }
    throw new NegocioError(
      'La partida cambió mientras se guardaba. Inténtalo de nuevo.',
      'conflicto',
    );
  },

  /**
   * Quita la partida y, si era la activa, deja `partidaActiva` a null, en una
   * sola escritura. `$literal` evita que un id que empiece por '$' se lea
   * como un campo.
   */
  async eliminarPartida(idUsuario: string, partidaId: string): Promise<void> {
    const id = { $literal: partidaId };
    const resultado = await (await usuarios()).updateOne(
      { _id: idMongo(idUsuario), 'partidas.partidaId': partidaId },
      [
        {
          $set: {
            partidas: {
              $filter: { input: '$partidas', cond: { $ne: ['$$this.partidaId', id] } },
            },
            partidaActiva: {
              $cond: [{ $eq: ['$partidaActiva', id] }, null, '$partidaActiva'],
            },
            actualizadoEn: '$$NOW',
          },
        },
      ],
    );
    if (resultado.matchedCount === 0) throw noExistePartida();
  },

  /** Con `partidaId` null deja al usuario sin partida activa. */
  async seleccionarPartidaActiva(idUsuario: string, partidaId: string | null): Promise<void> {
    const filtro =
      partidaId === null
        ? { _id: idMongo(idUsuario) }
        : { _id: idMongo(idUsuario), 'partidas.partidaId': partidaId };
    const resultado = await (await usuarios()).updateOne(filtro, {
      $set: { partidaActiva: partidaId, actualizadoEn: new Date() },
    });
    if (resultado.matchedCount === 0) {
      throw partidaId === null ? noExisteUsuario() : noExistePartida();
    }
  },
};
