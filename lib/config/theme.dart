import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// XM System Design System
/// Material 3 theme matching the dark slate enterprise aesthetic
class XMTheme {
  // ─── Brand Colors ───
  static const Color primary = Color(0xFF0F172A); // Corporate Blue / Dark Slate
  static const Color primaryLight = Color(0xFF334155);
  static const Color primaryDark = Color(0xFF020617);

  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color secondaryLight = Color(0xFF818CF8);

  static const Color success = Color(0xFF22C55E); // Growth Green
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444); // Actionable Terra
  static const Color info = Color(0xFF8B5CF6); // Intelligence Purple (Copilot)

  // ─── Surface Colors ───
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceDim = Color(0xFFF1F5F9);
  static const Color surfaceContainer = Color(0xFFFFFFFF);

  // ─── Dark Theme Colors ───
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceDim = Color(0xFF1E293B);
  static const Color darkSurfaceContainer = Color(0xFF020617);

  // ─── Sidebar / Nav ───
  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color sidebarText = Color(0xFF94A3B8);
  static const Color sidebarActiveText = Color(0xFFFFFFFF);
  static const Color sidebarActiveBg = Color(0xFF1E293B);

  // ─── Status Colors (SHEQ-specific) ───
  static const Color statusOpen = Color(0xFFEF4444);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusResolved = Color(0xFF22C55E);
  static const Color statusClosed = Color(0xFF64748B);
  static const Color statusDraft = Color(0xFF94A3B8);
  static const Color statusApproved = Color(0xFF6366F1);

  // ─── Risk Matrix Colors ───
  static const Color riskExtreme = Color(0xFFDC2626);
  static const Color riskHigh = Color(0xFFF97316);
  static const Color riskMedium = Color(0xFFFBBF24);
  static const Color riskLow = Color(0xFF22C55E);

  // ─── Severity Colors ───
  static const Color severityCritical = Color(0xFF991B1B);
  static const Color severityMajor = Color(0xFFDC2626);
  static const Color severityModerate = Color(0xFFF59E0B);
  static const Color severityMinor = Color(0xFF3B82F6);
  static const Color severityNegligible = Color(0xFF6B7280);

  // ─── Border Radius ───
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  // ─── Spacing ───
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  /// Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      secondary: secondary,
      error: error,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceContainer,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF64748B),
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceContainer,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDim,
        selectedColor: primary.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primaryLight,
      secondary: secondaryLight,
      error: error,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textThemeDark,
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceDim,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: primaryLight,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(fontSize: 57, fontWeight: FontWeight.w400, color: const Color(0xFF0F172A)),
    displayMedium: GoogleFonts.plusJakartaSans(fontSize: 45, fontWeight: FontWeight.w400, color: const Color(0xFF0F172A)),
    displaySmall: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w400, color: const Color(0xFF0F172A)),
    headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
    headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
    headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
    titleLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
    titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF1E293B)),
    titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF334155)),
    bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF334155)),
    bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF475569)),
    bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF64748B)),
    labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
    labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
    labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
  );

  static TextTheme get _textThemeDark => TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(fontSize: 57, fontWeight: FontWeight.w400, color: Colors.white),
    displayMedium: GoogleFonts.plusJakartaSans(fontSize: 45, fontWeight: FontWeight.w400, color: Colors.white),
    displaySmall: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w400, color: Colors.white),
    headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white),
    headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
    headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
    titleLarge: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
    titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE2E8F0)),
    titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFCBD5E1)),
    bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFFCBD5E1)),
    bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF94A3B8)),
    bodySmall: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF64748B)),
    labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFFE2E8F0)),
    labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8)),
    labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
  );
}
