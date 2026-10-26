import type { AtributosDto } from './atributos.dto.js';
import type { ClaseCodigo } from './clase-codigo.js';
import type { EquipoDto } from './equipo.dto.js';
import type { EstadisticasDto } from './estadisticas.dto.js';
import type { MundoDto } from './mundo.dto.js';
import type { UbicacionDto } from './ubicacion.dto.js';

export const APARIENCIAS = ['hombre', 'mujer'] as const;
export type Apariencia = (typeof APARIENCIAS)[number];

/** Réplica del subdocumento `usuarios.partidas[].personaje`. */
export interface PersonajeDto {
  nombre: string;
  /** Llave hacia `clases._id`. */
  claseCodigo: ClaseCodigo;
  apariencia: Apariencia;
  nivel: number;
  exp: number;
  puntosLibres: number;
  oro: number;
  atributos: AtributosDto;
  vidaActual: number;
  estaminaActual: number;
  equipo: EquipoDto;
  ubicacion: UbicacionDto;
  mundo: MundoDto;
  estadisticas: EstadisticasDto;
}
