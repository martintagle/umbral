/** Réplica del subdocumento `usuarios.partidas[].personaje.ubicacion`. */
export interface UbicacionDto {
  zonaId: string;
  x: number;
  y: number;
  ultimoPuntoGuardado: string | null;
}
