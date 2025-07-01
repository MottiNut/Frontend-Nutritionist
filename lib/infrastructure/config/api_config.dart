
class ApiConfig {
  static const String baseUrl = 'https://www.mottinnut.com/api/v1';

  // Endpoints
  static const String patients = '/patients';
  static const String nutritionPlans = '/nutrition-plans';
  static const String generatePlan = '/nutrition-plans/generate';

  // Timeouts
  static const Duration timeout = Duration(seconds: 30);

  static String get patientsUrl => '$baseUrl$patients';
  static String get nutritionPlansUrl => '$baseUrl$nutritionPlans';
  static String get generatePlanUrl => '$baseUrl$generatePlan';

  static String patientByIdUrl(String id) => '$baseUrl$patients/$id';
  static String plansByPatientUrl(String patientId) => '$baseUrl$nutritionPlans/patient/$patientId';
}