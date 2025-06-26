import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class AppColors {

  static const Color primary = Color(0xFF00ACB9);
  static const Color secondary = Color(0xFFFF6C00);

  //iconos
  static const Color iconPrimary = Color(0xFF9E9D9D);
  static const Color iconSecondary = Color(0xFFFFFFFF);
  static const Color iconDark = Color(0xFF000000);

  //barra de progress sing up
  static const Color progress = Color(0xFF6EEEB9);
  static const Color checkValidation = Color(0xFF08D510);

  //fondos
  static const Color backgroundplash= Color(0xFF5CE0E9);
  static const Color iconBackgroundLight = Color(0xFFFFF0E5);
  static const Color backgroundSuccess = Color(0xFF1E1E1E);
  static const Color backgroundtInput = Color(0xFFA09F9F);
  static const Color backgroundLigth = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);
  static const Color backgroundPrimary = Color(0xFF2C3E50);
  static const Color backgroundHomeCard= Color(0xFFAEAEAE);
  static const Color backgroundSecondary = Color(0xFF010E0E);
  static const Color backgroundIconNav = Color(0xFF12676D);
  static const Color backgroundDia = Color(0xFF00929D);
  //fondo de category
  static const Color backgroundDiabetes = Color(0xFFFFBC93);
  static const Color backgroundHipertencion = Color(0xFF00CEDC);
  static const Color backgroundDetail = Color(0xFF4CBFC7);
  static const Color backgroundObecidad = Color(0xFF679FD3);

  //text
  static const Color textPrimary = Color(0xFF565656);
  static const Color textPrimary1 = Color(0xFF525050);
  static const Color textSecondary = Color(0xFF1E1E1E);
  static const Color textTertiary = Color(0xFFFFFBFB);
  static const Color textCuatary = Color(0xFF757474);
  static const Color textQuintary = Color(0xFF64748B);
  static const Color textHome = Color(0xFF757474);
  static const Color textPrimaryHome = Color(0xFF12676D);
  static const Color textHomeLabel = Color(0xFF12676D);
  static const Color textTitleCateg = Color(0xFF007F88);
  static const Color textButNav= Colors.white54;
  static const Color textInput = Color(0xFFA09F9F);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textLDark = Color(0xFF000000);

  //text Error
  static const Color errorText = Color(0xFFFF006E);
  static const Color errorIcon = Color(0xFFF51406);

  // Colores de Superficie
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceAccent1 = Color(0xFFF8F4FF);
  static const Color surfaceAccent2 = Color(0xFFF0FBFF);
  static const Color surfaceAccent3 = Color(0xFFF0FFFF);

  // ========== GRADIENTES   ==========


  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF00D4E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, Color(0xFFFF8533)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente Primario + Secundario
  static const LinearGradient primarySecondaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradientes de Progreso
  static const LinearGradient progressGradient = LinearGradient(
    colors: [progress, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Gradientes de Fondo
  static const LinearGradient backgroundLightGradient = LinearGradient(
    colors: [backgroundLigth, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient backgroundDarkGradient = LinearGradient(
    colors: [backgroundDark, backgroundSuccess],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Gradientes para Iconos
  static const LinearGradient iconGradient = LinearGradient(
    colors: [iconPrimary, textCuatary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradientes de Superficie
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [surface, surfaceVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [surfaceAccent2, surfaceAccent3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradientes Suaves
  static const LinearGradient softPrimaryGradient = LinearGradient(
    colors: [
      Color(0xFF80D6DD), // primary más suave
      Color(0xFFB3E5EA), // aún más suave
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient softSecondaryGradient = LinearGradient(
    colors: [
      Color(0xFFFFB380), // secondary más suave
      Color(0xFFFFCCAD), // aún más suave
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Gradientes de Error
  static const LinearGradient errorGradient = LinearGradient(
    colors: [errorIcon, errorText],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradiente de Éxito (usando progress y primary)
  static const LinearGradient successGradient = LinearGradient(
    colors: [progress, Color(0xFF4FFFB3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradientes Radiales
  static const RadialGradient primaryRadialGradient = RadialGradient(
    colors: [primary, Color(0xFF80D6DD)],
    center: Alignment.center,
    radius: 0.8,
  );

  static const RadialGradient secondaryRadialGradient = RadialGradient(
    colors: [secondary, Color(0xFFFFB380)],
    center: Alignment.center,
    radius: 0.8,
  );

  // Métodos Utilitarios
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? backgroundPrimary : textLight;
  }

  // Método para crear gradientes personalizados con tus colores
  static LinearGradient createCustomGradient({
    required Color startColor,
    required Color endColor,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: [startColor, endColor],
      begin: begin,
      end: end,
    );
  }

  // Método para crear gradientes de 3 colores
  static LinearGradient createTripleGradient({
    required Color firstColor,
    required Color secondColor,
    required Color thirdColor,
    Alignment begin = Alignment.topCenter,
    Alignment end = Alignment.bottomCenter,
  }) {
    return LinearGradient(
      colors: [firstColor, secondColor, thirdColor],
      begin: begin,
      end: end,
      stops: const [0.0, 0.5, 1.0],
    );
  }
}