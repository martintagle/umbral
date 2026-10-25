import 'dotenv/config';

import { conexionBD } from './conexion/conexion-bd.js';
import { crearApp } from './servicio/app.js';

const puerto = Number(process.env.PUERTO ?? 3000);

for (const variable of ['MONGO_URI', 'JWT_SECRETO']) {
  if (!process.env[variable]) {
    console.error(`Falta ${variable}. Copia .env.ejemplo como .env y rellénalo.`);
    process.exit(1);
  }
}

// Conecta al arrancar para detectar enseguida una cadena o credenciales mal puestas.
await conexionBD.abrir();

crearApp().listen(puerto, '0.0.0.0', () => {
  console.log(`API de Umbral escuchando en http://localhost:${puerto}`);
});
