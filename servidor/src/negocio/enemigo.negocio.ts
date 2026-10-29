import { NegocioError } from './negocio-error.js';

/** Las criaturas débiles abundan en el mapa y dan poco; las fuertes escasean y dan más. */
export type Categoria = 'debil' | 'media' | 'fuerte' | 'jefe';

/**
 * Lo que puede dar una criatura al ser derrotada: cada derrota da una
 * cantidad al azar dentro de estos rangos, con los extremos incluidos.
 */
export interface Recompensa {
  id: string;
  categoria: Categoria;
  expMin: number;
  expMax: number;
  oroMin: number;
  oroMax: number;
}

type Rangos = Omit<Recompensa, 'id' | 'categoria'>;

const RANGOS: Record<Categoria, Rangos> = {
  debil: { expMin: 6, expMax: 10, oroMin: 2, oroMax: 4 },
  media: { expMin: 14, expMax: 22, oroMin: 5, oroMax: 9 },
  fuerte: { expMin: 28, expMax: 40, oroMin: 10, oroMax: 16 },
  jefe: { expMin: 360, expMax: 440, oroMin: 130, oroMax: 170 },
};

const CATEGORIAS: Record<string, Categoria> = {
  'ojo-errante': 'debil',
  'polilla-osaria': 'debil',
  manojo: 'media',
  'ahorcado-fungico': 'media',
  fauce: 'fuerte',
  'larva-cirio': 'fuerte',
  // Jefe de la sala del trono de la cripta. Una vez vencido no vuelve: queda
  // en `mundo.jefesDerrotados`.
  'jefe-rey-hueco': 'jefe',
};

function recompensa(id: string): Recompensa {
  const categoria = CATEGORIAS[id];
  if (!categoria) throw new NegocioError(`El enemigo "${id}" no existe.`);
  return { id, categoria, ...RANGOS[categoria] };
}

/** Reglas de las criaturas: su categoría y qué puede dar cada una. No accede a la base de datos. */
export const enemigoNegocio = {
  catalogo(): Recompensa[] {
    return Object.keys(CATEGORIAS).map(recompensa);
  },

  /** Jefes entre los enemigos derrotados, indicados como `{ id: cantidad }`. */
  jefesEn(derrotados: Record<string, number>): string[] {
    return Object.entries(derrotados)
      .filter(([id, n]) => n > 0 && CATEGORIAS[id] === 'jefe')
      .map(([id]) => id);
  },

  /**
   * Lo mínimo y lo máximo que pueden dar en total los enemigos derrotados,
   * indicados como `{ id: cantidad }`, y cuántos son.
   */
  rangoTotal(derrotados: Record<string, number>): Rangos & { enemigos: number } {
    const total = { expMin: 0, expMax: 0, oroMin: 0, oroMax: 0, enemigos: 0 };
    for (const [id, cantidad] of Object.entries(derrotados)) {
      const r = recompensa(id);
      total.expMin += r.expMin * cantidad;
      total.expMax += r.expMax * cantidad;
      total.oroMin += r.oroMin * cantidad;
      total.oroMax += r.oroMax * cantidad;
      total.enemigos += cantidad;
    }
    return total;
  },
};
