/// Validaciones locales para usar como `validator` de un `TextFormField`.
/// Devuelven `null` si el valor es válido o el mensaje de error si no lo es.
abstract final class Validaciones {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _username = RegExp(r'^[A-Za-z0-9_.-]+$');

  static String? requerido(String? valor, {String campo = 'Este campo'}) {
    if (valor == null || valor.trim().isEmpty) return '$campo es obligatorio.';
    return null;
  }

  static String? email(String? valor) {
    final error = requerido(valor, campo: 'El correo');
    if (error != null) return error;
    if (!_email.hasMatch(valor!.trim())) return 'Escribe un correo válido.';
    return null;
  }

  static String? username(String? valor) {
    final error = requerido(valor, campo: 'El nombre de usuario');
    if (error != null) return error;
    final v = valor!.trim();
    if (v.length < 3) return 'Usa al menos 3 caracteres.';
    if (v.length > 20) return 'Usa como máximo 20 caracteres.';
    if (!_username.hasMatch(v)) {
      return 'Solo letras, números, punto, guion y guion bajo.';
    }
    return null;
  }

  static String? password(String? valor) {
    if (valor == null || valor.isEmpty) return 'La contraseña es obligatoria.';
    if (valor.length < 8) return 'Usa al menos 8 caracteres.';
    return null;
  }

  static String? Function(String?) confirmarPassword(String Function() original) {
    return (valor) {
      if (valor == null || valor.isEmpty) return 'Repite la contraseña.';
      if (valor != original()) return 'Las contraseñas no coinciden.';
      return null;
    };
  }

  static String? nombrePersonaje(String? valor) {
    final error = requerido(valor, campo: 'El nombre');
    if (error != null) return error;
    final v = valor!.trim();
    if (v.length < 2) return 'Usa al menos 2 caracteres.';
    if (v.length > 16) return 'Usa como máximo 16 caracteres.';
    return null;
  }
}
