import type { ObjectId } from 'mongodb';

import type { AjustesDto } from './ajustes.dto.js';
import type { EstadoUsuario } from './estado-usuario.js';
import type { PartidaDto } from './partida.dto.js';
import type { RolUsuario } from './rol-usuario.js';

/**
 * Réplica de un documento de la colección `usuarios`, con sus subdocumentos
 * embebidos (ajustes y partidas).
 */
export interface UsuarioDto {
  _id: ObjectId;
  username: string;
  email: string;
  passwordHash: string;
  estado: EstadoUsuario;
  /** Ausente en las cuentas anteriores al campo: equivale a `jugador`. */
  rol?: RolUsuario;
  creadoEn: Date;
  ultimoLogin: Date | null;
  actualizadoEn: Date;
  versionEsquema: number;
  ajustes: AjustesDto;
  partidaActiva: string | null;
  partidas: PartidaDto[];
}
