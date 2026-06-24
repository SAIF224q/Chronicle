import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChronicleTheme {
  const ChronicleTheme._();

  static ThemeData buildTheme(String themeName) {
    final bool isEmber = themeName == 'burnt_ember';

    // Sunset Coral Palette (Option A - Premium Light Mode)
    const primaryCoral = Color(0xFFFF5D35);
    const bgCoral = Color(0xFFFCFAF7);
    const cardCoral = Color(0xFFFFFFFF);
    const textCoral = Color(0xFF1E1613);
    const textCoralLight = Color(0xFF706764);
    const highlightCoral = Color(0xFFFFF0EB);
    const borderCoral = Color(0xFFEDE8E5);

    // Burnt Ember Palette (Option C - Overhauled into Gorgeous Dark Mode)
    const primaryEmber = Color(0xFFF59E0B); // Amber / Gold Ember
    const bgEmber = Color(0xFF0F0D0C);      // Dark obsidian stone
    const cardEmber = Color(0xFF1A1715);    // obsidian container
    const textEmber = Color(0xFFF5F5F4);    // Off-white / Stone 100
    const textEmberLight = Color(0xFF9E9794); // Stone 400
    const highlightEmber = Color(0xFF272320); // Warm glowing accent
    const borderEmber = Color(0xFF2C2825);    // Dark charcoal border

    final primary = isEmber ? primaryEmber : primaryCoral;
    final scaffoldBg = isEmber ? bgEmber : bgCoral;
    final cardColor = isEmber ? cardEmber : cardCoral;
    final textColor = isEmber ? textEmber : textCoral;
    final textSecondary = isEmber ? textEmberLight : textCoralLight;
    final highlight = isEmber ? highlightEmber : highlightCoral;
    final border = isEmber ? borderEmber : borderCoral;

    final colorScheme = ColorScheme(
      brightness: isEmber ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: isEmber ? Colors.black : Colors.white,
      secondary: primary,
      onSecondary: isEmber ? Colors.black : Colors.white,
      error: const Color(0xFFEF4444), // Modern soft red
      onError: Colors.white,
      surface: cardColor,
      onSurface: textColor,
      onSurfaceVariant: textSecondary,
      outlineVariant: border,
      surfaceContainerLow: cardColor,
      surfaceContainerHigh: highlight,
      surfaceContainerHighest: border,
    );

    // Build the default base theme
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: isEmber ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w800, // Thicker, premium feel
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border.withOpacity(0.8), width: 1),
          borderRadius: BorderRadius.circular(24), // More organic
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: isEmber ? Colors.black : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Pill-like float
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: highlight,
        disabledColor: scaffoldBg,
        selectedColor: primary,
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        secondaryLabelStyle: TextStyle(
          color: isEmber ? Colors.black : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        brightness: isEmber ? Brightness.dark : Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isEmber ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
        labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isEmber ? const Color(0xFF2C2825) : textColor,
        contentTextStyle: TextStyle(color: isEmber ? textEmber : Colors.white),
        actionTextColor: primary,
        closeIconColor: isEmber ? textEmber : Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    // Apply GoogleFonts.outfit to all text
    return baseTheme.copyWith(
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme),
    );
  }
}
