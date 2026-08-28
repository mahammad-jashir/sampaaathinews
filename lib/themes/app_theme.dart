import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF438AFE);
  static const Color secondaryColor = Color(0xFF2D73E5);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color lightBgColor = Color(0xFFF5F9FF);
  static const Color darkBgColor = Color(0xFF0F172A);
  static const Color textColorLight = Color(0xFF1A1A1A);
  static const Color textColorDark = Color(0xFFF8FAFC);
  static const Color greyColor = Color(0xFF6B7280);
  static const Color borderLightColor = Color(0xFFE5E7EB);
  static const Color borderDarkColor = Color(0xFF334155);
  
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);

  // Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBgColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: whiteColor,
        error: errorColor,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: textColorLight,
        outline: borderLightColor,
      ),
      dividerColor: borderLightColor,
      textTheme: GoogleFonts.notoSansKannadaTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansKannada(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColorLight,
        ),
        headlineLarge: GoogleFonts.notoSansKannada(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColorLight,
        ),
        headlineMedium: GoogleFonts.notoSansKannada(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColorLight,
        ),
        titleLarge: GoogleFonts.notoSansKannada(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColorLight,
        ),
        bodyLarge: GoogleFonts.notoSerifKannada(
          fontSize: 16,
          height: 1.6,
          color: textColorLight,
        ),
        bodyMedium: GoogleFonts.notoSerifKannada(
          fontSize: 14,
          height: 1.5,
          color: textColorLight,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColorLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: whiteColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColorLight),
        titleTextStyle: TextStyle(
          color: textColorLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: whiteColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBgColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Color(0xFF1E293B),
        error: errorColor,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: textColorDark,
        outline: borderDarkColor,
      ),
      dividerColor: borderDarkColor,
      textTheme: GoogleFonts.notoSansKannadaTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansKannada(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColorDark,
        ),
        headlineLarge: GoogleFonts.notoSansKannada(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColorDark,
        ),
        headlineMedium: GoogleFonts.notoSansKannada(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColorDark,
        ),
        titleLarge: GoogleFonts.notoSansKannada(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColorDark,
        ),
        bodyLarge: GoogleFonts.notoSerifKannada(
          fontSize: 16,
          height: 1.6,
          color: textColorDark,
        ),
        bodyMedium: GoogleFonts.notoSerifKannada(
          fontSize: 14,
          height: 1.5,
          color: textColorDark,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColorDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        elevation: 0,
        iconTheme: IconThemeData(color: textColorDark),
        titleTextStyle: TextStyle(
          color: textColorDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
