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

/**
 * Cada criatura con su categoría y la zona de la que es propia
 * (`docs/guion.md`). Las de una zona vuelven en la siguiente como las más
 * débiles, pero dan lo mismo que en la suya.
 */
const ENEMIGOS: Record<string, { categoria: Categoria; zona: number }> = {
  'ojo-errante': { categoria: 'debil', zona: 1 },
  'polilla-osaria': { categoria: 'debil', zona: 1 },
  manojo: { categoria: 'media', zona: 1 },
  'ahorcado-fungico': { categoria: 'media', zona: 1 },
  fauce: { categoria: 'fuerte', zona: 1 },
  'larva-cirio': { categoria: 'fuerte', zona: 1 },
  enjambre: { categoria: 'media', zona: 2 },
  'sapo-lapida': { categoria: 'media', zona: 2 },
  'ahogado-de-cera': { categoria: 'fuerte', zona: 2 },
  'minero-hueco': { categoria: 'media', zona: 3 },
  'gusano-de-sal': { categoria: 'media', zona: 3 },
  'cristal-vivo': { categoria: 'fuerte', zona: 3 },
  'gargola-rota': { categoria: 'media', zona: 4 },
  'monja-sin-rostro': { categoria: 'media', zona: 4 },
  campanero: { categoria: 'fuerte', zona: 4 },
  'estandarte-poseido': { categoria: 'media', zona: 5 },
  'caballo-sin-jinete': { categoria: 'media', zona: 5 },
  'soldado-de-ceniza': { categoria: 'fuerte', zona: 5 },
  'boca-del-hueco': { categoria: 'media', zona: 6 },
  vigia: { categoria: 'media', zona: 6 },
  'sombra-sin-nombre': { categoria: 'fuerte', zona: 6 },
  // Los custodios. Una vez vencidos no vuelven: quedan en
  // `mundo.jefesDerrotados`.
  'jefe-rey-hueco': { categoria: 'jefe', zona: 1 },
  'jefe-madre-cirio': { categoria: 'jefe', zona: 2 },
  'jefe-capataz-de-sal': { categoria: 'jefe', zona: 3 },
  'jefe-abadesa': { categoria: 'jefe', zona: 4 },
  'jefe-caballero-de-ceniza': { categoria: 'jefe', zona: 5 },
  'jefe-el-que-mira': { categoria: 'jefe', zona: 6 },
};

/**
 * Cada zona da un 60 % más que la anterior: sus criaturas aguantan y pegan
 * más, y los niveles cuestan cada vez más experiencia.
 */
const FACTOR_POR_ZONA = 1.6;

function recompensa(id: string): Recompensa {
  const enemigo = ENEMIGOS[id];
  if (!enemigo) throw new NegocioError(`El enemigo "${id}" no existe.`);
  const factor = FACTOR_POR_ZONA ** (enemigo.zona - 1);
  const base = RANGOS[enemigo.categoria];
  return {
    id,
    categoria: enemigo.categoria,
    expMin: Math.round(base.expMin * factor),
    expMax: Math.round(base.expMax * factor),
    oroMin: Math.round(base.oroMin * factor),
    oroMax: Math.round(base.oroMax * factor),
  };
}

/** Reglas de las criaturas: su categoría y qué puede dar cada una. No accede a la base de datos. */
export const enemigoNegocio = {
  catalogo(): Recompensa[] {
    return Object.keys(ENEMIGOS).map(recompensa);
  },

  /** Jefes entre los enemigos derrotados, indicados como `{ id: cantidad }`. */
  jefesEn(derrotados: Record<string, number>): string[] {
    return Object.entries(derrotados)
      .filter(([id, n]) => n > 0 && ENEMIGOS[id]?.categoria === 'jefe')
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
