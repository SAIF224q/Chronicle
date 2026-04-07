import 'package:flutter/material.dart';

class ChronicleTheme {
  const ChronicleTheme._();

  static const Color majorColor = Color(0xFFFFF8DE);
  static const Color minorColor = Color(0xFF18230F);

  static const ColorScheme colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: minorColor,
    onPrimary: majorColor,
    secondary: minorColor,
    onSecondary: majorColor,
    error: minorColor,
    onError: majorColor,
    surface: majorColor,
    onSurface: minorColor,
  );

  static ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: majorColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: minorColor,
        foregroundColor: majorColor,
      ),
      cardTheme: const CardThemeData(color: majorColor),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: minorColor,
        foregroundColor: majorColor,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: minorColor,
        disabledColor: majorColor,
        selectedColor: minorColor,
        secondarySelectedColor: minorColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        labelStyle: const TextStyle(color: majorColor),
        secondaryLabelStyle: const TextStyle(color: majorColor),
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: minorColor),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: minorColor,
          side: const BorderSide(color: minorColor),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: minorColor),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: minorColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: minorColor, width: 2),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: minorColor,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: minorColor,
        contentTextStyle: TextStyle(color: majorColor),
        actionTextColor: majorColor,
        closeIconColor: majorColor,
      ),
    );
  }
}
