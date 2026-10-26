import 'package:flutter/material.dart';

class AppTheme {
  static const Color bgDark = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color headerDark = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFF1F5F9);

  static const Color accentOrange = Color(0xFFEA580C);
  static const Color accentOrangeWarm = Color(0xFFC2410C);
  static const Color productBg = Color(0xFFF8FAFC);

  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color statusSubmitted = Color(0xFFD97706);
  static const Color statusResponded = Color(0xFF0284C7);
  static const Color statusCompleted = Color(0xFF059669);
  static const Color statusCancelled = Color(0xFFE11D48);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.light(
      primary: accentOrange,
      secondary: accentOrangeWarm,
      surface: surfaceDark,
      error: statusCancelled,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: headerDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: headerDark,
      elevation: 1,
      indicatorColor: const Color(0xFFFFEDD5),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          );
        }
        return const TextStyle(color: textSecondary, fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: accentOrange, size: 24);
        }
        return const IconThemeData(color: textSecondary, size: 24);
      }),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderDark, width: 1),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
  );

  static final ThemeData dark = light;
}
