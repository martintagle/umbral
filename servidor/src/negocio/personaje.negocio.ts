import type { AtributosDto } from '../dto/atributos.dto.js';
import type { ClaseCodigo } from '../dto/clase-codigo.js';
import type { ClaseDto } from '../dto/clase.dto.js';
import { APARIENCIAS, type Apariencia, type PersonajeDto } from '../dto/personaje.dto.js';
import type { UbicacionDto } from '../dto/ubicacion.dto.js';
import { enemigoNegocio } from './enemigo.negocio.js';
import { NegocioError } from './negocio-error.js';

/** Lo que cuesta subir un nivel una pieza de equipo y lo que da. */
export interface Mejora {
  costo: number;
  /** Daño (arma) o defensa (armadura) con el nivel siguiente. */
  valorSiguiente: number;
}

/** Valores de combate de un personaje, calculados con las reglas del juego. */
export interface Combate {
  vidaMaxima: number;
  /** Experiencia que cuesta el siguiente nivel (`costoNiveles[0]`). */
  expSiguiente: number;
  /**
   * Experiencia que cuesta cada uno de los próximos niveles, en orden: con
   * esto la app muestra cuánto costará subir varios puntos de una vez.
   */
  costoNiveles: number[];
  dano: number;
  defensa: number;
  probabilidadCritico: number;
  multiplicadorCritico: number;
  /** `null` si la pieza ya está al nivel máximo. */
  mejoraArma: Mejora | null;
  mejoraArmadura: Mejora | null;
}

export type PiezaEquipo = 'arma' | 'armadura';

/** Una clase de la colección con lo que tendría un personaje nuevo de esa clase. */
export interface ClaseInicial {
  clase: ClaseDto;
  /** Nivel con el que empieza: depende de sus atributos base. */
  nivel: number;
  oroInicial: number;
  combate: Combate;
}

export interface CatalogoClases {
  apariencias: readonly Apariencia[];
  clases: ClaseInicial[];
}

/**
 * Lo que ha pasado en la partida desde el último guardado. La app envía los
 * hechos y aquí se calculan la experiencia y el oro ganados.
 */
export interface Progreso {
  /** Enemigos derrotados de cada tipo: `{ id: cantidad }`. */
  enemigosDerrotados: Record<string, number>;
  muertes: number;
  segundosJugados: number;
  vidaActual: number;
  ubicacion: UbicacionDto;
}

/**
 * Reglas de cada clase que no están en la colección `clases`. Los atributos
 * base sí están allí: como en Elden Ring, cada atributo parte en 1 y cada
 * punto por encima es un nivel, así que las clases empiezan en nivel 10 (9
 * puntos repartidos según su estilo) y el prisionero, con todo al 1, en nivel 1.
 */
interface ClaseReglas {
  oroInicial: number;
  armaduraInicial: number;
  /** Atributo con el que escala el daño del arma de la clase. */
  atributoAtaque: 'fuerza' | 'destreza' | 'inteligencia';
}

const CLASES: Record<ClaseCodigo, ClaseReglas> = {
  vagabundo: {
    oroInicial: 30,
    armaduraInicial: 1,
    atributoAtaque: 'destreza',
  },
  guerrero: {
    oroInicial: 20,
    armaduraInicial: 2,
    atributoAtaque: 'fuerza',
  },
  arquero: {
    oroInicial: 40,
    armaduraInicial: 1,
    atributoAtaque: 'destreza',
  },
  mago: {
    oroInicial: 40,
    armaduraInicial: 0,
    atributoAtaque: 'inteligencia',
  },
  // Clase de desafío: sin armadura y sin oro.
  prisionero: {
    oroInicial: 0,
    armaduraInicial: 0,
    atributoAtaque: 'destreza',
  },
};

const ZONA_INICIAL = 'claro-de-las-lapidas';
const VIDA_BASE = 80;
const VIDA_POR_PUNTO = 12;
const DANO_BASE = 6;
const DANO_POR_PUNTO = 2;
const DANO_POR_NIVEL_ARMA = 3;
const DEFENSA_POR_ARMADURA = 2;
const CRITICO_BASE = 0.05;
const CRITICO_POR_DESTREZA = 0.008;
const MULTIPLICADOR_CRITICO = 1.5;
/** La curva de Elden Ring se divide por esto: aquí los enemigos dan menos. */
const DIVISOR_COSTO_NIVEL = 10;
const NIVELES_EN_CATALOGO = 30;
const ESTAMINA_MAXIMA = 100;
const ATRIBUTO_MINIMO = 1;
const ATRIBUTO_MAXIMO = 50;
const NIVEL_MAXIMO_EQUIPO = 10;
/** Holgura para el redondeo de los segundos que envía la app. */
const MARGEN_SEGUNDOS = 5;
/** Ritmo máximo creíble de enemigos derrotados. */
const MAXIMO_ENEMIGOS_POR_SEGUNDO = 1;

/** Nivel que corresponde a unos atributos: 1 más cada punto por encima de 1. */
function nivelDe(a: AtributosDto): number {
  return 1 + a.vida + a.fuerza + a.destreza + a.inteligencia - 4 * ATRIBUTO_MINIMO;
}

function vidaMaxima(atributos: AtributosDto): number {
  return VIDA_BASE + atributos.vida * VIDA_POR_PUNTO;
}

/**
 * Experiencia que cuesta pasar de [nivel] a [nivel] + 1. Es la fórmula de las
 * runas de Elden Ring dividida por [DIVISOR_COSTO_NIVEL]: casi plana los
 * primeros niveles y cada vez más cara a partir del 12. Siempre crece.
 */
function costoNivel(nivel: number): number {
  const x = Math.max((nivel + 81 - 92) * 0.02, 0);
  const runas = Math.floor((x + 0.1) * (nivel + 81) ** 2) + 1;
  return Math.max(1, Math.round(runas / DIVISOR_COSTO_NIVEL));
}

/** Lo que cuestan los [cantidad] niveles siguientes a [nivel], sumados. */
function costoNiveles(nivel: number, cantidad: number): number {
  let total = 0;
  for (let i = 0; i < cantidad; i++) total += costoNivel(nivel + i);
  return total;
}

/**
 * Oro para llevar una pieza al nivel [n] (`docs/diseno/interfaz/componentes.md`,
 * PantallaHerreria): cada mejora cuesta más que la anterior. Solo se paga con
 * oro: el juego no tiene materiales.
 */
function costoMejora(n: number): number {
  if (n >= NIVEL_MAXIMO_EQUIPO) return 2500;
  return (n <= 6 ? 150 : 200) * n;
}

type BaseCombate = Pick<PersonajeDto, 'claseCodigo' | 'nivel' | 'atributos' | 'equipo'>;

/** Como en Elden Ring, el nivel no da daño por sí solo: lo dan el atributo del arma y sus mejoras. */
function dano(p: BaseCombate, nivelArma: number): number {
  const ataque = p.atributos[CLASES[p.claseCodigo].atributoAtaque];
  return DANO_BASE + ataque * DANO_POR_PUNTO + nivelArma * DANO_POR_NIVEL_ARMA;
}

function mejora(nivel: number, valorSiguiente: number): Mejora | null {
  return nivel < NIVEL_MAXIMO_EQUIPO ? { costo: costoMejora(nivel + 1), valorSiguiente } : null;
}

function combate(p: BaseCombate): Combate {
  const a = p.atributos;
  const { nivelArma, nivelArmadura } = p.equipo;
  return {
    vidaMaxima: vidaMaxima(a),
    expSiguiente: costoNivel(p.nivel),
    costoNiveles: Array.from({ length: NIVELES_EN_CATALOGO }, (_, i) => costoNivel(p.nivel + i)),
    dano: dano(p, nivelArma),
    defensa: nivelArmadura * DEFENSA_POR_ARMADURA,
    probabilidadCritico: CRITICO_BASE + a.destreza * CRITICO_POR_DESTREZA,
    multiplicadorCritico: MULTIPLICADOR_CRITICO,
    mejoraArma: mejora(nivelArma, dano(p, nivelArma + 1)),
    mejoraArmadura: mejora(nivelArmadura, (nivelArmadura + 1) * DEFENSA_POR_ARMADURA),
  };
}

function validarNombre(nombre: string): string {
  const limpio = nombre.trim();
  if (limpio.length < 2 || limpio.length > 16) {
    throw new NegocioError('El nombre del personaje debe tener entre 2 y 16 caracteres.');
  }
  return limpio;
}

function validarApariencia(apariencia: string): Apariencia {
  const valida = APARIENCIAS.find((a) => a === apariencia);
  if (!valida) throw new NegocioError(`La apariencia "${apariencia}" no existe.`);
  return valida;
}

/** Reglas del personaje: clases, combate y progresión. No accede a la base de datos. */
export const personajeNegocio = {
  combate,

  /** [clases] son las de la colección, con lo que tendría un personaje nuevo de cada una. */
  catalogo(clases: ClaseDto[]): CatalogoClases {
    return {
      apariencias: APARIENCIAS,
      clases: clases.map((clase) => {
        const reglas = CLASES[clase._id];
        const nivel = nivelDe(clase.atributosBase);
        return {
          clase,
          nivel,
          oroInicial: reglas.oroInicial,
          combate: combate({
            claseCodigo: clase._id,
            nivel,
            atributos: clase.atributosBase,
            equipo: { nivelArma: 1, nivelArmadura: reglas.armaduraInicial },
          }),
        };
      }),
    };
  },

  /**
   * Personaje nuevo, con el nivel de su clase, en la entrada de la zona inicial
   * (0,0). Los atributos se copian de `clase.atributosBase`: a partir de aquí
   * evolucionan en el personaje y no se vuelven a leer de la colección.
   */
  personajeInicial(nombre: string, clase: ClaseDto, apariencia: string): PersonajeDto {
    const reglas = CLASES[clase._id];
    return {
      nombre: validarNombre(nombre),
      claseCodigo: clase._id,
      apariencia: validarApariencia(apariencia),
      nivel: nivelDe(clase.atributosBase),
      exp: 0,
      puntosLibres: 0,
      oro: reglas.oroInicial,
      atributos: { ...clase.atributosBase },
      vidaActual: vidaMaxima(clase.atributosBase),
      estaminaActual: ESTAMINA_MAXIMA,
      equipo: { nivelArma: 1, nivelArmadura: reglas.armaduraInicial },
      ubicacion: { zonaId: ZONA_INICIAL, x: 0, y: 0, ultimoPuntoGuardado: null },
      mundo: { zonasDesbloqueadas: [ZONA_INICIAL], cofresAbiertos: [], jefesDerrotados: [] },
      estadisticas: { enemigosDerrotados: 0, muertes: 0, tiempoJugadoSeg: 0 },
    };
  },

  /**
   * Suma lo ocurrido en la partida: experiencia y oro se acumulan para
   * gastarlos en el altar y en la herrería. No sube de nivel por sí solo.
   * [segundosDesdeGuardado] es el tiempo real desde el último guardado: el
   * progreso no puede abarcar más.
   */
  aplicarProgreso(p: PersonajeDto, progreso: Progreso, segundosDesdeGuardado: number): PersonajeDto {
    const maxima = vidaMaxima(p.atributos);
    if (progreso.vidaActual > maxima) {
      throw new NegocioError(`La vida no puede superar ${maxima}.`);
    }
    if (progreso.segundosJugados > segundosDesdeGuardado + MARGEN_SEGUNDOS) {
      throw new NegocioError('El tiempo jugado no puede superar el tiempo desde el último guardado.');
    }
    const ganado = enemigoNegocio.recompensaTotal(progreso.enemigosDerrotados);
    if (ganado.enemigos > progreso.segundosJugados * MAXIMO_ENEMIGOS_POR_SEGUNDO) {
      throw new NegocioError('Demasiados enemigos derrotados para el tiempo jugado.');
    }
    const e = p.estadisticas;
    return {
      ...p,
      exp: p.exp + ganado.exp,
      oro: p.oro + ganado.oro,
      vidaActual: progreso.vidaActual,
      ubicacion: progreso.ubicacion,
      mundo: {
        ...p.mundo,
        jefesDerrotados: [
          ...new Set([...p.mundo.jefesDerrotados, ...enemigoNegocio.jefesEn(progreso.enemigosDerrotados)]),
        ],
      },
      estadisticas: {
        enemigosDerrotados: e.enemigosDerrotados + ganado.enemigos,
        muertes: e.muertes + progreso.muertes,
        tiempoJugadoSeg: e.tiempoJugadoSeg + progreso.segundosJugados,
      },
    };
  },

  /**
   * Sube atributos gastando experiencia, como las runas de Elden Ring: cada
   * punto es un nivel y cada nivel cuesta más que el anterior.
   * [incrementos] dice cuántos puntos va a cada atributo. Si sube la vida
   * máxima, la vida actual sube lo mismo.
   *
   * `puntosLibres` son los que dejaba la regla anterior (niveles ya subidos
   * sin repartir): se gastan primero y no cuestan ni suben el nivel.
   */
  subirAtributos(p: PersonajeDto, incrementos: AtributosDto): PersonajeDto {
    const total =
      incrementos.vida + incrementos.fuerza + incrementos.destreza + incrementos.inteligencia;
    if (total < 1) throw new NegocioError('No has elegido ningún punto.');
    const gratis = Math.min(p.puntosLibres, total);
    const niveles = total - gratis;
    const costo = costoNiveles(p.nivel, niveles);
    if (costo > p.exp) {
      throw new NegocioError(`Te falta experiencia: necesitas ${costo} y tienes ${p.exp}.`);
    }
    const a = p.atributos;
    const atributos: AtributosDto = {
      vida: a.vida + incrementos.vida,
      fuerza: a.fuerza + incrementos.fuerza,
      destreza: a.destreza + incrementos.destreza,
      inteligencia: a.inteligencia + incrementos.inteligencia,
    };
    if (Object.values(atributos).some((v) => v > ATRIBUTO_MAXIMO)) {
      throw new NegocioError(`Ningún atributo puede pasar de ${ATRIBUTO_MAXIMO}.`);
    }
    return {
      ...p,
      atributos,
      nivel: p.nivel + niveles,
      exp: p.exp - costo,
      puntosLibres: p.puntosLibres - gratis,
      vidaActual: p.vidaActual + vidaMaxima(atributos) - vidaMaxima(a),
    };
  },

  /** Sube un nivel el arma o la armadura a cambio de oro. */
  mejorarEquipo(p: PersonajeDto, pieza: PiezaEquipo): PersonajeDto {
    const campo = pieza === 'arma' ? 'nivelArma' : 'nivelArmadura';
    const nivel = p.equipo[campo];
    if (nivel >= NIVEL_MAXIMO_EQUIPO) {
      throw new NegocioError('Esa pieza ya está al nivel máximo.');
    }
    const costo = costoMejora(nivel + 1);
    if (p.oro < costo) {
      throw new NegocioError(`Te falta oro: la mejora cuesta ${costo} y tienes ${p.oro}.`);
    }
    return { ...p, oro: p.oro - costo, equipo: { ...p.equipo, [campo]: nivel + 1 } };
  },
};
