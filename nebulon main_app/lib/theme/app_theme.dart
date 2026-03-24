import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Brand Colors
  static const Color indigo = Color(0xFF101A77);
  static const Color emerald = Color(0xFF006B5C);
  static const Color mint = Color(0xFF68FADD);
  static const Color rose = Color(0xFFBA1A1A); // Red for Expenses
  static const Color amber = Color(0xFFFFBF00); // For warnings/highlights

  // Background and Surface Colors
  static const Color background = Color(0xFFFCF9F8);
  static const Color surface = Color(0xFFF6F3F2);
  static const Color surfaceLight = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1B1B);
  static const Color textSecondary = Color(0xFF777683);
  static const Color textLight = Color(0xFF464652);

  // Border and Divider Colors
  static const Color borderLight = Color(0xFFC7C5D4);
  static const Color divider = Color(0xFFE5E2E1);

  // Status Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF006B5C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF101A77), Color(0xFF2B348D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: indigo,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: indigo,
        primary: indigo,
        secondary: emerald,
        surface: surface,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -1),
        displayMedium: GoogleFonts.manrope(fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
        displaySmall: GoogleFonts.manrope(fontSize: 24, fontWeight: FontWeight.w800, color: textPrimary),
        headlineLarge: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textLight, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textLight, height: 1.5),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textSecondary),
        labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
        labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: indigo,
          side: const BorderSide(color: borderLight),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: borderLight.withValues(alpha: 0.1)),
        ),
      ),
      useMaterial3: true,
    );
  }
}
