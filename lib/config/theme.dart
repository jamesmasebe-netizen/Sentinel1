import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// XM System Design System
/// Material 3 Expressive theme matching a premium, enterprise-grade Google app aesthetic
class XMTheme {
  // ─── Google Brand Colors (M3 Baseline) ───
  static const Color primary = Color(0xFF1A73E8); // Authentic Google Blue
  static const Color primaryLight = Color(0xFF8AB4F8);
  static const Color primaryDark = Color(0xFF174EA6);
  static const Color sidebarBg = Color(0xFF0F172A); // Dark navy for sidebar

  static const Color secondary = Color(0xFF202124); // Google Grey 900
  static const Color secondaryLight = Color(0xFF5F6368); // Google Grey 700

  // ─── Semantic Colors (Google Core Colors) ───
  static const Color success = Color(0xFF1E8E3E); // Google Green
  static const Color warning = Color(0xFFF9AB00); // Google Yellow
  static const Color error = Color(0xFFD93025); // Google Red
  static const Color info = Color(0xFF1A73E8); // Google Blue

  // ─── Semantic Palette: Risk & Severity ───
  static const Color riskExtreme = Color(0xFFB71C1C); // Deep Red
  static const Color riskHigh = Color(0xFFD32F2F); // Red
  static const Color riskMedium = Color(0xFFF57C00); // Orange
  static const Color riskLow = Color(0xFF388E3C); // Green

  static const Color severityCritical = Color(0xFFB71C1C);
  static const Color severityMajor = Color(0xFFD32F2F);
  static const Color severityModerate = Color(0xFFF57C00); // Added
  static const Color severityMinor = Color(0xFFF9AB00); // Updated to Yellow
  static const Color severityNegligible = Color(0xFF388E3C);

  static const Color statusActive = Color(0xFF1E8E3E);
  static const Color statusDraft = Color(0xFF5F6368);
  static const Color statusArchived = Color(0xFF202124);

  // Status Semantic Aliases
  static const Color statusOpen = Color(0xFF1A73E8); // Blue
  static const Color statusInProgress = Color(0xFFF9AB00); // Yellow/Orange
  static const Color statusResolved = Color(0xFF1E8E3E); // Green
  static const Color statusClosed = Color(0xFF202124); // Dark Grey

  // ─── Surface Colors (M3 Surface Container Roles) ───
  static const Color scaffoldBackground = Color(0xFFF8F9FA); // Google Grey 50
  static const Color surfaceLowest = Colors.white;
  static const Color surfaceLow = Color(0xFFF2F2F2);
  static const Color surfaceDefault = Color(0xFFF8F9FA);
  static const Color surfaceHigh = Color(0xFFECECEC);
  static const Color surfaceHighest = Color(0xFFE2E2E2);

  // ─── Dark Theme Colors ───
  static const Color darkScaffoldBackground = Color(
    0xFF131314,
  ); // Google Dark Background
  static const Color darkSurfaceLowest = Color(0xFF1E1F20);
  static const Color darkSurfaceLow = Color(0xFF28292A);
  static const Color darkSurfaceDefault = Color(0xFF2F3033);
  static const Color darkSurfaceHigh = Color(0xFF3C4043);
  static const Color darkSurfaceHighest = Color(0xFF4F5256);

  // ─── Border Radius (M3 Standard) ───
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 28.0; // M3 Extra Large (Cards/Dialogs)
  static const double radiusFull = 1000.0; // Pill shape

  // ─── Spacing (M3 Baseline) ───
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
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD3E3FD),
      onPrimaryContainer: Color(0xFF041E49),
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE8F0FE),
      onSecondaryContainer: Color(0xFF174EA6),
      surface: surfaceLowest,
      onSurface: Color(0xFF1F1F1F),
      surfaceContainerLowest: surfaceLowest,
      surfaceContainerLow: surfaceLow,
      surfaceContainer: surfaceDefault,
      surfaceContainerHigh: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      outline: Color(0xFFC4C7C5),
      outlineVariant: Color(0xFFE1E3E1),
    );

    return _buildTheme(colorScheme, _textTheme);
  }

  /// Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primaryLight,
      onPrimary: Color(0xFF041E49),
      primaryContainer: Color(0xFF0842A0),
      onPrimaryContainer: Color(0xFFD3E3FD),
      secondary: primaryLight,
      onSecondary: Color(0xFF041E49),
      secondaryContainer: Color(0xFF303134),
      onSecondaryContainer: Color(0xFFE8EAED),
      surface: darkScaffoldBackground,
      onSurface: Color(0xFFE3E3E3),
      surfaceContainerLowest: darkSurfaceLowest,
      surfaceContainerLow: darkSurfaceLow,
      surfaceContainer: darkSurfaceDefault,
      surfaceContainerHigh: darkSurfaceHigh,
      surfaceContainerHighest: darkSurfaceHighest,
      outline: Color(0xFF8E918F),
      outlineVariant: Color(0xFF444746),
    );

    return _buildTheme(colorScheme, _textThemeDark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, TextTheme textTheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLow,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        margin: const EdgeInsets.symmetric(
          vertical: spacingSm,
          horizontal: spacingMd,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusFull),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.all(spacingMd),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(horizontal: spacingSm, vertical: 4),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
    );
  }

  // ─── Typography ───
  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.outfit(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.roboto(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelLarge: GoogleFonts.roboto(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.roboto(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.roboto(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );

  static TextTheme get _textThemeDark => _textTheme.apply(
    bodyColor: const Color(0xFFE3E3E3),
    displayColor: Colors.white,
  );
}
