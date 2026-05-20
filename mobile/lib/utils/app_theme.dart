import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tokens alineados con mobile/design-reference/*.html (DS Yoltec mobile)
class AppTheme {
  // Brand verde clínico
  static const Color primaryColor = Color(0xFF1A5C3A);
  static const Color primaryDark = Color(0xFF144A2E);
  static const Color primaryLight = Color(0xFF4CAF82);
  static const Color primarySurface = Color(0xFFE8F5EE);

  // IA — azul clínico (acento separado del brand)
  static const Color iaColor = Color(0xFF2563EB);
  static const Color iaSurface = Color(0xFFEFF6FF);

  // Estados
  static const Color success = Color(0xFF1A5C3A);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSurface = Color(0xFFFEF3E0);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);

  // Superficie y texto (light)
  static const Color bg = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSoft = Color(0xFFF3F4F6);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textSubtle = Color(0xFF9CA3AF);

  // Superficies dark (alineadas con design-reference-dark)
  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1A1D27);
  static const Color borderDark = Color(0xFF2D3144);
  static const Color textPrimaryDark = Color(0xFFE5E7EB);
  static const Color textMutedDark = Color(0xFF9CA3AF);
  static const Color textSubtleDark = Color(0xFF6B7280);

  // Grises neutros (Tailwind) — aliases para compatibilidad con widgets existentes
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF6B7280);
  static const Color gray700 = Color(0xFF4B5563);
  static const Color gray800 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);

  // Radios
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusPill = 999;

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme(const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMuted),
      bodyLarge: TextStyle(fontSize: 14, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: textMuted),
      bodySmall: TextStyle(fontSize: 12, color: textSubtle),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: primarySurface,
        onPrimaryContainer: primaryDark,
        secondary: iaColor,
        onSecondary: Colors.white,
        secondaryContainer: iaSurface,
        onSecondaryContainer: iaColor,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
        errorContainer: errorSurface,
        onErrorContainer: error,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.04),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
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
        selectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(color: borderSoft, thickness: 1, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: primarySurface,
        labelStyle: const TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimaryDark, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimaryDark, letterSpacing: -0.3),
      headlineSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimaryDark),
      titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimaryDark),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textMutedDark),
      bodyLarge: TextStyle(fontSize: 14, color: textPrimaryDark),
      bodyMedium: TextStyle(fontSize: 13, color: textMutedDark),
      bodySmall: TextStyle(fontSize: 12, color: textSubtleDark),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimaryDark),
    ));

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1B3A2A),
        onPrimaryContainer: Colors.white,
        secondary: iaColor,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF1E293B),
        onSecondaryContainer: iaColor,
        surface: surfaceDark,
        onSurface: textPrimaryDark,
        error: error,
        onError: Colors.white,
        errorContainer: Color(0xFF3F1414),
        onErrorContainer: Color(0xFFFCA5A5),
      ),
      scaffoldBackgroundColor: bgDark,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: textMutedDark, fontSize: 13),
        hintStyle: const TextStyle(color: textSubtleDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryLight,
        unselectedItemColor: textSubtleDark,
        backgroundColor: surfaceDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
      ),
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(color: borderDark, thickness: 1, space: 0),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF1B3A2A),
        labelStyle: const TextStyle(color: primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusPill)),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceDark,
        contentTextStyle: const TextStyle(color: textPrimaryDark, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
