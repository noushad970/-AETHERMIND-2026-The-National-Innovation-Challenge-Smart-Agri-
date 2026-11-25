import 'package:flutter/material.dart';

/// Centralized theming for the application.
/// "Harvest Paper": deep emerald and harvest gold on a warm paper background,
/// with flat bordered cards, soft corners and pill-shaped buttons.
class AppTheme {
  AppTheme._();

  // Brand agricultural colors
  static const Color primaryGreen = Color(0xFF0F5C4A); // Deep emerald paddy
  static const Color primaryGreenLight = Color(0xFF2EA37B); // Young sprout
  static const Color primaryGreenDark = Color(0xFF08382D); // Night field
  static const Color emeraldGreen = Color(0xFF0E8C7F); // Dew leaf teal
  static const Color goldenHarvest = Color(0xFFD98E04); // Golden paddy / wheat
  static const Color accentAmber = Color(0xFFE8A317); // Harvest gold
  static const Color sunYellow = Color(0xFFF6C445); // Morning sun
  static const Color earthBrown = Color(0xFF5B4032); // Fertile soil
  static const Color terracotta = Color(0xFFB5694B); // Warm clay
  static const Color skyBlue = Color(0xFF1F7FB5); // Monsoon sky
  static const Color dewCyan = Color(0xFF2AA79B); // Morning dew

  static const Color bgLight = Color(0xFFF7F4EC); // Warm paper
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF16241E); // Ink green
  static const Color textSecondary = Color(0xFF5A6A61); // Muted sage
  static const Color danger = Color(0xFFC0392B);
  static const Color success = Color(0xFF1B7A5C);
  static const Color warning = Color(0xFFC8590A);
  static const Color divider = Color(0xFFE7E1D1);

  // Agricultural Gradient Presets
  static const LinearGradient paddyHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF08382D),
      Color(0xFF0F5C4A),
      Color(0xFF1B7A5C),
    ],
  );

  static const LinearGradient harvestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD98E04),
      Color(0xFFF2B93B),
    ],
  );

  static const LinearGradient natureCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF3EFE2),
    ],
  );

  static const LinearGradient soilMoistureGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0E6E66),
      Color(0xFF1F7FB5),
    ],
  );

  static const LinearGradient diseaseScanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F5C4A),
      Color(0xFF0E8C7F),
    ],
  );

  static ThemeData lightTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: primaryGreen,
        secondary: accentAmber,
        surface: cardLight,
        error: danger,
      ),
      fontFamily: 'NotoSansBengali',
      fontFamilyFallback: const ['NotoSansBengali'],
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryGreen.withValues(alpha: 0.15),
        side: const BorderSide(color: Color(0xFFDDD6C2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD6C2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDDD6C2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF7A877F),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: const Color(0xFFE7E1D1),
    );
  }

  static ThemeData darkTheme() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primaryGreenLight,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: primaryGreenLight,
        secondary: goldenHarvest,
        surface: const Color(0xFF14211C),
        error: danger,
      ),
      fontFamily: 'NotoSansBengali',
      fontFamilyFallback: const ['NotoSansBengali'],
      scaffoldBackgroundColor: const Color(0xFF0A130F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1C17),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF14211C),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: primaryGreenLight.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreenLight,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreenLight,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: primaryGreenLight, width: 1.5),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111C17),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: primaryGreenLight, width: 2),
        ),
      ),
      dividerColor: const Color(0xFF23362D),
    );
  }
}
