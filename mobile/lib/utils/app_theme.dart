import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Verde medico institucional — Design System Yoltec
  static const Color primaryColor = Color(0xFF1B6B45);
  static const Color primaryDark = Color(0xFF155A39);
  static const Color primaryLight = Color(0xFF4CAF82);
  static const Color primarySurface = Color(0xFFE8F5EE);

  // IA — azul clinico
  static const Color iaColor = Color(0xFF2563EB);
  static const Color iaSurface = Color(0xFFEFF6FF);

  // Colores de estado
  static const Color success = Color(0xFF1B6B45);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF2563EB);

  // Neutros verde-tintados
  static const Color bg = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDE8E3);
  static const Color textPrimary = Color(0xFF1A2E25);
  static const Color textMuted = Color(0xFF4A6859);
  static const Color textSubtle = Color(0xFF7B8F86);

  // Grises legacy (para compatibilidad con widgets existentes)
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primarySurface,
        onPrimaryContainer: primaryDark,
        secondary: primaryLight,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(

          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
  
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
        hintStyle: const TextStyle(color: textSubtle),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: textSubtle,
        backgroundColor: surface,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.2),
        headlineSmall: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
        bodyLarge: TextStyle(fontSize: 14, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 13, color: textMuted),
        bodySmall: TextStyle(fontSize: 12, color: textSubtle),
      )),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primarySurface,
        labelStyle: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1B3A2A),
        onPrimaryContainer: Colors.white,
        secondary: primaryLight,
        onSecondary: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFE0E0E0),
        error: error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF153D2A),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(

          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF2C2C2C)),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
  
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: gray700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: gray700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: gray400, fontSize: 13),
        hintStyle: const TextStyle(color: gray600),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryLight,
        unselectedItemColor: gray500,
        backgroundColor: Color(0xFF1E1E1E),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
      textTheme: GoogleFonts.interTextTheme(const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFFE0E0E0)),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFE0E0E0)),
        headlineSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFFE0E0E0)),
        titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFBDBDBD)),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFBDBDBD)),
        bodyLarge: TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
        bodyMedium: TextStyle(fontSize: 13, color: gray500),
        bodySmall: TextStyle(fontSize: 12, color: gray600),
      )),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2C),
        thickness: 1,
        space: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1B3A2A),
        labelStyle: const TextStyle(color: primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      ),
    );
  }
}
