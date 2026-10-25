import { rateLimit } from 'express-rate-limit';

/** Límite general por IP para toda la API. */
export const limiteGeneral = rateLimit({
  windowMs: 60_000,
  limit: 120,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { error: 'Demasiadas peticiones. Espera un momento e inténtalo de nuevo.' },
});

/**
 * Límite estricto para login y registro: frena ataques de fuerza bruta contra
 * contraseñas y la creación masiva de cuentas.
 */
export const limiteAcceso = rateLimit({
  windowMs: 15 * 60_000,
  limit: 10,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { error: 'Demasiados intentos. Vuelve a intentarlo en unos minutos.' },
});
