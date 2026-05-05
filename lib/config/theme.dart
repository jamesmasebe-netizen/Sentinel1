import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// XM System Design System
/// Material 3 Expressive theme matching a premium, enterprise-grade Google app aesthetic
class XMTheme {
  // ─── Google Brand Colors ───
  static const Color primary = Color(0xFF1A73E8); // Authentic Google Blue
  static const Color primaryLight = Color(0xFF8AB4F8);
  static const Color primaryDark = Color(0xFF174EA6);

  static const Color secondary = Color(0xFF202124); // Google Grey 900
  static const Color secondaryLight = Color(0xFF5F6368); // Google Grey 700

  // ─── Semantic Colors (Google Core Colors) ───
  static const Color success = Color(0xFF1E8E3E); // Google Green
  static const Color warning = Color(0xFFF9AB00); // Google Yellow
  static const Color error = Color(0xFFD93025); // Google Red
  static const Color info = Color(0xFF1A73E8); // Google Blue

  // Extended Semantic/Status Colors
  static const Color riskExtreme = Color(0xFFA50E0E); // Darker red
  static const Color riskHigh = error;
  static const Color riskMedium = warning;
  static const Color riskLow = success;
  
  static const Color severityCritical = Color(0xFFA50E0E);
  static const Color severityMajor = error;
  static const Color severityModerate = warning;
  static const Color severityMinor = info;
  static const Color severityNegligible = success;

  static const Color statusOpen = error;
  static const Color statusInProgress = info;
  static const Color statusResolved = success;
  static const Color statusClosed = Color(0xFF5F6368); // Google Grey 700
  static const Color statusDraft = Color(0xFF9AA0A6); // Google Grey 500

  // ─── Surface Colors ───
  static const Color scaffoldBackground = Color(0xFFF8F9FA); // Google Grey 50
  static const Color surfaceContainer = Colors.white; 
  
  // ─── Dark Theme Colors ───
  static const Color darkScaffoldBackground = Color(0xFF202124); // Google Grey 900
  static const Color darkSurfaceContainer = Color(0xFF303134); // Google Grey 800

  // ─── Sidebar / Nav ───
  static const Color sidebarBg = Color(0xFFF8F9FA); // Usually same as scaffold in Google apps
  static const Color sidebarText = Color(0xFF5F6368);
  static const Color sidebarActiveText = Color(0xFF1967D2);
  static const Color sidebarActiveBg = Color(0xFFE8F0FE); // Soft blue background for active nav

  // ─── Border Radius ───
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0; // Material 3 large
  static const double radiusXl = 100.0; // Fully rounded (pill shape)

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
      surface: surfaceContainer,
      surfaceContainerHighest: const Color(0xFFE8EAED), // Google Grey 200
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: const Color(0xFF202124),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF202124),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0, // M3 Expressive prefers flat cards with borders or very soft shadows
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: Color(0xFFE8EAED), width: 1),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0, // Flat buttons in M3
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl), // Pill-shaped
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl), // Pill-shaped
          ),
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1), // Google Grey 300
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl), // Pill-shaped
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: Color(0xFFDADCE0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.roboto(
          color: const Color(0xFF5F6368),
          fontSize: 14,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: surfaceContainer, // Google M3 typically uses surface with primary icon, or primary container
        foregroundColor: primary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg), // Squircle
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        selectedItemColor: const Color(0xFF202124),
        unselectedItemColor: const Color(0xFF5F6368),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBackground,
        indicatorColor: const Color(0xFFC2E7FF), // Very soft blue indicator
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF202124))
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF001D35));
          }
          return const IconThemeData(color: Color(0xFF444746));
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scaffoldBackground,
        indicatorColor: const Color(0xFFC2E7FF),
        selectedIconTheme: const IconThemeData(color: Color(0xFF001D35)),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF444746)),
        selectedLabelTextStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF202124)),
        unselectedLabelTextStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF444746)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: const Color(0xFFE8F0FE),
        labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF3C4043)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs), // Standard chip radius
          side: const BorderSide(color: Color(0xFFDADCE0)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE8EAED), // Google Grey 200
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232), // Google standard dark grey snackbar
        contentTextStyle: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
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
      error: const Color(0xFFF28B82), // Google Red Light
      surface: darkSurfaceContainer,
      surfaceContainerHighest: const Color(0xFF3C4043),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textThemeDark,
      scaffoldBackgroundColor: darkScaffoldBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScaffoldBackground,
        foregroundColor: const Color(0xFFE8EAED),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFE8EAED),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: Color(0xFF5F6368), width: 1),
        ),
        margin: const EdgeInsets.all(spacingSm),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: const Color(0xFF202124),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: const Color(0xFF202124),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          side: const BorderSide(color: Color(0xFF5F6368), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: Color(0xFF5F6368)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: Color(0xFF5F6368)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: const Color(0xFF3C4043),
        foregroundColor: primaryLight,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkScaffoldBackground,
        indicatorColor: const Color(0xFF004A77),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED))
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFFC2E7FF));
          }
          return const IconThemeData(color: Color(0xFFC4C7C5));
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkScaffoldBackground,
        indicatorColor: const Color(0xFF004A77),
        selectedIconTheme: const IconThemeData(color: Color(0xFFC2E7FF)),
        unselectedIconTheme: const IconThemeData(color: Color(0xFFC4C7C5)),
        selectedLabelTextStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED)),
        unselectedLabelTextStyle: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFC4C7C5)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceContainer,
        selectedColor: const Color(0xFF004A77),
        labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXs),
          side: const BorderSide(color: Color(0xFF5F6368)),
        ),
      ),
    );
  }

  // ─── Google Typography (Outfit for display/titles, Roboto for body) ───
  static TextTheme get _textTheme => TextTheme(
    displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.w400, color: const Color(0xFF202124)),
    displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.w400, color: const Color(0xFF202124)),
    displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w400, color: const Color(0xFF202124)),
    headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w500, color: const Color(0xFF202124)),
    headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w500, color: const Color(0xFF202124)),
    headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w500, color: const Color(0xFF202124)),
    titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500, color: const Color(0xFF202124)),
    titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF202124), letterSpacing: 0.15),
    titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3C4043), letterSpacing: 0.1),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFF3C4043), letterSpacing: 0.5),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF5F6368), letterSpacing: 0.25),
    bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF5F6368), letterSpacing: 0.4),
    labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF3C4043), letterSpacing: 0.1),
    labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF5F6368), letterSpacing: 0.5),
    labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF5F6368), letterSpacing: 0.5),
  );

  static TextTheme get _textThemeDark => TextTheme(
    displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.w400, color: const Color(0xFFE8EAED)),
    displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.w400, color: const Color(0xFFE8EAED)),
    displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w400, color: const Color(0xFFE8EAED)),
    headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED)),
    headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED)),
    headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED)),
    titleLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED)),
    titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFFE8EAED), letterSpacing: 0.15),
    titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBDC1C6), letterSpacing: 0.1),
    bodyLarge: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: const Color(0xFFBDC1C6), letterSpacing: 0.5),
    bodyMedium: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF9AA0A6), letterSpacing: 0.25),
    bodySmall: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, color: const Color(0xFF9AA0A6), letterSpacing: 0.4),
    labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFFBDC1C6), letterSpacing: 0.1),
    labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF9AA0A6), letterSpacing: 0.5),
    labelSmall: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF9AA0A6), letterSpacing: 0.5),
  );
}
