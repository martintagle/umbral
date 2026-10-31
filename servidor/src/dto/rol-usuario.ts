/** Valores permitidos para `usuarios.rol`. */
export const ROLES_USUARIO = ['jugador', 'admin'] as const;

export type RolUsuario = (typeof ROLES_USUARIO)[number];
