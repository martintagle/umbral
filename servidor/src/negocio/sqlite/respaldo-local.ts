import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { DatabaseSync } from 'node:sqlite';

import { ObjectId } from 'mongodb';

import type { ClaseDto } from '../../dto/clase.dto.js';
import type { UsuarioDto } from '../../dto/usuario.dto.js';
import { NegocioError } from '../negocio-error.js';

/** Usuario guardado en SQLite, con la versión de su último cambio local. */
export interface UsuarioLocal {
  usuario: UsuarioDto;
  version: number;
}

let bd: DatabaseSync | null = null;

function base(): DatabaseSync {
  if (!bd) throw new Error('La copia local no está abierta: llama a respaldoLocal.abrir() al arrancar.');
  return bd;
}

/** El documento en JSON: `_id` en hexadecimal y las fechas en ISO 8601. */
function aTexto(u: UsuarioDto): string {
  return JSON.stringify({ ...u, _id: u._id.toHexString() });
}

function deTexto(texto: string): UsuarioDto {
  const d = JSON.parse(texto);
  return {
    ...d,
    _id: new ObjectId(d._id as string),
    creadoEn: new Date(d.creadoEn),
    ultimoLogin: d.ultimoLogin === null ? null : new Date(d.ultimoLogin),
    actualizadoEn: new Date(d.actualizadoEn),
    partidas: (d.partidas as UsuarioDto['partidas']).map((p) => ({
      ...p,
      creadaEn: new Date(p.creadaEn),
      ultimaVezJugada: new Date(p.ultimaVezJugada),
    })),
  };
}

/** Traduce el choque con los índices únicos, como hace Mongo con el 11000. */
function conUnicos<T>(operacion: () => T): T {
  try {
    return operacion();
  } catch (e) {
    const mensaje = (e as Error).message ?? '';
    if (mensaje.includes('UNIQUE constraint failed: usuarios.email')) {
      throw new NegocioError('El correo ya está registrado.', 'conflicto');
    }
    if (mensaje.includes('UNIQUE constraint failed: usuarios.username')) {
      throw new NegocioError('El nombre de usuario ya está en uso.', 'conflicto');
    }
    throw e;
  }
}

/**
 * Copia de la base en SQLite, para seguir funcionando cuando MongoDB Atlas no
 * responde. Guarda cada documento de `usuarios` (con sus partidas) y de
 * `clases`. Los cambios hechos sin Atlas quedan marcados como pendientes con
 * una versión, y `sincronizacion` los envía a Mongo cuando vuelve.
 *
 * El archivo es `SQLITE_RUTA` (por defecto `datos/umbral.sqlite`).
 */
export const respaldoLocal = {
  abrir(ruta = process.env.SQLITE_RUTA ?? 'datos/umbral.sqlite'): void {
    if (bd) return;
    if (ruta !== ':memory:') mkdirSync(dirname(ruta), { recursive: true });
    bd = new DatabaseSync(ruta);
    bd.exec(`
      CREATE TABLE IF NOT EXISTS usuarios (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        documento TEXT NOT NULL,
        -- 0 si coincide con Mongo; si no, sube con cada cambio local.
        version INTEGER NOT NULL DEFAULT 0
      );
      CREATE TABLE IF NOT EXISTS usuarios_eliminados (id TEXT PRIMARY KEY);
      CREATE TABLE IF NOT EXISTS clases (id TEXT PRIMARY KEY, documento TEXT NOT NULL);
    `);
  },

  cerrar(): void {
    bd?.close();
    bd = null;
  },

  usuario(id: string): UsuarioDto | null {
    const fila = base().prepare('SELECT documento FROM usuarios WHERE id = ?').get(id);
    return fila ? deTexto(fila.documento as string) : null;
  },

  /** Por correo (en minúsculas) o por username, como el login. */
  usuarioPorIdentificador(valor: string): UsuarioDto | null {
    const fila = base()
      .prepare('SELECT documento FROM usuarios WHERE email = ? OR username = ?')
      .get(valor.toLowerCase(), valor);
    return fila ? deTexto(fila.documento as string) : null;
  },

  /** Un cambio hecho sin Atlas: queda pendiente de enviar. */
  guardarCambio(u: UsuarioDto): void {
    const id = u._id.toHexString();
    conUnicos(() =>
      base()
        .prepare(
          `INSERT INTO usuarios (id, username, email, documento, version) VALUES (?, ?, ?, ?, 1)
           ON CONFLICT(id) DO UPDATE SET username = excluded.username, email = excluded.email,
             documento = excluded.documento, version = usuarios.version + 1`,
        )
        .run(id, u.username, u.email, aTexto(u)),
    );
    base().prepare('DELETE FROM usuarios_eliminados WHERE id = ?').run(id);
  },

  /**
   * La versión de Mongo de un usuario. No pisa un cambio local pendiente:
   * ese manda hasta que llegue a Mongo.
   */
  guardarDeMongo(u: UsuarioDto): void {
    base()
      .prepare(
        `INSERT INTO usuarios (id, username, email, documento, version) VALUES (?, ?, ?, ?, 0)
         ON CONFLICT(id) DO UPDATE SET username = excluded.username, email = excluded.email,
           documento = excluded.documento
         WHERE usuarios.version = 0`,
      )
      .run(u._id.toHexString(), u.username, u.email, aTexto(u));
  },

  /** Quita una cuenta. Si fue sin Atlas, se anota para borrarla también allí. */
  eliminarUsuario(id: string, pendiente: boolean): void {
    base().prepare('DELETE FROM usuarios WHERE id = ?').run(id);
    if (pendiente) {
      base().prepare('INSERT OR IGNORE INTO usuarios_eliminados (id) VALUES (?)').run(id);
    }
  },

  /** Quita de la copia las cuentas que ya no están en Mongo (sin cambios pendientes). */
  conservarSolo(ids: Set<string>): void {
    const filas = base().prepare('SELECT id FROM usuarios WHERE version = 0').all();
    for (const { id } of filas) {
      if (!ids.has(id as string)) this.eliminarUsuario(id as string, false);
    }
  },

  usuariosPendientes(): UsuarioLocal[] {
    return base()
      .prepare('SELECT documento, version FROM usuarios WHERE version > 0')
      .all()
      .map((f) => ({ usuario: deTexto(f.documento as string), version: f.version as number }));
  },

  eliminacionesPendientes(): string[] {
    return base()
      .prepare('SELECT id FROM usuarios_eliminados')
      .all()
      .map((f) => f.id as string);
  },

  hayPendientes(): boolean {
    const fila = base()
      .prepare(
        `SELECT (SELECT COUNT(*) FROM usuarios WHERE version > 0)
              + (SELECT COUNT(*) FROM usuarios_eliminados) AS total`,
      )
      .get();
    return Number(fila?.total) > 0;
  },

  /** El cambio llegó a Mongo, salvo que haya otro más nuevo después. */
  marcarEnviado(id: string, version: number): void {
    base().prepare('UPDATE usuarios SET version = 0 WHERE id = ? AND version = ?').run(id, version);
  },

  marcarEliminado(id: string): void {
    base().prepare('DELETE FROM usuarios_eliminados WHERE id = ?').run(id);
  },

  guardarClases(clases: ClaseDto[]): void {
    const insertar = base().prepare(
      'INSERT INTO clases (id, documento) VALUES (?, ?) ON CONFLICT(id) DO UPDATE SET documento = excluded.documento',
    );
    for (const c of clases) insertar.run(c._id, JSON.stringify(c));
  },

  clases(): ClaseDto[] {
    return base()
      .prepare('SELECT documento FROM clases')
      .all()
      .map((f) => JSON.parse(f.documento as string) as ClaseDto);
  },
};
