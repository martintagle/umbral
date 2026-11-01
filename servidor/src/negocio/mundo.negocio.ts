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
  // Guarda la astilla de nada: abrirlo es tenerla. No da oro.
  'umbral/cofre-secreto-astilla': 0,
};

/** Al vencer a cada custodio se abre el paso a la zona siguiente. */
const ZONA_TRAS_JEFE: Record<string, string> = {
  'jefe-rey-hueco': 'cienaga',
  'jefe-madre-cirio': 'minas',
  'jefe-capataz-de-sal': 'abadia',
  'jefe-abadesa': 'paramo',
  'jefe-caballero-de-ceniza': 'umbral',
};

/** Una fogata del mundo (`altar:<zona>:<n>`) o de una sala (`sala:<slug>`). */
const FOGATA = /^(altar:[a-z-]{1,40}:\d{1,2}|sala:[a-z0-9-]{1,58})$/;

/** Un punto de aparición: la zona o la sala y el número del punto. */
const PUNTO = /^[a-z0-9-]{1,60}#\d{1,3}$/;
const MAXIMO_PUNTOS = 500;

/** Un diálogo de Oreste: `oreste-<zona>-<orden>`. */
const DIALOGO = /^oreste-[1-6]-[1-9]$/;

/** Reglas del mundo de una partida: cofres, fogatas, diálogos y zonas. No accede a la base de datos. */
export const mundoNegocio = {
  /**
   * Anota los [cofres] recién abiertos, las [fogatas] encendidas y los
   * [jefes] vencidos. Un cofre solo se abre una vez: los que ya estaban
   * abiertos no vuelven a dar oro.
   */
  aplicar(
    mundo: MundoDto,
    cofres: string[],
    jefes: string[],
    fogatas: string[] = [],
    caidos?: Record<string, number>,
    dialogos: string[] = [],
  ): { mundo: MundoDto; oro: number } {
    for (const id of dialogos) {
      if (!DIALOGO.test(id)) throw new NegocioError(`El diálogo "${id}" no existe.`);
    }
    if (caidos) {
      const puntos = Object.keys(caidos);
      if (puntos.length > MAXIMO_PUNTOS || puntos.some((p) => !PUNTO.test(p))) {
        throw new NegocioError('Las criaturas caídas no son válidas.');
      }
    }
    for (const id of fogatas) {
      if (!FOGATA.test(id)) throw new NegocioError(`La fogata "${id}" no existe.`);
    }
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
        fogatasEncendidas: [...new Set([...(mundo.fogatasEncendidas ?? []), ...fogatas])],
        // Es el estado completo desde el último descanso: reemplaza al anterior.
        enemigosCaidos: caidos ?? mundo.enemigosCaidos ?? {},
        dialogosLeidos: [...new Set([...(mundo.dialogosLeidos ?? []), ...dialogos])],
      },
      oro,
    };
  },
};
