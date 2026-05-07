import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00897B);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFFFFF8FB);  // warm pinkish white (Claude Design)
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color textColor = Color(0xFF1F1A20);  // richer dark (Claude Design)
  static const Color subtextColor = Color(0xFF4A434B);  // warmer grey (Claude Design)

  // Extended palette from Claude Design
  static const Color teal50 = Color(0xFFE0F2F1);
  static const Color teal700 = Color(0xFF00796B);
  static const Color pink50 = Color(0xFFFCE4EC);
  static const Color pink100 = Color(0xFFF8BBD0);
  static const Color pink700 = Color(0xFFC2185B);
  static const Color purple = Color(0xFF7E57C2);
  static const Color purple50 = Color(0xFFEDE7F6);
  static const Color purple700 = Color(0xFF5E35B1);
  static const Color lineColor = Color(0xFFF0E4EA);  // pink-tinted divider

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: GoogleFonts.almarai(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: GoogleFonts.almarai(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.almarai(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleLarge: GoogleFonts.almarai(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.almarai(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.almarai(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.almarai(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: GoogleFonts.almarai(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: subtextColor,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.almarai(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: _buildTextTheme(),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.almarai(
          fontSize: 14,
          color: subtextColor,
        ),
        hintStyle: GoogleFonts.almarai(
          fontSize: 14,
          color: subtextColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          shadowColor: const Color(0x1AE91E63),  // pink-tinted shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),  // pill shape (Claude Design)
          ),
          textStyle: GoogleFonts.almarai(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),  // pill shape
          ),
          side: const BorderSide(color: primaryColor),
          textStyle: GoogleFonts.almarai(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: subtextColor,
        selectedLabelStyle: GoogleFonts.almarai(fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: const Color(0x14E91E63),  // pink-tinted card shadow
        color: surfaceColor,
      ),
      dividerColor: lineColor,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF18121A),  // warm dark (Claude Design)
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.almarai(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: _buildTextTheme(),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: const Color(0xFF1E1E1E),
        error: errorColor,
      ),
    );
  }
}






