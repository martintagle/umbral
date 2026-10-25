import { Double } from 'mongodb';

import { conexionBD } from '../conexion/conexion-bd.js';
import type { AjustesDto } from '../dto/ajustes.dto.js';
import type { UsuarioDto } from '../dto/usuario.dto.js';

const COLECCION = 'usuarios';

/**
 * Forma en que se escriben los ajustes. El esquema exige `double` y JavaScript
 * guardaría 1.0 como entero, así que se envuelven en Double.
 */
interface AjustesDocumento {
  idioma: string;
  musica: Double;
  efectos: Double;
}

/** Documento tal como está en la colección. */
export type UsuarioDocumento = Omit<UsuarioDto, 'ajustes'> & { ajustes: AjustesDocumento };

export const usuarios = () => conexionBD.coleccion<UsuarioDocumento>(COLECCION);

export function ajustesDocumento(a: AjustesDto): AjustesDocumento {
  return { idioma: a.idioma, musica: new Double(a.musica), efectos: new Double(a.efectos) };
}

export function documentoUsuario(u: UsuarioDto): UsuarioDocumento {
  return { ...u, ajustes: ajustesDocumento(u.ajustes) };
}

/** `Number()` acepta tanto el Double como el number que devuelve el driver. */
export function usuarioDto(d: UsuarioDocumento): UsuarioDto {
  const { idioma, musica, efectos } = d.ajustes;
  return { ...d, ajustes: { idioma, musica: Number(musica), efectos: Number(efectos) } };
}
