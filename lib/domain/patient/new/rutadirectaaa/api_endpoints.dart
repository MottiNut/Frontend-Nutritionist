// lib/config/constants.dart
class ApiConstants {
  // Configuración base
  static const String baseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net';
  static const String apiVersion = '/api/bff';

  // Headers por defecto
  static Map<String, String> getHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // ================ ENDPOINTS DE PACIENTES ================

  // Gestión de pacientes
  static const String patients = '$apiVersion/patients';
  static String patientById(int id) => '$apiVersion/patients/$id';
  static String patientWithHistory(int id) => '$apiVersion/patients/$id/with-history';
  static const String chronicDiseases = '$apiVersion/patients/chronic-diseases';
  static String patientProfileImage(int userId) => '$apiVersion/auth/profile/patient/$userId/image';

  // Historial médico
  static String patientHistory(int patientId) => '$apiVersion/patients/$patientId/history';
  static String updateHistory(int historyId) => '$apiVersion/patients/history/$historyId';

  // Resumen de salud
  static String patientHealthSummary(int patientId) => '$apiVersion/patients/$patientId/health-summary';
  static String patientProgress(int patientId) => '$apiVersion/patients/$patientId/progress';

  // ================ ENDPOINTS DE PLANES NUTRICIONALES ================

  static const String generatePlan = '$apiVersion/nutritionist/nutrition-plans/generate';
  static const String pendingPlans = '$apiVersion/nutritionist/nutrition-plans/pending';
  static String planDetails(int planId) => '$apiVersion/nutritionist/nutrition-plans/$planId';
  static String reviewPlan(int planId) => '$apiVersion/nutritionist/nutrition-plans/$planId/review';
  static String editPlan(int planId) => '$apiVersion/nutritionist/nutrition-plans/$planId/edit';
  static const String rejectedByPatientPlans = '$apiVersion/nutritionist/nutrition-plans/rejected-by-patient';
}

