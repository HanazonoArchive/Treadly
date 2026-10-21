import 'package:flutter/material.dart';

/// Centralized Design System & Theme Configuration
/// "Precision Asphalt & Technical Amber" Executive Automotive Design System
/// Inspired by Continental, Porsche Design, and Tire Rack Pro.
class AppTheme {
  // 🏁 Core Brand Surfaces & Backgrounds
  static const Color bgDark = Color(0xFF0D0F14);         // Deep Carbon Asphalt (Screen Canvas)
  static const Color surfaceDark = Color(0xFF161A22);    // Smoked Alloy (Cards, Tiles & Containers)
  static const Color surfaceElevated = Color(0xFF1E232E);// Elevated Surfaces, Dialogs & Modals
  static const Color headerDark = Color(0xFF11141A);     // Top Bars & Sticky Headers
  static const Color inputBg = Color(0xFF090B0F);        // Deep Recessed Input Background
  static const Color borderDark = Color(0xFF262C38);     // Precision Machined Alloy Borders
  static const Color borderSubtle = Color(0xFF1E242E);   // Soft Divider Lines

  // 🏎️ Brand & Accent Colors
  static const Color accentOrange = Color(0xFFF59E0B);   // Technical Amber Gold (Primary Brand Accent)
  static const Color accentOrangeWarm = Color(0xFFEA580C);// Deep Track Amber (Gradients & Pressed states)
  static const Color productBg = Color(0xFFF1F3F5);      // Studio Titanium Stage (for Tire Visuals)

  // 📝 Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);    // Crisp Titanium White
  static const Color textSecondary = Color(0xFF94A3B8);  // Alloy Slate (Specs, Subheadings)
  static const Color textMuted = Color(0xFF64748B);      // Subtle Metadata

  // 🚦 Refined Status Indicators
  static const Color statusSubmitted = Color(0xFFF59E0B);// Technical Amber
  static const Color statusResponded = Color(0xFF38BDF8);// Ice Sky Blue
  static const Color statusCompleted = Color(0xFF10B981);// Emerald Green
  static const Color statusCancelled = Color(0xFFF43F5E);// Crimson Rose

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
        fontFamily: 'Outfit',
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Bottom Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: headerDark,
      elevation: 0,
      indicatorColor: surfaceElevated,
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

    // Card Theme
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderDark, width: 1),
      ),
    ),

    // Button Theme
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accentOrange,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    ),
  );

  // Fallback light theme
  static final ThemeData light = dark;
}

