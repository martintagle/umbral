import bcrypt from 'bcryptjs';
import { ObjectId } from 'mongodb';

import type { AjustesDto } from '../dto/ajustes.dto.js';
import type { UsuarioDto } from '../dto/usuario.dto.js';
import { ajustesDocumento, documentoUsuario, usuarioDto, usuarios } from './coleccion-usuarios.js';
import { conErroresMongo, idMongo, NegocioError } from './negocio-error.js';
import { respaldoLocal } from './sqlite/respaldo-local.js';
import { sincronizacion } from './sqlite/sincronizacion.js';

export const VERSION_ESQUEMA = 1;
const AJUSTES_POR_DEFECTO: AjustesDto = { idioma: 'es', musica: 1, efectos: 1 };
const RONDAS_BCRYPT = 10;
const USERNAME = /^[A-Za-z0-9_.-]{3,20}$/;
const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/** Usuario tal como lo entrega negocio: sin `passwordHash` y con `_id` como `id` en texto. */
export type UsuarioPublico = Omit<UsuarioDto, '_id' | 'passwordHash'> & { id: string };

function publico(u: UsuarioDto): UsuarioPublico {
  return {
    id: u._id.toHexString(),
    username: u.username,
    email: u.email,
    estado: u.estado,
    creadoEn: u.creadoEn,
    ultimoLogin: u.ultimoLogin,
    actualizadoEn: u.actualizadoEn,
    versionEsquema: u.versionEsquema,
    ajustes: u.ajustes,
    partidaActiva: u.partidaActiva,
    partidas: u.partidas,
  };
}

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

/** Comprueba la contraseña y el estado de la cuenta. */
async function comprobarAcceso(usuario: UsuarioDto | null, password: string): Promise<UsuarioDto> {
  const valida = usuario !== null && (await bcrypt.compare(password, usuario.passwordHash));
  // Mismo mensaje en ambos casos para no revelar qué cuentas existen.
  if (!usuario || !valida) {
    throw new NegocioError('Usuario o contraseña incorrectos.', 'autenticacion');
  }
  if (usuario.estado === 'baneado') {
    throw new NegocioError('La cuenta está baneada.', 'prohibido');
  }
  if (usuario.estado === 'eliminado') {
    throw new NegocioError('La cuenta está eliminada.', 'prohibido');
  }
  return usuario;
}

const noExiste = () => new NegocioError('El usuario no existe.', 'no-encontrado');

/** Usuario de la copia local; sin Atlas, es la única fuente. */
function usuarioLocal(id: string): UsuarioDto {
  idMongo(id);
  const usuario = respaldoLocal.usuario(id);
  if (!usuario) throw noExiste();
  return usuario;
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
  async registrar(username: string, email: string, password: string): Promise<UsuarioPublico> {
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
    return sincronizacion.conRespaldo(
      async () => {
        const coleccion = await usuarios();
        await conErroresMongo(() => coleccion.insertOne(documentoUsuario(usuario)));
        return publico(usuario);
      },
      () => {
        respaldoLocal.guardarCambio(usuario);
        return publico(usuario);
      },
      usuario._id.toHexString(),
    );
  },

  /** `identificador` puede ser el email o el username. */
  async iniciarSesion(identificador: string, password: string): Promise<UsuarioPublico> {
    const valor = identificador.trim();
    if (!valor || !password) {
      throw new NegocioError('Escribe tu correo o usuario y tu contraseña.');
    }
    const ahora = new Date();
    return sincronizacion.conRespaldo(
      async () => {
        const coleccion = await usuarios();
        const documento = await coleccion.findOne({
          $or: [{ email: valor.toLowerCase() }, { username: valor }],
        });
        const usuario = await comprobarAcceso(documento && usuarioDto(documento), password);
        await coleccion.updateOne(
          { _id: usuario._id },
          { $set: { ultimoLogin: ahora, actualizadoEn: ahora } },
        );
        const actualizado = { ...usuario, ultimoLogin: ahora, actualizadoEn: ahora };
        respaldoLocal.guardarDeMongo(actualizado);
        return publico(actualizado);
      },
      async () => {
        const usuario = await comprobarAcceso(respaldoLocal.usuarioPorIdentificador(valor), password);
        const actualizado = { ...usuario, ultimoLogin: ahora, actualizadoEn: ahora };
        respaldoLocal.guardarCambio(actualizado);
        return publico(actualizado);
      },
    );
  },

  obtenerPorId(id: string): Promise<UsuarioPublico> {
    return sincronizacion.conRespaldo(
      async () => {
        const documento = await (await usuarios()).findOne({ _id: idMongo(id) });
        if (!documento) throw noExiste();
        const usuario = usuarioDto(documento);
        respaldoLocal.guardarDeMongo(usuario);
        return publico(usuario);
      },
      () => publico(usuarioLocal(id)),
    );
  },

  async actualizarAjustes(id: string, ajustes: AjustesDto): Promise<void> {
    validarAjustes(ajustes);
    const ahora = new Date();
    await sincronizacion.conRespaldo(
      async () => {
        const coleccion = await usuarios();
        const resultado = await conErroresMongo(() =>
          coleccion.updateOne(
            { _id: idMongo(id) },
            { $set: { ajustes: ajustesDocumento(ajustes), actualizadoEn: ahora } },
          ),
        );
        if (resultado.matchedCount === 0) throw noExiste();
      },
      () => respaldoLocal.guardarCambio({ ...usuarioLocal(id), ajustes, actualizadoEn: ahora }),
      id,
    );
  },

  /** Borra el documento del usuario, con todas sus partidas. */
  async eliminar(id: string): Promise<void> {
    await sincronizacion.conRespaldo(
      async () => {
        const resultado = await (await usuarios()).deleteOne({ _id: idMongo(id) });
        if (resultado.deletedCount === 0) throw noExiste();
        respaldoLocal.eliminarUsuario(id, false);
      },
      () => {
        usuarioLocal(id);
        respaldoLocal.eliminarUsuario(id, true);
      },
    );
  },
};
