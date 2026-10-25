import bcrypt from 'bcryptjs';
import { ObjectId } from 'mongodb';

import type { AjustesDto } from '../dto/ajustes.dto.js';
import type { UsuarioDto } from '../dto/usuario.dto.js';
import { ajustesDocumento, documentoUsuario, usuarioDto, usuarios } from './coleccion-usuarios.js';
import { conErroresMongo, idMongo, NegocioError } from './negocio-error.js';

export const VERSION_ESQUEMA = 1;
const AJUSTES_POR_DEFECTO: AjustesDto = { idioma: 'es', musica: 1, efectos: 1 };
const RONDAS_BCRYPT = 10;
const USERNAME = /^[A-Za-z0-9_.-]{3,20}$/;
const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/**
 * El username no admite '@': como el login acepta email o username en el
 * mismo campo, así nunca puede coincidir con el email de otra cuenta.
 */
function validarRegistro(username: string, email: string, password: string): void {
  if (!USERNAME.test(username)) {
    throw new NegocioError(
      'El nombre de usuario debe tener entre 3 y 20 caracteres: letras, números, punto, guion o guion bajo.',
    );
  }
  if (email.length > 254 || !EMAIL.test(email)) {
    throw new NegocioError('El correo no es válido.');
  }
  // bcrypt solo usa los primeros 72 bytes de la contraseña.
  if (password.length < 8 || password.length > 72) {
    throw new NegocioError('La contraseña debe tener entre 8 y 72 caracteres.');
  }
}

function validarAjustes(a: AjustesDto): void {
  if (a.idioma.length < 2 || a.idioma.length > 10) {
    throw new NegocioError('El idioma no es válido.');
  }
  for (const v of [a.musica, a.efectos]) {
    if (v < 0 || v > 1) throw new NegocioError('El volumen debe estar entre 0 y 1.');
  }
}

export const usuarioNegocio = {
  async registrar(username: string, email: string, password: string): Promise<UsuarioDto> {
    const nombre = username.trim();
    const correo = email.trim().toLowerCase();
    validarRegistro(nombre, correo, password);
    const ahora = new Date();
    const usuario: UsuarioDto = {
      _id: new ObjectId(),
      username: nombre,
      email: correo,
      passwordHash: await bcrypt.hash(password, RONDAS_BCRYPT),
      estado: 'activo',
      creadoEn: ahora,
      ultimoLogin: null,
      actualizadoEn: ahora,
      versionEsquema: VERSION_ESQUEMA,
      ajustes: AJUSTES_POR_DEFECTO,
      partidaActiva: null,
      partidas: [],
    };
    const coleccion = await usuarios();
    await conErroresMongo(() => coleccion.insertOne(documentoUsuario(usuario)));
    return usuario;
  },

  /** `identificador` puede ser el email o el username. */
  async iniciarSesion(identificador: string, password: string): Promise<UsuarioDto> {
    const valor = identificador.trim();
    if (!valor || !password) {
      throw new NegocioError('Escribe tu correo o usuario y tu contraseña.');
    }
    const coleccion = await usuarios();
    const documento = await coleccion.findOne({
      $or: [{ email: valor.toLowerCase() }, { username: valor }],
    });
    const valida = documento !== null && (await bcrypt.compare(password, documento.passwordHash));
    // Mismo mensaje en ambos casos para no revelar qué cuentas existen.
    if (!documento || !valida) {
      throw new NegocioError('Usuario o contraseña incorrectos.', 'autenticacion');
    }
    if (documento.estado === 'baneado') {
      throw new NegocioError('La cuenta está baneada.', 'prohibido');
    }
    if (documento.estado === 'eliminado') {
      throw new NegocioError('La cuenta está eliminada.', 'prohibido');
    }

    const ahora = new Date();
    await coleccion.updateOne(
      { _id: documento._id },
      { $set: { ultimoLogin: ahora, actualizadoEn: ahora } },
    );
    return usuarioDto({ ...documento, ultimoLogin: ahora, actualizadoEn: ahora });
  },

  async obtenerPorId(id: string): Promise<UsuarioDto> {
    const documento = await (await usuarios()).findOne({ _id: idMongo(id) });
    if (!documento) throw new NegocioError('El usuario no existe.', 'no-encontrado');
    return usuarioDto(documento);
  },

  async actualizarAjustes(id: string, ajustes: AjustesDto): Promise<void> {
    validarAjustes(ajustes);
    const coleccion = await usuarios();
    const resultado = await conErroresMongo(() =>
      coleccion.updateOne(
        { _id: idMongo(id) },
        { $set: { ajustes: ajustesDocumento(ajustes), actualizadoEn: new Date() } },
      ),
    );
    if (resultado.matchedCount === 0) {
      throw new NegocioError('El usuario no existe.', 'no-encontrado');
    }
  },

  /** Borra el documento del usuario, con todas sus partidas. */
  async eliminar(id: string): Promise<void> {
    const resultado = await (await usuarios()).deleteOne({ _id: idMongo(id) });
    if (resultado.deletedCount === 0) {
      throw new NegocioError('El usuario no existe.', 'no-encontrado');
    }
  },
};
