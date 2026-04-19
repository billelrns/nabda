import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00897B);
  static const Color accentColor = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFFFAFAFA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color textColor = Color(0xFF212121);
  static const Color subtextColor = Color(0xFF757575);

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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF121212),
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






