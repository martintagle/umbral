import type { PersonajeDto } from './personaje.dto.js';

/** Réplica de cada elemento del array `usuarios.partidas`. */
export interface PartidaDto {
  partidaId: string;
  creadaEn: Date;
  ultimaVezJugada: Date;
  personaje: PersonajeDto;
}
