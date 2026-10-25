import { NegocioError } from './negocio-error.js';

/** Lo que da una criatura al ser derrotada. */
export interface Recompensa {
  id: string;
  exp: number;
  oro: number;
}

const RECOMPENSAS: Record<string, Omit<Recompensa, 'id'>> = {
  'ojo-errante': { exp: 8, oro: 3 },
  fauce: { exp: 18, oro: 6 },
  'polilla-osaria': { exp: 14, oro: 5 },
  'larva-cirio': { exp: 26, oro: 10 },
  manojo: { exp: 16, oro: 6 },
  'ahorcado-fungico': { exp: 20, oro: 8 },
  // Jefe de la sala del trono de la cripta.
  'jefe-rey-hueco': { exp: 400, oro: 150 },
};

/** Reglas de las criaturas: qué da cada una al ser derrotada. No accede a la base de datos. */
export const enemigoNegocio = {
  catalogo(): Recompensa[] {
    return Object.entries(RECOMPENSAS).map(([id, r]) => ({ id, ...r }));
  },

  /** Suma lo que dan los enemigos derrotados, indicados como `{ id: cantidad }`. */
  recompensaTotal(derrotados: Record<string, number>): { exp: number; oro: number; enemigos: number } {
    const total = { exp: 0, oro: 0, enemigos: 0 };
    for (const [id, cantidad] of Object.entries(derrotados)) {
      const r = RECOMPENSAS[id];
      if (!r) throw new NegocioError(`El enemigo "${id}" no existe.`);
      total.exp += r.exp * cantidad;
      total.oro += r.oro * cantidad;
      total.enemigos += cantidad;
    }
    return total;
  },
};
