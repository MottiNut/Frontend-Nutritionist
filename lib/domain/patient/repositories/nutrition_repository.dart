import '../entity/patient.dart';
import '../enums/gender.dart';
import '../services/nutrition_plan_service.dart';
import '../services/patient_services.dart';


class NutritionRepository {
  final PatientService _patientService = PatientService();
  final NutritionPlanService _planService = NutritionPlanService();

  // Pacientes
  Future<List<Patient>> getPatients() => _patientService.getPatients();
  Future<Patient> getPatientById(String id) => _patientService.getPatientById(id);
  Future<Patient> createPatient(Patient patient) => _patientService.createPatient(patient);
  Future<Patient> updatePatient(Patient patient) => _patientService.updatePatient(patient);
  Future<List<Patient>> searchPatients(String query) => _patientService.searchPatients(query);

  // Planes nutricionales
  Future<List<NutritionPlan>> getPlansByPatient(String patientId) =>
      _planService.getPlansByPatient(patientId);

  Future<NutritionPlan> generateNutritionPlan({
    required String patientId,
    required String goal,
    required int durationWeeks,
    required List<MealType> mealTypes,
    String? specialRequests,
  }) => _planService.generateNutritionPlan(
    patientId: patientId,
    goal: goal,
    durationWeeks: durationWeeks,
    mealTypes: mealTypes,
    specialRequests: specialRequests,
  );

  Future<NutritionPlan> activatePlan(String planId) => _planService.activatePlan(planId);
}