import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _primaryColor = Color(0xFF1565C0);
  static const Color _secondaryColor = Color(0xFF8D6E63);
  static const Color _tertiaryColor = Color(0xFF00796B);
  static const Color _errorColor = Color(0xFFB00020);

  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1C1B1F)
        : const Color(0xFFE6E1E5);

    return GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(
          fontSize: 57, fontWeight: FontWeight.w400, color: baseColor),
      displayMedium: GoogleFonts.nunito(
          fontSize: 45, fontWeight: FontWeight.w400, color: baseColor),
      displaySmall: GoogleFonts.nunito(
          fontSize: 36, fontWeight: FontWeight.w400, color: baseColor),
      headlineLarge: GoogleFonts.nunito(
          fontSize: 32, fontWeight: FontWeight.w700, color: baseColor),
      headlineMedium: GoogleFonts.nunito(
          fontSize: 28, fontWeight: FontWeight.w700, color: baseColor),
      headlineSmall: GoogleFonts.nunito(
          fontSize: 24, fontWeight: FontWeight.w600, color: baseColor),
      titleLarge: GoogleFonts.nunito(
          fontSize: 22, fontWeight: FontWeight.w600, color: baseColor),
      titleMedium: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w600, color: baseColor),
      titleSmall: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w500, color: baseColor),
      bodyLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w400, color: baseColor),
      bodyMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w400, color: baseColor),
      bodySmall: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w400, color: baseColor),
      labelLarge: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w700, color: baseColor),
      labelMedium: GoogleFonts.nunito(
          fontSize: 12, fontWeight: FontWeight.w500, color: baseColor),
      labelSmall: GoogleFonts.nunito(
          fontSize: 11, fontWeight: FontWeight.w500, color: baseColor),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      secondary: _secondaryColor,
      tertiary: _tertiaryColor,
      error: _errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(fontSize: 14),
        hintStyle: GoogleFonts.nunito(fontSize: 14, color: colorScheme.outline),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      secondary: _secondaryColor,
      tertiary: _tertiaryColor,
      error: _errorColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: GoogleFonts.nunito(fontSize: 14),
        hintStyle: GoogleFonts.nunito(fontSize: 14, color: colorScheme.outline),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
