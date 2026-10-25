import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens de `docs/diseno/tokens.json`.
abstract final class Colores {
  static const abismo = Color(0xFF0D0B10);
  static const piedra = Color(0xFF1C1820);
  static const borde = Color(0xFF756A7C);
  static const hueso = Color(0xFFE8DCC4);
  static const ceniza = Color(0xFF9A8F86);
  static const sangre = Color(0xFFA3242A);
  static const brasa = Color(0xFFE08A2C);
  static const alma = Color(0xFF5AA0B8);
  static const podredumbre = Color(0xFF7F9E45);
}

abstract final class Espacios {
  static const paso1 = 4.0;
  static const paso2 = 8.0;
  static const paso4 = 16.0;
  static const paso6 = 24.0;
}

abstract final class Radios {
  static const astilla = BorderRadius.all(Radius.circular(4));
  static const sello = BorderRadius.all(Radius.circular(8));
}

/// Única sombra del diseño: desplazada un píxel de arte, sin desenfoque.
const sombraDura = [
  BoxShadow(color: Colores.abismo, offset: Offset(4, 4), blurRadius: 0),
];

abstract final class Textos {
  static TextStyle tituloJuego({Color color = Colores.hueso}) =>
      GoogleFonts.jacquard12(fontSize: 64, height: 1, color: color);

  static TextStyle tituloZona({Color color = Colores.hueso}) =>
      GoogleFonts.jacquard12(fontSize: 32, height: 40 / 32, color: color);

  static TextStyle encabezado({Color color = Colores.hueso}) =>
      GoogleFonts.pixelifySans(
          fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w600, color: color);

  static TextStyle cuerpo({Color color = Colores.hueso}) =>
      GoogleFonts.pixelifySans(fontSize: 16, height: 24 / 16, color: color);

  static TextStyle etiqueta({Color color = Colores.hueso}) =>
      GoogleFonts.silkscreen(fontSize: 12, height: 16 / 12, color: color);

  static TextStyle dano({Color color = Colores.hueso}) => GoogleFonts.silkscreen(
      fontSize: 32, height: 1, fontWeight: FontWeight.w700, color: color);

  static TextStyle contador({Color color = Colores.hueso}) =>
      GoogleFonts.silkscreen(fontSize: 16, height: 1, color: color);
}

ThemeData temaUmbral() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colores.abismo,
    colorScheme: const ColorScheme.dark(
      surface: Colores.piedra,
      primary: Colores.brasa,
      onPrimary: Colores.abismo,
      secondary: Colores.alma,
      error: Colores.sangre,
      onSurface: Colores.hueso,
    ),
    splashFactory: NoSplash.splashFactory,
    // Sin el tinte de Material 3 al desplazar: la barra queda en abismo.
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.abismo,
      foregroundColor: Colores.hueso,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.pixelifySans().fontFamily,
      bodyColor: Colores.hueso,
      displayColor: Colores.hueso,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colores.brasa,
      selectionColor: Color(0x66E08A2C),
      selectionHandleColor: Colores.brasa,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colores.piedra,
      shape: RoundedRectangleBorder(
        borderRadius: Radios.astilla,
        side: BorderSide(color: Colores.borde, width: 2),
      ),
    ),
  );
}
