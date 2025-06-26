import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mottinutnutriotinist/configuration/providers/fontsize_app_screen.dart';
import 'package:provider/provider.dart';
import 'configuration/providers/app_theme_provider.dart';
import 'configuration/providers/speed_test_config.dart';
import 'configuration/routes/mottinut_nutriotinist_app_screen.dart';
import 'configuration/providers/color_dar_light_app.dart';
import 'domain/patient/app_state.dart';
import 'domain/patient/pruebaa.dart';
import 'domain/services/auth_provider.dart';

void main() async {
  // Configurar logging para development
  Logger.setLevel(LogLevel.debug);

  runApp(
      MultiBlocProvider(
        providers: [
          // Providers existentes
          ChangeNotifierProvider(create: (context) => DarkModeProvider()),
          ChangeNotifierProvider(create: (context) => FontSizeProvider()),
          ChangeNotifierProvider(create: (context) => NetworkProvider()),
          ChangeNotifierProvider(create: (context) => AppThemeProvider()),
          ChangeNotifierProvider(create: (context) => AppState()),
          ChangeNotifierProvider(create: (context) => AuthProvider()),
        ],
        child: MottiNutNutriotinistApp(),
      )
  );
}

