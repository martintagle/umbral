/**
 * Crea (o promueve) una cuenta de administrador para probar el juego:
 * npm run bd:admin -- <usuario> <correo> <contraseña>. Sin argumentos usa
 * admin / admin@umbral.dev / UmbralAdmin2026. Basta con un usuario readWrite.
 */
import 'dotenv/config';

import { conexionBD } from '../conexion/conexion-bd.js';
import { respaldoLocal } from '../negocio/sqlite/respaldo-local.js';
import { usuarioNegocio } from '../negocio/usuario.negocio.js';

const [username = 'admin', email = 'admin@umbral.dev', password = 'UmbralAdmin2026'] =
  process.argv.slice(2);

// Como al arrancar la API: si Atlas no responde, la cuenta queda en la copia
// local y se envía cuando vuelva.
respaldoLocal.abrir();
const admin = await usuarioNegocio.crearAdmin(username, email, password);
console.log(`Cuenta ${admin.username} (${admin.email}) con rol ${admin.rol}.`);
respaldoLocal.cerrar();
await conexionBD.cerrar();
