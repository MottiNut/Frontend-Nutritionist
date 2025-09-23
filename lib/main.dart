import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mottinutnutriotinist/configuration/providers/fontsize_app_screen.dart';
import 'package:provider/provider.dart';
import 'package:mottinutnutriotinist/configuration/providers/app_languaje_provider.dart';
import 'package:mottinutnutriotinist/configuration/providers/app_theme_provider.dart';
import 'package:mottinutnutriotinist/configuration/providers/speed_test_config.dart';
import 'package:mottinutnutriotinist/configuration/routes/mottinut_nutriotinist_app_screen.dart';
import 'package:mottinutnutriotinist/configuration/providers/color_dar_light_app.dart';
import 'package:mottinutnutriotinist/domain/patient/app_state.dart';
import 'package:mottinutnutriotinist/domain/patient/pruebaa.dart';
import 'package:mottinutnutriotinist/domain/services/auth_provider.dart';
import 'domain/patient/new/providers/notification_provider.dart';
import 'domain/patient/new/rutadirectaaa/firebase_notification_handler.dart';
import 'domain/patient/new/rutadirectaaa/nutritionist_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Supongamos que obtienes el token desde algún lugar, p.ej. SharedPreferences o inicialización
  final String token = 'TU_TOKEN_AQUI';

  // Inicializa tu servicio de notificaciones con token
  final notificationService = NutritionistNotificationService(token);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DarkModeProvider()),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationService),
        ),
      ],
      child: MottiNutNutriotinistApp(),
    ),
  );
}


