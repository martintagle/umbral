import type { MundoDto } from '../dto/mundo.dto.js';
import { NegocioError } from './negocio-error.js';

/**
 * Cofres de los mapas (`assets/mapas/*.json`), como `zonaId/cofreId`, con el
 * oro que dan. Los demás cofres traen llaves u objetos que el juego aún no
 * guarda: solo se anota que se abrieron.
 */
const COFRES: Record<string, number> = {
  'tierras-del-umbral/cofre-hoz': 0,
  'tierras-del-umbral/cofre-llave': 0,
  'tierras-del-umbral/cofre-torre': 0,
  'tierras-del-umbral/cofre-cementerio': 50,
  'cienaga/cofre-llave': 0,
  'cienaga/cofre-secreto-cunas': 0,
  'cienaga/cofre-bosque': 0,
  'cienaga/cofre-sur': 200,
  'cienaga/cofre-este': 0,
  'minas/cofre-llave': 0,
  'minas/cofre-secreto-lago': 0,
  'minas/cofre-galeria': 0,
  'minas/cofre-orilla': 300,
  'minas/cofre-bocamina': 0,
  'abadia/cofre-llave': 0,
  'abadia/cofre-secreto-atrio': 0,
  'abadia/cofre-sala-norte': 0,
  'abadia/cofre-claustro': 400,
  'abadia/cofre-cementerio': 0,
  'paramo/cofre-llave': 0,
  'paramo/cofre-secreto-charca': 0,
  'paramo/cofre-campamento': 0,
  'paramo/cofre-trinchera': 500,
  'paramo/cofre-sureste': 0,
  'umbral/cofre-llave': 0,
  'umbral/cofre-secreto-islote': 0,
  'umbral/cofre-puentes': 0,
  'umbral/cofre-sur': 600,
  'umbral/cofre-isla-central': 0,
};

/** Al vencer a cada custodio se abre el paso a la zona siguiente. */
const ZONA_TRAS_JEFE: Record<string, string> = {
  'jefe-rey-hueco': 'cienaga',
  'jefe-madre-cirio': 'minas',
  'jefe-capataz-de-sal': 'abadia',
  'jefe-abadesa': 'paramo',
  'jefe-caballero-de-ceniza': 'umbral',
};

/** Reglas del mundo de una partida: cofres y zonas. No accede a la base de datos. */
export const mundoNegocio = {
  /**
   * Anota los [cofres] recién abiertos y los [jefes] vencidos. Un cofre solo
   * se abre una vez: los que ya estaban abiertos no vuelven a dar oro.
   */
  aplicar(
    mundo: MundoDto,
    cofres: string[],
    jefes: string[],
  ): { mundo: MundoDto; oro: number } {
    const abiertos = new Set(mundo.cofresAbiertos);
    let oro = 0;
    for (const id of new Set(cofres)) {
      if (!Object.hasOwn(COFRES, id)) throw new NegocioError(`El cofre "${id}" no existe.`);
      if (abiertos.has(id)) continue;
      abiertos.add(id);
      oro += COFRES[id] ?? 0;
    }
    const vencidos = [...new Set([...mundo.jefesDerrotados, ...jefes])];
    const zonas = new Set(mundo.zonasDesbloqueadas);
    for (const jefe of vencidos) {
      if (ZONA_TRAS_JEFE[jefe]) zonas.add(ZONA_TRAS_JEFE[jefe]);
    }
    return {
      mundo: {
        zonasDesbloqueadas: [...zonas],
        cofresAbiertos: [...abiertos],
        jefesDerrotados: vencidos,
      },
      oro,
    };
  },
};
