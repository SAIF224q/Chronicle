import 'package:flutter/material.dart';

class ChronicleTheme {
  const ChronicleTheme._();

  static ThemeData buildTheme(String themeName) {
    final bool isEmber = themeName == 'burnt_ember';

    // Sunset Coral Palette (Option A)
    const primaryCoral = Color(0xFFFF6B35);
    const bgCoral = Color(0xFFFAFAF9);
    const cardCoral = Color(0xFFFFFFFF);
    const textCoral = Color(0xFF2E2522);
    const textCoralLight = Color(0xFF7D726E);
    const highlightCoral = Color(0xFFFFF0EB);
    const borderCoral = Color(0xFFE6DFDC);

    // Burnt Ember Palette (Option C)
    const primaryEmber = Color(0xFFD97706);
    const bgEmber = Color(0xFFF5F5F4);
    const cardEmber = Color(0xFFFAF9F6);
    const textEmber = Color(0xFF1C1917);
    const textEmberLight = Color(0xFF6B6664);
    const highlightEmber = Color(0xFFFEF3C7);
    const borderEmber = Color(0xFFE4E1DE);

    final primary = isEmber ? primaryEmber : primaryCoral;
    final scaffoldBg = isEmber ? bgEmber : bgCoral;
    final cardColor = isEmber ? cardEmber : cardCoral;
    final textColor = isEmber ? textEmber : textCoral;
    final textSecondary = isEmber ? textEmberLight : textCoralLight;
    final highlight = isEmber ? highlightEmber : highlightCoral;
    final border = isEmber ? borderEmber : borderCoral;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: cardColor,
      onSurface: textColor,
      onSurfaceVariant: textSecondary,
      outlineVariant: border,
      surfaceContainerLow: cardColor,
      surfaceContainerHigh: highlight,
      surfaceContainerHighest: border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: highlight,
        disabledColor: scaffoldBg,
        selectedColor: primary,
        secondarySelectedColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        labelStyle: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: textSecondary),
        labelStyle: TextStyle(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: border),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        actionTextColor: primary,
        closeIconColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
