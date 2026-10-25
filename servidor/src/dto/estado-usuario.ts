/** Valores permitidos para `usuarios.estado`. */
export const ESTADOS_USUARIO = ['activo', 'baneado', 'eliminado'] as const;

export type EstadoUsuario = (typeof ESTADOS_USUARIO)[number];
