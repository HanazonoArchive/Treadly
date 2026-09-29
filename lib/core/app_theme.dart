import 'package:flutter/material.dart';

/// Centralized Design System & Theme Configuration
class AppTheme {
  // 🎨 Core Brand Colors (extracted from your inspiration mockups)
  static const Color bgDark = Color(0xFF0E131F);         // Deep Midnight Navy (Screen Background)
  static const Color surfaceDark = Color(0xFF181F31);    // Dark Slate (Cards, Search Bars, Dialogs)
  static const Color borderDark = Color(0xFF232D42);     // Subtle Card Borders
  static const Color accentOrange = Color(0xFFFF7A00);   // Discounts, Badges, Star Ratings
  static const Color productBg = Color(0xFFF4F5F7);      // Light Warm Stage (so black tires pop)

  // 📝 Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E9BAE);  // Muted grey for specs & subheadings

  // 🌙 Dark Theme Definition (The default look for Treadly)
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,

    // Top Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: bgDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom Navigation Bar Theme (Midnight Slate)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bgDark,
      elevation: 0,
      indicatorColor: surfaceDark,
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
          return const IconThemeData(color: textPrimary, size: 24);
        }
        return const IconThemeData(color: textSecondary, size: 24);
      }),
    ),

    // Card Theme (Rounded slate containers)
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderDark, width: 1),
      ),
    ),

    // Button Theme (Luxury White Pill Buttons like in the mockup)
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
  );

  // Fallback light theme
  static final ThemeData light = dark;
}

