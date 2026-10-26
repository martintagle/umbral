import type { AtributosBaseDto } from './atributos-base.dto.js';
import type { ClaseCodigo } from './clase-codigo.js';

/**
 * Réplica de un documento de la colección `clases`. `_id` es el código de la
 * clase y es la llave a la que apunta `personaje.claseCodigo`.
 */
export interface ClaseDto {
  _id: ClaseCodigo;
  nombre: string;
  arma: string;
  descripcion: string;
  atributosBase: AtributosBaseDto;
}
