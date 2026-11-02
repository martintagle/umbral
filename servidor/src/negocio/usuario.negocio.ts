import { randomBytes, randomInt } from 'node:crypto';

import bcrypt from 'bcryptjs';
import { OAuth2Client } from 'google-auth-library';
import { ObjectId } from 'mongodb';

import type { AjustesDto } from '../dto/ajustes.dto.js';
import type { RolUsuario } from '../dto/rol-usuario.js';
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
export type UsuarioPublico = Omit<UsuarioDto, '_id' | 'passwordHash' | 'rol'> & {
  id: string;
  rol: RolUsuario;
};

function publico(u: UsuarioDto): UsuarioPublico {
  return {
    id: u._id.toHexString(),
    username: u.username,
    email: u.email,
    estado: u.estado,
    rol: u.rol ?? 'jugador',
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
  if (email.length > 254 || !EMAIL.test(email) || /['"`;\\]/.test(email)) {
    throw new NegocioError('El correo no es válido.');
  }
  // bcrypt solo usa los primeros 72 bytes de la contraseña.
  if (password.length < 8 || password.length > 72) {
    throw new NegocioError('La contraseña debe tener entre 8 y 72 caracteres.');
  }
}

/** Si [valor] tiene la forma de un username o de un correo. */
function esIdentificador(valor: string): boolean {
  return USERNAME.test(valor) || (valor.length <= 254 && EMAIL.test(valor) && !/['"`;\\]/.test(valor));
}

/** Comprueba la contraseña y el estado de la cuenta. */
async function comprobarAcceso(usuario: UsuarioDto | null, password: string): Promise<UsuarioDto> {
  const valida = usuario !== null && (await bcrypt.compare(password, usuario.passwordHash));
  // Mismo mensaje en ambos casos para no revelar qué cuentas existen.
  if (!usuario || !valida) {
    throw new NegocioError('Usuario o contraseña incorrectos.', 'autenticacion');
  }
  return estadoValido(usuario);
}

/** Rechaza las cuentas baneadas o eliminadas. */
function estadoValido(usuario: UsuarioDto): UsuarioDto {
  if (usuario.estado === 'baneado') {
    throw new NegocioError('La cuenta está baneada.', 'prohibido');
  }
  if (usuario.estado === 'eliminado') {
    throw new NegocioError('La cuenta está eliminada.', 'prohibido');
  }
  return usuario;
}

const noExiste = () => new NegocioError('El usuario no existe.', 'no-encontrado');

const google = new OAuth2Client();

/**
 * Comprueba con Google que [idToken] es suyo, está vigente y se emitió para
 * esta app (`GOOGLE_CLIENT_ID`, varios separados por comas), y devuelve su
 * correo verificado en minúsculas.
 */
async function correoDeGoogle(idToken: string): Promise<string> {
  const audience = (process.env.GOOGLE_CLIENT_ID ?? '')
    .split(',')
    .map((id) => id.trim())
    .filter(Boolean);
  if (audience.length === 0) {
    throw new NegocioError('El inicio con Google no está configurado en el servidor.', 'prohibido');
  }
  let correo: string | undefined;
  try {
    const datos = (await google.verifyIdToken({ idToken, audience })).getPayload();
    if (datos?.email_verified) correo = datos.email?.trim().toLowerCase();
  } catch {
    // Firma, emisor, audiencia o caducidad no válidos.
  }
  if (!correo || correo.length > 254 || !EMAIL.test(correo)) {
    throw new NegocioError('Google no confirmó tu cuenta. Vuelve a intentarlo.', 'autenticacion');
  }
  return correo;
}

/**
 * Usuario nuevo para el correo de Google. El username sale del correo; en
 * cada [intento] tras el primero lleva un número al azar.
 */
async function nuevoDeGoogle(correo: string, intento: number, ahora: Date): Promise<UsuarioDto> {
  let base = (correo.split('@')[0] ?? '').replace(/[^A-Za-z0-9_.-]/g, '').slice(0, 15);
  if (base.length < 3) base = `${base}jugador`.slice(0, 15);
  const username = intento === 0 ? base : `${base}${randomInt(1000, 100000)}`;
  return {
    _id: new ObjectId(),
    username,
    email: correo,
    passwordHash: await bcrypt.hash(randomBytes(32).toString('base64'), RONDAS_BCRYPT),
    estado: 'activo',
    rol: 'jugador',
    creadoEn: ahora,
    ultimoLogin: ahora,
    actualizadoEn: ahora,
    versionEsquema: VERSION_ESQUEMA,
    ajustes: AJUSTES_POR_DEFECTO,
    partidaActiva: null,
    partidas: [],
  };
}

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
      rol: 'jugador',
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
    // Solo llega a la consulta lo que puede ser un username o un correo: un
    // intento de inyección (comillas, `OR 1=1`, `--`...) no pasa de aquí.
    if (!esIdentificador(valor)) {
      throw new NegocioError('Usuario o contraseña incorrectos.', 'autenticacion');
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

  /**
   * Entra con la cuenta de Google del teléfono. [idToken] lo firma Google y
   * se comprueba aquí: si su correo ya tiene cuenta, se entra en ella; si
   * no, se crea una con un username sacado del correo y una contraseña al
   * azar que nadie conoce.
   */
  async iniciarConGoogle(idToken: string): Promise<UsuarioPublico> {
    const correo = await correoDeGoogle(idToken);
    const ahora = new Date();
    return sincronizacion.conRespaldo(
      async () => {
        const coleccion = await usuarios();
        const documento = await coleccion.findOne({ email: correo });
        if (documento) {
          const usuario = estadoValido(usuarioDto(documento));
          await coleccion.updateOne(
            { _id: usuario._id },
            { $set: { ultimoLogin: ahora, actualizadoEn: ahora } },
          );
          const actualizado = { ...usuario, ultimoLogin: ahora, actualizadoEn: ahora };
          respaldoLocal.guardarDeMongo(actualizado);
          return publico(actualizado);
        }
        for (let intento = 0; ; intento++) {
          const usuario = await nuevoDeGoogle(correo, intento, ahora);
          try {
            await conErroresMongo(() => coleccion.insertOne(documentoUsuario(usuario)));
            respaldoLocal.guardarDeMongo(usuario);
            return publico(usuario);
          } catch (e) {
            // El username sacado del correo ya lo tiene otro: se prueba con un número.
            if (!(e instanceof NegocioError && e.tipo === 'conflicto') || intento >= 5) throw e;
          }
        }
      },
      async () => {
        const local = respaldoLocal.usuarioPorIdentificador(correo);
        if (local) {
          const actualizado = { ...estadoValido(local), ultimoLogin: ahora, actualizadoEn: ahora };
          respaldoLocal.guardarCambio(actualizado);
          return publico(actualizado);
        }
        for (let intento = 0; ; intento++) {
          const usuario = await nuevoDeGoogle(correo, intento, ahora);
          try {
            respaldoLocal.guardarCambio(usuario);
            return publico(usuario);
          } catch (e) {
            if (!(e instanceof NegocioError && e.tipo === 'conflicto') || intento >= 5) throw e;
          }
        }
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

  /**
   * Crea la cuenta, o toma la que ya existe con ese username y contraseña, y
   * le da el rol `admin`: en el juego no recibe daño, no gasta estamina y pega
   * más fuerte, para recorrerlo entero al probarlo. Solo lo usa
   * `dev/crear-admin.ts`; la API no permite pedirlo.
   */
  async crearAdmin(username: string, email: string, password: string): Promise<UsuarioPublico> {
    let usuario: UsuarioPublico;
    try {
      usuario = await this.registrar(username, email, password);
    } catch (e) {
      if (!(e instanceof NegocioError && e.tipo === 'conflicto')) throw e;
      usuario = await this.iniciarSesion(username, password);
    }
    const { id } = usuario;
    const ahora = new Date();
    await sincronizacion.conRespaldo(
      async () => {
        const coleccion = await usuarios();
        await coleccion.updateOne(
          { _id: idMongo(id) },
          { $set: { rol: 'admin', actualizadoEn: ahora } },
        );
      },
      () => respaldoLocal.guardarCambio({ ...usuarioLocal(id), rol: 'admin', actualizadoEn: ahora }),
      id,
    );
    return { ...usuario, rol: 'admin', actualizadoEn: ahora };
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
