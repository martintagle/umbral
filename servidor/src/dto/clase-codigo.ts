/** Valores permitidos para `clases._id` y `usuarios.partidas[].personaje.claseCodigo`. */
export const CLASES_CODIGO = ['vagabundo', 'guerrero', 'arquero', 'mago', 'prisionero'] as const;

export type ClaseCodigo = (typeof CLASES_CODIGO)[number];
