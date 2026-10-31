import 'dotenv/config';

import { conexionBD, SinConexionBD } from './conexion/conexion-bd.js';
import { claseNegocio } from './negocio/clase.negocio.js';
import { respaldoLocal } from './negocio/sqlite/respaldo-local.js';
import { sincronizacion } from './negocio/sqlite/sincronizacion.js';
import { crearApp } from './servicio/app.js';

const puerto = Number(process.env.PUERTO ?? process.env.PORT ?? 3000);

for (const variable of ['MONGO_URI', 'JWT_SECRETO']) {
  if (!process.env[variable]) {
    console.error(`Falta ${variable}. Copia .env.ejemplo como .env y rellénalo.`);
    process.exit(1);
  }
}
// Con una clave corta, cualquiera podría adivinarla y fabricar sesiones de otros usuarios.
if (process.env.JWT_SECRETO!.length < 32) {
  console.error('JWT_SECRETO debe tener al menos 32 caracteres. Genera uno como indica .env.ejemplo.');
  process.exit(1);
}

// La copia SQLite con la que negocio sigue funcionando si Atlas no responde.
respaldoLocal.abrir();
// Conecta al arrancar para detectar enseguida una cadena mal puesta. Si Atlas
// no responde, se arranca igual con la copia local.
try {
  await conexionBD.abrir();
} catch (e) {
  if (!(e instanceof SinConexionBD)) throw e;
  console.warn(e.message);
}
// Las clases no cambian: se leen una vez y se sirven desde memoria.
await claseNegocio.cargar();
// Envía a Mongo lo hecho sin conexión y copia la base en SQLite.
await sincronizacion.iniciar();

const servidor = crearApp().listen(puerto, '0.0.0.0', () => {
  console.log(`API de Umbral escuchando en http://localhost:${puerto}`);
});

// El hosting manda SIGTERM al redesplegar: termina las peticiones y cierra Atlas.
process.on('SIGTERM', () => {
  servidor.close(() => {
    sincronizacion.detener();
    respaldoLocal.cerrar();
    void conexionBD.cerrar().finally(() => process.exit(0));
  });
});
