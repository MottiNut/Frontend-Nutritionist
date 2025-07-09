import 'package:flutter/material.dart';

class AppThemeProvider extends ChangeNotifier {
  final AppTypography _typography = AppTypography();

  ThemeData getTheme({
    required double fontSize,
    required bool isDarkMode,
  }) {
    final textTheme = _typography.getTextTheme(
      fontSize: fontSize,
      isDarkMode: isDarkMode,
    );

    if (isDarkMode) {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: Colors.black,
        textTheme: textTheme,
        // Configurar fontFamily por defecto para toda la app
        fontFamily: 'Omnes',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade900,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyan, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          labelStyle: TextStyle(
            fontFamily: 'Omnes',
            color: Colors.grey[300],
            fontWeight: FontWeight.w400,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Omnes',
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Omnes',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Omnes',
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.cyan,
          selectionColor: Colors.cyan.withOpacity(0.3),
          selectionHandleColor: Colors.cyan,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Omnes',
            fontSize: fontSize + 4,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.cyan,
        scaffoldBackgroundColor: Colors.white,
        textTheme: textTheme,
        // Configurar fontFamily por defecto para toda la app
        fontFamily: 'Omnes',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.cyan, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          labelStyle: TextStyle(
            fontFamily: 'Omnes',
            color: Colors.grey[700],
            fontWeight: FontWeight.w400,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyan,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Omnes',
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Omnes',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Omnes',
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.cyan,
          selectionColor: Colors.cyan.withOpacity(0.3),
          selectionHandleColor: Colors.cyan,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Omnes',
            fontSize: fontSize + 4,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      );
    }
  }
}

class AppTypography {
  static final AppTypography _instance = AppTypography._internal();

  factory AppTypography() {
    return _instance;
  }

  AppTypography._internal();

  // Configuración de pesos de fuente estilo redes sociales con Omnes
  static const String fontFamily = 'Omnes';
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight black = FontWeight.w900;

  TextTheme getTextTheme({
    required double fontSize,
    required bool isDarkMode,
  }) {
    final baseColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryColor = isDarkMode ? Colors.grey[300] : Colors.grey[700];

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 28,
        fontWeight: bold,
        color: baseColor,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 24,
        fontWeight: bold,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 20,
        fontWeight: semiBold,
        color: baseColor,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 16,
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 12,
        fontWeight: semiBold,
        color: baseColor,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 8,
        fontWeight: medium,
        color: baseColor,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 6,
        fontWeight: semiBold,
        color: baseColor,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 4,
        fontWeight: medium,
        color: baseColor,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize + 2,
        fontWeight: medium,
        color: baseColor,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: regular,
        color: baseColor,
        height: 1.3,
        letterSpacing: 0.2,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize - 1,
        fontWeight: regular,
        color: baseColor,
        height: 1.35,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize - 2,
        fontWeight: regular,
        color: secondaryColor,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize - 1,
        fontWeight: medium,
        color: baseColor,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize - 2,
        fontWeight: medium,
        color: baseColor,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize - 2,
        fontWeight: regular,
        color: secondaryColor,
        letterSpacing: 0.1,
      ),
    );
  }
}