import { ObjectId } from 'mongodb';

import type { AtributosDto } from '../dto/atributos.dto.js';
import type { PartidaDto } from '../dto/partida.dto.js';
import type { PersonajeDto } from '../dto/personaje.dto.js';
import type { UsuarioDto } from '../dto/usuario.dto.js';
import { claseNegocio } from './clase.negocio.js';
import { usuarios } from './coleccion-usuarios.js';
import { conErroresMongo, idMongo, NegocioError } from './negocio-error.js';
import {
  personajeNegocio,
  type Combate,
  type PiezaEquipo,
  type Progreso,
} from './personaje.negocio.js';
import { respaldoLocal } from './sqlite/respaldo-local.js';
import { sincronizacion } from './sqlite/sincronizacion.js';

const MAXIMO_PARTIDAS = 10;
/** Reintentos si otra petición guarda la misma partida a la vez. */
const INTENTOS_GUARDADO = 3;

/** Partida con los valores de combate que el juego necesita para jugarla. */
export interface PartidaJugable {
  partida: PartidaDto;
  combate: Combate;
}

const jugable = (partida: PartidaDto): PartidaJugable => ({
  partida,
  combate: personajeNegocio.combate(partida.personaje),
});

const noExisteUsuario = () => new NegocioError('El usuario no existe.', 'no-encontrado');
const noExistePartida = () => new NegocioError('La partida no existe.', 'no-encontrado');
const limitePartidas = () =>
  new NegocioError(`No puedes tener más de ${MAXIMO_PARTIDAS} partidas.`, 'conflicto');

async function leerPartidas(idUsuario: string): Promise<PartidaDto[]> {
  const usuario = await (await usuarios()).findOne(
    { _id: idMongo(idUsuario) },
    { projection: { partidas: 1 } },
  );
  if (!usuario) throw noExisteUsuario();
  return usuario.partidas;
}

/** Usuario de la copia local; sin Atlas, es la única fuente. */
function usuarioLocal(idUsuario: string): UsuarioDto {
  idMongo(idUsuario);
  const usuario = respaldoLocal.usuario(idUsuario);
  if (!usuario) throw noExisteUsuario();
  return usuario;
}

/**
 * Sin Atlas: aplica [cambio] al usuario de la copia local y lo guarda como
 * pendiente de enviar a Mongo.
 */
function cambiarLocal(
  idUsuario: string,
  cambio: (anterior: UsuarioDto, ahora: Date) => Omit<UsuarioDto, 'actualizadoEn'>,
): void {
  const ahora = new Date();
  respaldoLocal.guardarCambio({ ...cambio(usuarioLocal(idUsuario), ahora), actualizadoEn: ahora });
}

/**
 * Cambia el personaje de una partida con [cambio]. En Mongo, la escritura
 * solo ocurre si la partida sigue como se leyó (mismo `ultimaVezJugada`, que
 * se renueva en cada cambio); si otra petición la cambió entre medias, se
 * vuelve a leer y a aplicar. Sin Atlas, se aplica sobre la copia local.
 */
function actualizarPersonaje(
  idUsuario: string,
  partidaId: string,
  cambio: (anterior: PartidaDto, ahora: Date) => PersonajeDto,
): Promise<PartidaJugable> {
  return sincronizacion.conRespaldo(
    async () => {
      const id = idMongo(idUsuario);
      const coleccion = await usuarios();
      for (let intento = 0; intento < INTENTOS_GUARDADO; intento++) {
        const anterior = (await leerPartidas(idUsuario)).find((p) => p.partidaId === partidaId);
        if (!anterior) throw noExistePartida();

        const ahora = new Date();
        const personaje = cambio(anterior, ahora);
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
          return jugable({ ...anterior, ultimaVezJugada: ahora, personaje });
        }
      }
      throw new NegocioError('La partida cambió mientras se guardaba. Inténtalo de nuevo.', 'conflicto');
    },
    () => {
      let nueva: PartidaDto | undefined;
      cambiarLocal(idUsuario, (u, ahora) => {
        const anterior = u.partidas.find((p) => p.partidaId === partidaId);
        if (!anterior) throw noExistePartida();
        nueva = { ...anterior, ultimaVezJugada: ahora, personaje: cambio(anterior, ahora) };
        return { ...u, partidas: u.partidas.map((p) => (p.partidaId === partidaId ? nueva! : p)) };
      });
      return jugable(nueva!);
    },
    idUsuario,
  );
}

/**
 * Operaciones sobre el array `partidas` embebido en cada usuario. Las partidas
 * no tienen colección propia: cada operación es una sola escritura atómica
 * sobre el documento del usuario. Si Atlas no responde, se hacen sobre la
 * copia SQLite y se envían a Mongo al volver (ver `sincronizacion`).
 */
export const partidaNegocio = {
  listarPartidas(idUsuario: string): Promise<PartidaJugable[]> {
    return sincronizacion.conRespaldo(
      async () => (await leerPartidas(idUsuario)).map(jugable),
      () => usuarioLocal(idUsuario).partidas.map(jugable),
    );
  },

  crearPartida(
    idUsuario: string,
    nombre: string,
    claseCodigo: string,
    apariencia: string,
  ): Promise<PartidaJugable> {
    const clase = claseNegocio.obtener(claseCodigo);
    const ahora = new Date();
    const partida: PartidaDto = {
      partidaId: new ObjectId().toHexString(),
      creadaEn: ahora,
      ultimaVezJugada: ahora,
      personaje: personajeNegocio.personajeInicial(nombre, clase, apariencia),
    };
    return sincronizacion.conRespaldo(
      async () => {
        const coleccion = await usuarios();
        // El límite se comprueba en el propio filtro: no puede colarse una
        // partida de más entre la comprobación y la escritura.
        const resultado = await conErroresMongo(() =>
          coleccion.updateOne(
            { _id: idMongo(idUsuario), [`partidas.${MAXIMO_PARTIDAS - 1}`]: { $exists: false } },
            { $push: { partidas: partida }, $set: { actualizadoEn: ahora } },
          ),
        );
        if (resultado.matchedCount === 0) {
          await leerPartidas(idUsuario); // distingue "no existe" de "límite"
          throw limitePartidas();
        }
        return jugable(partida);
      },
      () => {
        cambiarLocal(idUsuario, (u) => {
          if (u.partidas.length >= MAXIMO_PARTIDAS) throw limitePartidas();
          return { ...u, partidas: [...u.partidas, partida] };
        });
        return jugable(partida);
      },
      idUsuario,
    );
  },

  /** Aplica el progreso con las reglas del personaje. */
  registrarProgreso(idUsuario: string, partidaId: string, progreso: Progreso): Promise<PartidaJugable> {
    return actualizarPersonaje(idUsuario, partidaId, (anterior, ahora) =>
      personajeNegocio.aplicarProgreso(
        anterior.personaje,
        progreso,
        (ahora.getTime() - anterior.ultimaVezJugada.getTime()) / 1000,
      ),
    );
  },

  /** Sube atributos (y nivel) gastando experiencia en un altar de brasas. */
  subirAtributos(idUsuario: string, partidaId: string, incrementos: AtributosDto): Promise<PartidaJugable> {
    return actualizarPersonaje(idUsuario, partidaId, (anterior) =>
      personajeNegocio.subirAtributos(anterior.personaje, incrementos),
    );
  },

  /** Mejora el arma o la armadura con oro (yunque de la herrería). */
  mejorarEquipo(idUsuario: string, partidaId: string, pieza: PiezaEquipo): Promise<PartidaJugable> {
    return actualizarPersonaje(idUsuario, partidaId, (anterior) =>
      personajeNegocio.mejorarEquipo(anterior.personaje, pieza),
    );
  },

  /**
   * Quita la partida y, si era la activa, deja `partidaActiva` a null, en una
   * sola escritura. `$literal` evita que un id que empiece por '$' se lea
   * como un campo.
   */
  async eliminarPartida(idUsuario: string, partidaId: string): Promise<void> {
    await sincronizacion.conRespaldo(
      async () => {
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
      () =>
        cambiarLocal(idUsuario, (u) => {
          if (!u.partidas.some((p) => p.partidaId === partidaId)) throw noExistePartida();
          return {
            ...u,
            partidas: u.partidas.filter((p) => p.partidaId !== partidaId),
            partidaActiva: u.partidaActiva === partidaId ? null : u.partidaActiva,
          };
        }),
      idUsuario,
    );
  },

  /** Con `partidaId` null deja al usuario sin partida activa. */
  async seleccionarPartidaActiva(idUsuario: string, partidaId: string | null): Promise<void> {
    await sincronizacion.conRespaldo(
      async () => {
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
      () =>
        cambiarLocal(idUsuario, (u) => {
          if (partidaId !== null && !u.partidas.some((p) => p.partidaId === partidaId)) {
            throw noExistePartida();
          }
          return { ...u, partidaActiva: partidaId };
        }),
      idUsuario,
    );
  },
};
