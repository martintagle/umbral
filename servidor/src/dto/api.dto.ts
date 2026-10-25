/**
 * Objetos que viajan por la API pero no son colecciones: se calculan o se
 * reciben, nunca se guardan tal cual.
 */
import type { AtributosDto } from './atributos.dto.js';
import type { Apariencia } from './personaje.dto.js';
import type { UbicacionDto } from './ubicacion.dto.js';

/** Valores de combate de un personaje, calculados con las reglas del juego. */
export interface CombateDto {
  vidaMaxima: number;
  /** Experiencia total que hace falta para pasar al siguiente nivel. */
  expSiguiente: number;
  dano: number;
  defensa: number;
  probabilidadCritico: number;
  multiplicadorCritico: number;
}

/** Una clase tal como se muestra al crear un personaje. */
export interface ClaseDto {
  id: string;
  atributos: AtributosDto;
  oroInicial: number;
  combate: CombateDto;
}

export interface CatalogoClasesDto {
  apariencias: readonly Apariencia[];
  clases: ClaseDto[];
}

/**
 * Lo que ha pasado en la partida desde el último guardado. La app envía los
 * hechos y el servidor aplica las reglas (subida de nivel incluida).
 */
export interface ProgresoDto {
  expGanada: number;
  oroGanado: number;
  enemigosDerrotados: number;
  muertes: number;
  segundosJugados: number;
  vidaActual: number;
  ubicacion: UbicacionDto;
}
