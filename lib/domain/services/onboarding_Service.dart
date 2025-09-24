import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingSeenKey = 'onboarding_seen';

  // Verificar si el usuario ya vio el onboarding
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingSeenKey) ?? false;
    } catch (e) {
      // En caso de error, mostrar onboarding por seguridad
      return false;
    }
  }

  // Marcar que el usuario ya vio el onboarding
  static Future<void> setOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingSeenKey, true);
    } catch (e) {
      // Manejar error silenciosamente
      print('Error saving onboarding status: $e');
    }
  }

  // Método para resetear (útil para testing o configuraciones)
  static Future<void> resetOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingSeenKey);
    } catch (e) {
      print('Error resetting onboarding status: $e');
    }
  }
}