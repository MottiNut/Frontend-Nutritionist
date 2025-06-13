import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../infrastructure/config/api_config.dart';
import '../entity/patient.dart';
import '../enums/gender.dart';

class NutritionPlanService {
  final http.Client _client = http.Client();

  // Obtener planes de un paciente
  Future<List<NutritionPlan>> getPlansByPatient(String patientId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.plansByPatientUrl(patientId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => NutritionPlan.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener planes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Generar plan nutricional con IA
  Future<NutritionPlan> generateNutritionPlan({
    required String patientId,
    required String goal, // objetivo: "perder peso", "ganar masa muscular", etc.
    required int durationWeeks,
    required List<MealType> mealTypes,
    String? specialRequests,
  }) async {
    try {
      final requestData = {
        'patient_id': patientId,
        'goal': goal,
        'duration_weeks': durationWeeks,
        'meal_types': mealTypes.map((e) => e.apiValue).toList(),
        'special_requests': specialRequests,
      };

      final response = await _client.post(
        Uri.parse(ApiConfig.generatePlanUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 60)); // Más tiempo para IA

      if (response.statusCode == 201) {
        return NutritionPlan.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al generar plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Activar plan nutricional
  Future<NutritionPlan> activatePlan(String planId) async {
    try {
      final response = await _client.patch(
        Uri.parse('${ApiConfig.nutritionPlansUrl}/$planId/activate'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return NutritionPlan.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al activar plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}