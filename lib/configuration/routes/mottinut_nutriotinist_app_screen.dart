import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../../application/auth/sign_in/recover_password_screen.dart';
import '../../application/auth/sign_in/sign_in_screen.dart';
import '../../application/auth/sign_up/sign_up_screen.dart';
import '../../application/auth/sign_up/verification_code/code_verification_screen.dart';
import '../../application/onbording/ombording_screen.dart';
import '../../application/splash/splash_screen.dart';
import '../../domain/services/auth_provider.dart';
import '../providers/app_theme_provider.dart';
import '../providers/color_dar_light_app.dart';
import '../providers/fontsize_app_screen.dart';
import '../providers/speed_test_config.dart';
import '../themes/app_colors.dart';
import 'buttons_navigations.dart';

class MottiNutNutriotinistApp extends StatelessWidget {

  Widget build(BuildContext context) {
    return Consumer4<DarkModeProvider, FontSizeProvider, NetworkProvider, AppThemeProvider>(
      builder: (context, darkModeProvider, fontSizeProvider, networkProvider, appThemeProvider, child) {
        final isDarkMode = darkModeProvider.isDarkMode;
        final typography = AppTypography();

        // Configurar el estilo del sistema de manera más robusta
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: isDarkMode ? Colors.black : Colors.white,
            systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
            systemNavigationBarDividerColor: Colors.transparent,
          ),
        );

        // Configuraciones de orientación
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        return MaterialApp(
          title: 'MottiNut',
          debugShowCheckedModeBanner: false,

          // CONFIGURACIÓN DE LOCALIZACIÓN - AGREGADO
          locale: const Locale('es', 'ES'), // Español
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'), // Español
            Locale('en', 'US'), // Inglés (opcional)
          ],

          // Tema claro
          theme: _buildLightTheme(typography, fontSizeProvider),

          // Tema oscuro
          darkTheme: _buildDarkTheme(typography, fontSizeProvider),

          // Temas de alto contraste
          highContrastTheme: _buildHighContrastLightTheme(typography, fontSizeProvider),
          highContrastDarkTheme: _buildHighContrastDarkTheme(typography, fontSizeProvider),

          // Modo de tema
          themeMode: darkModeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Ruta inicial
          initialRoute: '/',

          // Rutas de navegación mejoradas
          routes: _buildRoutes(),

          // Generador de rutas para navegación dinámica
          onGenerateRoute: _generateRoute,

          // Página de error para rutas no encontradas
          onUnknownRoute: (settings) => MaterialPageRoute(
            builder: (context) => _buildErrorScreen(),
          ),
        );
      },
    );
  }

  // Construir tema claro
  ThemeData _buildLightTheme(AppTypography typography, FontSizeProvider fontSizeProvider) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      textTheme: typography.getTextTheme(
        fontSize: fontSizeProvider.fontSize,
        isDarkMode: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.secondary,
        selectionColor: AppColors.secondary.withOpacity(0.3),
        selectionHandleColor: AppColors.secondary,
      ),
    );
  }

  // Construir tema oscuro
  ThemeData _buildDarkTheme(AppTypography typography, FontSizeProvider fontSizeProvider) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      primarySwatch: Colors.cyan,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      textTheme: typography.getTextTheme(
        fontSize: fontSizeProvider.fontSize,
        isDarkMode: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade300),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withOpacity(0.3),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }

  // Tema de alto contraste claro
  ThemeData _buildHighContrastLightTheme(AppTypography typography, FontSizeProvider fontSizeProvider) {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      textTheme: typography.getTextTheme(
        fontSize: fontSizeProvider.fontSize * 1.2,
        isDarkMode: false,
      ),
    );
  }

  // Tema de alto contraste oscuro
  ThemeData _buildHighContrastDarkTheme(AppTypography typography, FontSizeProvider fontSizeProvider) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.black,
      textTheme: typography.getTextTheme(
        fontSize: fontSizeProvider.fontSize * 1.2,
        isDarkMode: true,
      ),
    );
  }

  // Construir rutas de navegación
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/': (context) => SplashScreen(),
      '/onboarding': (context) => OnboardingScreen(),
      '/login': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return SignInScreen(
          message: args?['message'],
          email: args?['email'],
        );
      },
      '/recover_password': (context) => RecoverPasswordScreen(),
      '/register': (context) => SignUpScreen(),
      //'/verification': (context) => CodeVerificationScreen(email: '', sms: '', whatsapcode: ''),
      '/button_navigation': (context) => const ButtonsNavigations(initialIndex: 0),
      '/button_navigation/novedades': (context) => const ButtonsNavigations(initialIndex: 1),
      '/button_navigation/chats': (context) => const ButtonsNavigations(initialIndex: 3),
      '/button_navigation/perfil': (context) => const ButtonsNavigations(initialIndex: 4),
      //'/search-rapida': (context) =>  SearchScreen(),
      //'/avisos': (context) =>  NotificationScreen(),
    };
  }

  VerificationMethod _parseVerificationMethod(String? value) {
    switch (value?.toLowerCase()) {
      case 'email':
        return VerificationMethod.email;
      case 'sms':
        return VerificationMethod.sms;
      case 'whatsapp':
        return VerificationMethod.whatsapp;
      default:
        return VerificationMethod.email; // o lanza una excepción si prefieres
    }
  }

  // Generador de rutas dinámicas
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/verification':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => CodeVerificationScreen(
            email: args?['email'] ?? '',
            phone: args?['phone'] ?? '',
            verificationMethod: _parseVerificationMethod(args?['verificationMethod']),
          ),
        );

      case '/home':
        final args = settings.arguments as Map<String, dynamic>?;
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ButtonsNavigations(
            initialIndex: args?['initialIndex'] ?? 0,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );

      default:
        return null;
    }
  }

  // Pantalla de error para rutas no encontradas
  Widget _buildErrorScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Página no encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('La página que buscas no existe.'),
          ],
        ),
      ),
    );
  }
}