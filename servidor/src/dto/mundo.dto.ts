/** Réplica del subdocumento `usuarios.partidas[].personaje.mundo`. */
export interface MundoDto {
  zonasDesbloqueadas: string[];
  cofresAbiertos: string[];
  jefesDerrotados: string[];
  /**
   * Fogatas encendidas: `altar:<zona>:<n>` en el mundo y `sala:<slug>` en las
   * salas. Ausente en las partidas anteriores al campo.
   */
  fogatasEncendidas?: string[];
  /**
   * Criaturas caídas desde el último descanso por punto de aparición
   * (`<zona o sala>#<n>`): no vuelven hasta descansar.
   */
  enemigosCaidos?: Record<string, number>;
  /** Diálogos de Oreste leídos (`oreste-<zona>-<n>`). Solo crece. */
  dialogosLeidos?: string[];
  /**
   * Palancas accionadas y muros agrietados rotos (`<zonaId>/<id>`, por
   * ejemplo `cienaga/palanca-2`). Solo crece.
   */
  mecanismosActivados?: string[];
}
