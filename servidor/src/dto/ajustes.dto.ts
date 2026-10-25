/**
 * Réplica del subdocumento `usuarios.ajustes`.
 * `musica` y `efectos` son `double` en el esquema: al escribirlos hay que
 * envolverlos en `new Double(...)`, porque JavaScript guardaría 1.0 como entero.
 */
export interface AjustesDto {
  idioma: string;
  musica: number;
  efectos: number;
}
