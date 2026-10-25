import type { CatalogoClasesDto, CombateDto, ProgresoDto } from '../dto/api.dto.js';
import type { AtributosDto } from '../dto/atributos.dto.js';
import { APARIENCIAS, type Apariencia, type PersonajeDto } from '../dto/personaje.dto.js';
import { NegocioError } from './negocio-error.js';

interface ClaseReglas {
  atributos: AtributosDto;
  oroInicial: number;
  armaduraInicial: number;
  /** Atributo con el que escala el daño del arma de la clase. */
  atributoAtaque: 'fuerza' | 'destreza' | 'inteligencia';
}

const CLASES: Record<string, ClaseReglas> = {
  vagabundo: {
    atributos: { vida: 11, fuerza: 11, destreza: 13, inteligencia: 9 },
    oroInicial: 30,
    armaduraInicial: 1,
    atributoAtaque: 'destreza',
  },
  guerrero: {
    atributos: { vida: 14, fuerza: 15, destreza: 9, inteligencia: 6 },
    oroInicial: 20,
    armaduraInicial: 2,
    atributoAtaque: 'fuerza',
  },
  arquero: {
    atributos: { vida: 10, fuerza: 8, destreza: 16, inteligencia: 10 },
    oroInicial: 40,
    armaduraInicial: 1,
    atributoAtaque: 'destreza',
  },
  mago: {
    atributos: { vida: 9, fuerza: 6, destreza: 10, inteligencia: 19 },
    oroInicial: 40,
    armaduraInicial: 0,
    atributoAtaque: 'inteligencia',
  },
  // Clase de desafío: menos atributos, sin armadura y sin oro.
  prisionero: {
    atributos: { vida: 8, fuerza: 8, destreza: 10, inteligencia: 7 },
    oroInicial: 0,
    armaduraInicial: 0,
    atributoAtaque: 'destreza',
  },
};

const ZONA_INICIAL = 'claro-de-las-lapidas';
const VIDA_BASE = 40;
const VIDA_POR_PUNTO = 8;
const DANO_POR_NIVEL_ARMA = 3;
const DANO_POR_NIVEL = 2;
const DEFENSA_POR_ARMADURA = 2;
const CRITICO_BASE = 0.05;
const CRITICO_POR_DESTREZA = 0.005;
const MULTIPLICADOR_CRITICO = 1.5;
const EXP_POR_NIVEL = 60;
const PUNTOS_POR_NIVEL = 2;
const ESTAMINA_MAXIMA = 100;

function reglasDeClase(clase: string): ClaseReglas {
  const reglas = CLASES[clase];
  if (!reglas) throw new NegocioError(`La clase "${clase}" no existe.`);
  return reglas;
}

function vidaMaxima(atributos: AtributosDto): number {
  return VIDA_BASE + atributos.vida * VIDA_POR_PUNTO;
}

function expParaSubir(nivel: number): number {
  return EXP_POR_NIVEL * nivel;
}

function combate(p: Pick<PersonajeDto, 'clase' | 'nivel' | 'atributos' | 'equipo'>): CombateDto {
  const a = p.atributos;
  const ataque = a[reglasDeClase(p.clase).atributoAtaque];
  return {
    vidaMaxima: vidaMaxima(a),
    expSiguiente: expParaSubir(p.nivel),
    dano: ataque + p.equipo.nivelArma * DANO_POR_NIVEL_ARMA + (p.nivel - 1) * DANO_POR_NIVEL,
    defensa: p.equipo.nivelArmadura * DEFENSA_POR_ARMADURA,
    probabilidadCritico: CRITICO_BASE + a.destreza * CRITICO_POR_DESTREZA,
    multiplicadorCritico: MULTIPLICADOR_CRITICO,
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

  catalogo(): CatalogoClasesDto {
    return {
      apariencias: APARIENCIAS,
      clases: Object.entries(CLASES).map(([id, c]) => ({
        id,
        atributos: c.atributos,
        oroInicial: c.oroInicial,
        combate: combate({
          clase: id,
          nivel: 1,
          atributos: c.atributos,
          equipo: { nivelArma: 1, nivelArmadura: c.armaduraInicial },
        }),
      })),
    };
  },

  /** Personaje de nivel 1 en la entrada de la zona inicial (0,0). */
  personajeInicial(nombre: string, clase: string, apariencia: string): PersonajeDto {
    const reglas = reglasDeClase(clase);
    return {
      nombre: validarNombre(nombre),
      clase,
      apariencia: validarApariencia(apariencia),
      nivel: 1,
      exp: 0,
      puntosLibres: 0,
      oro: reglas.oroInicial,
      atributos: { ...reglas.atributos },
      vidaActual: vidaMaxima(reglas.atributos),
      estaminaActual: ESTAMINA_MAXIMA,
      equipo: { nivelArma: 1, nivelArmadura: reglas.armaduraInicial },
      ubicacion: { zonaId: ZONA_INICIAL, x: 0, y: 0, ultimoPuntoGuardado: null },
      mundo: { zonasDesbloqueadas: [ZONA_INICIAL], cofresAbiertos: [], jefesDerrotados: [] },
      estadisticas: { enemigosDerrotados: 0, muertes: 0, tiempoJugadoSeg: 0 },
    };
  },

  /**
   * Suma lo ocurrido en la partida y sube de nivel las veces que haga falta.
   * Al subir de nivel el personaje recupera toda la vida.
   */
  aplicarProgreso(p: PersonajeDto, progreso: ProgresoDto): PersonajeDto {
    const maxima = vidaMaxima(p.atributos);
    if (progreso.vidaActual > maxima) {
      throw new NegocioError(`La vida no puede superar ${maxima}.`);
    }
    let nivel = p.nivel;
    let exp = p.exp + progreso.expGanada;
    while (exp >= expParaSubir(nivel)) {
      exp -= expParaSubir(nivel);
      nivel++;
    }
    const e = p.estadisticas;
    return {
      ...p,
      nivel,
      exp,
      puntosLibres: p.puntosLibres + (nivel - p.nivel) * PUNTOS_POR_NIVEL,
      oro: p.oro + progreso.oroGanado,
      vidaActual: nivel > p.nivel ? maxima : progreso.vidaActual,
      ubicacion: progreso.ubicacion,
      estadisticas: {
        enemigosDerrotados: e.enemigosDerrotados + progreso.enemigosDerrotados,
        muertes: e.muertes + progreso.muertes,
        tiempoJugadoSeg: e.tiempoJugadoSeg + progreso.segundosJugados,
      },
    };
  },
};
