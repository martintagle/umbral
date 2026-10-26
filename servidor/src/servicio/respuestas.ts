import type { ClaseDto } from '../dto/clase.dto.js';
import type { PartidaDto } from '../dto/partida.dto.js';
import type { PersonajeDto } from '../dto/personaje.dto.js';
import type { UsuarioDto } from '../dto/usuario.dto.js';
import { personajeNegocio, type CatalogoClases, type Combate } from '../negocio/personaje.negocio.js';

/** Partida tal como viaja a la app: fechas en ISO 8601. */
export interface PartidaJson {
  partidaId: string;
  creadaEn: string;
  ultimaVezJugada: string;
  personaje: PersonajeDto;
}

/** Partida con los valores de combate que el juego necesita para jugarla. */
export interface PartidaJugableJson {
  partida: PartidaJson;
  combate: Combate;
}

export function partidaJson(p: PartidaDto): PartidaJson {
  return {
    partidaId: p.partidaId,
    creadaEn: p.creadaEn.toISOString(),
    ultimaVezJugada: p.ultimaVezJugada.toISOString(),
    personaje: p.personaje,
  };
}

export function partidaJugableJson(p: PartidaDto): PartidaJugableJson {
  return { partida: partidaJson(p), combate: personajeNegocio.combate(p.personaje) };
}

/** Usuario tal como viaja a la app: sin `passwordHash` y con `id` en texto. */
export function usuarioJson(u: UsuarioDto) {
  return {
    id: u._id.toHexString(),
    username: u.username,
    email: u.email,
    estado: u.estado,
    creadoEn: u.creadoEn.toISOString(),
    ultimoLogin: u.ultimoLogin?.toISOString() ?? null,
    actualizadoEn: u.actualizadoEn.toISOString(),
    versionEsquema: u.versionEsquema,
    ajustes: u.ajustes,
    partidaActiva: u.partidaActiva,
    partidas: u.partidas.map(partidaJson),
  };
}

/** Clase tal como viaja a la app: `_id` (el código) llega como `id`. */
export function claseJson(c: ClaseDto) {
  return {
    id: c._id,
    nombre: c.nombre,
    arma: c.arma,
    descripcion: c.descripcion,
    atributosBase: c.atributosBase,
  };
}

export function catalogoJson(c: CatalogoClases) {
  return {
    apariencias: c.apariencias,
    clases: c.clases.map((inicial) => ({ ...inicial, clase: claseJson(inicial.clase) })),
  };
}
