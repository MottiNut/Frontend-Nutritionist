import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../application/views/home/notificactions/notification_screen.dart';
import 'api_endpoints.dart';

class NutritionistService {

  static final Map<int, Uint8List> _imageCache = HashMap<int, Uint8List>();

  Future<List<PatientProfile>> getAllPatients({
    String? chronicDisease,
    String sortBy = 'fullName',
    String order = 'asc',
    required String token,
  }) async {
    final queryParams = <String, String>{
      'sortBy': sortBy,
      'order': order,
    };

    if (chronicDisease != null && chronicDisease.isNotEmpty) {
      queryParams['chronicDisease'] = chronicDisease;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PatientProfile.fromJson(json)).toList();
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      throw Exception('Error al obtener pacientes: $e');
    }
  }

  /// Obtiene un paciente específico por ID
  Future<PatientProfile> getPatientById(int patientId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientById(patientId)}'),
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        return PatientProfile.fromJson(json.decode(response.body));
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      throw Exception('Error al obtener paciente: $e');
    }
  }

  /// Obtiene un paciente con su historial médico
  Future<PatientWithHistory> getPatientWithHistory(int patientId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientWithHistory(patientId)}'),
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return PatientWithHistory.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener paciente con historial: ${response.body}');
    }
  }

  /// Obtiene las enfermedades crónicas para filtros
  Future<List<ChronicDiseaseFilter>> getChronicDiseaseFilters(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chronicDiseases}'),
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ChronicDiseaseFilter.fromJson(json)).toList();
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      throw Exception('Error al obtener enfermedades crónicas: $e');
    }
  }

  /// Obtiene imagen de perfil del paciente
  Future<Uint8List?> getPatientProfileImage(int userId, String token) async {
    // Verificar caché primero
    if (_imageCache.containsKey(userId)) {
      return _imageCache[userId];
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientProfileImage(userId)}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;
        // Guardar en caché
        _imageCache[userId] = imageData;
        return imageData;
      } else if (response.statusCode == 404) {
        return null; // No tiene imagen
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      // Log del error pero no lanzar excepción para mantener UX
      print('Error al obtener imagen del paciente $userId: $e');
      return null;
    }
  }
  /// Limpia el caché de imágenes
  static void clearImageCache() {
    _imageCache.clear();
  }

  /// Remueve una imagen específica del caché
  static void removeFromImageCache(int userId) {
    _imageCache.remove(userId);
  }
  // ================ HISTORIAL MÉDICO ================

  /// Obtiene el historial médico de un paciente
  Future<List<MedicalHistory>> getPatientHistory(
      int patientId,
      String token, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientHistory(patientId)}')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(
      uri,
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => MedicalHistory.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener historial: ${response.body}');
    }
  }

  /// Crea un nuevo registro de historial médico
  Future<MedicalHistory> createMedicalHistory(
      int patientId,
      CreateMedicalHistoryRequest request,
      String token,
      ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientHistory(patientId)}'),
      headers: ApiConstants.getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 201) {
      return MedicalHistory.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al crear historial: ${response.body}');
    }
  }

  /// Actualiza un registro de historial médico
  Future<MedicalHistory> updateMedicalHistory(
      int historyId,
      UpdateMedicalHistoryRequest request,
      String token,
      ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateHistory(historyId)}'),
      headers: ApiConstants.getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return MedicalHistory.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al actualizar historial: ${response.body}');
    }
  }

  // ================ RESÚMENES Y PROGRESO ================

  /// Obtiene el resumen de salud del paciente
  Future<PatientHealthSummary> getPatientHealthSummary(int patientId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientHealthSummary(patientId)}'),
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return PatientHealthSummary.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener resumen de salud: ${response.body}');
    }
  }

  /// Obtiene el progreso del paciente
  Future<PatientProgress> getPatientProgress(
      int patientId,
      String token, {
        int days = 30,
      }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientProgress(patientId)}')
        .replace(queryParameters: {'days': days.toString()});

    final response = await http.get(
      uri,
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return PatientProgress.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener progreso: ${response.body}');
    }
  }

  // ================ PLANES NUTRICIONALES ================

  /// Genera un nuevo plan nutricional usando IA
  Future<NutritionPlanResponse> generatePlan(
      GeneratePlanRequest request,
      String token,
      ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.generatePlan}'),
      headers: ApiConstants.getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return NutritionPlanResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al generar plan: ${response.body}');
    }
  }

  /// Obtiene los planes pendientes de revisión
  Future<List<PendingPlanResponse>> getPendingPlans(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.pendingPlans}'),
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PendingPlanResponse.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener planes pendientes: ${response.body}');
    }
  }

  /// Obtiene los detalles de un plan específico
  Future<DetailedNutritionPlan> getPlanDetails(int planId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.planDetails(planId)}'),
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return DetailedNutritionPlan.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener detalles del plan: ${response.body}');
    }
  }

  /// Revisa y aprueba/rechaza un plan
  Future<NutritionPlanResponse> reviewPlan(
      int planId,
      ReviewPlanRequest request,
      String token,
      ) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviewPlan(planId)}'),
      headers: ApiConstants.getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return NutritionPlanResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al revisar plan: ${response.body}');
    }
  }

  /// Edita un plan nutricional existente
  Future<NutritionPlanResponse> editPlan(
      int planId,
      EditPlanRequest request,
      String token,
      ) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.editPlan(planId)}'),
      headers: ApiConstants.getHeaders(token),
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return NutritionPlanResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al editar plan: ${response.body}');
    }
  }

  /// Obtiene los planes rechazados por pacientes
  Future<List<RejectedByPatient>> getRejectedByPatientPlans(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rejectedByPatientPlans}'),
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => RejectedByPatient.fromJson(json)).toList();
    } else {
      throw Exception('Error al obtener planes rechazados: ${response.body}');
    }
  }

  // ================ MÉTODOS DE UTILIDAD ================

  /// Maneja errores HTTP comunes
  String _handleHttpError(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida: $body';
      case 401:
        return 'No autorizado. Inicie sesión nuevamente.';
      case 403:
        return 'No tiene permisos para realizar esta acción.';
      case 404:
        return 'Recurso no encontrado.';
      case 500:
        return 'Error interno del servidor.';
      default:
        return 'Error desconocido: $body';
    }
  }
}
// ================ ENTIDADES DE PLANS NUTRICIONALES ================
class NutritionPlanResponse {
  final int planId;
  final int patientId;
  final String patientName;
  final int nutritionistId;
  final String nutritionistName;
  final String weekStartDate;
  final int energyRequirement;
  final String goal;
  final String specialRequirements;
  final Map<String, dynamic> planContent;
  final String status;
  final String? reviewNotes;
  final String createdAt;
  final String? reviewedAt;

  NutritionPlanResponse({
    required this.planId,
    required this.patientId,
    required this.patientName,
    required this.nutritionistId,
    required this.nutritionistName,
    required this.weekStartDate,
    required this.energyRequirement,
    required this.goal,
    required this.specialRequirements,
    required this.planContent,
    required this.status,
    this.reviewNotes,
    required this.createdAt,
    this.reviewedAt,
  });

  factory NutritionPlanResponse.fromJson(Map<String, dynamic> json) {
    return NutritionPlanResponse(
      planId: json['planId'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      nutritionistId: json['nutritionistId'],
      nutritionistName: json['nutritionistName'],
      weekStartDate: json['weekStartDate'],
      energyRequirement: json['energyRequirement'],
      goal: json['goal'],
      specialRequirements: json['specialRequirements'],
      planContent: Map<String, dynamic>.from(json['planContent'] ?? {}),
      status: json['status'],
      reviewNotes: json['reviewNotes'],
      createdAt: json['createdAt'],
      reviewedAt: json['reviewedAt'],
    );
  }
}
class PendingPlanResponse {
  final int planId;
  final int patientId;
  final String patientName;
  final String weekStartDate;
  final int energyRequirement;
  final String goal;
  final String specialRequirements;
  final String createdAt;

  PendingPlanResponse({
    required this.planId,
    required this.patientId,
    required this.patientName,
    required this.weekStartDate,
    required this.energyRequirement,
    required this.goal,
    required this.specialRequirements,
    required this.createdAt,
  });

  factory PendingPlanResponse.fromJson(Map<String, dynamic> json) {
    return PendingPlanResponse(
      planId: json['planId'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      weekStartDate: json['weekStartDate'],
      energyRequirement: json['energyRequirement'],
      goal: json['goal'],
      specialRequirements: json['specialRequirements'],
      createdAt: json['createdAt'],
    );
  }
}
class DetailedNutritionPlan {
  final int planId;
  final int patientId;
  final String patientName;
  final int nutritionistId;
  final String nutritionistName;
  final String weekStartDate;
  final int energyRequirement;
  final String goal;
  final String specialRequirements;
  final Map<String, dynamic> planContent;
  final String status;
  final String? reviewNotes;
  final String? patientFeedback;
  final String createdAt;
  final String? reviewedAt;
  final String? patientResponseAt;

  DetailedNutritionPlan({
    required this.planId,
    required this.patientId,
    required this.patientName,
    required this.nutritionistId,
    required this.nutritionistName,
    required this.weekStartDate,
    required this.energyRequirement,
    required this.goal,
    required this.specialRequirements,
    required this.planContent,
    required this.status,
    this.reviewNotes,
    this.patientFeedback,
    required this.createdAt,
    this.reviewedAt,
    this.patientResponseAt,
  });

  factory DetailedNutritionPlan.fromJson(Map<String, dynamic> json) {
    return DetailedNutritionPlan(
      planId: json['planId'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      nutritionistId: json['nutritionistId'],
      nutritionistName: json['nutritionistName'],
      weekStartDate: json['weekStartDate'],
      energyRequirement: json['energyRequirement'],
      goal: json['goal'],
      specialRequirements: json['specialRequirements'],
      planContent: Map<String, dynamic>.from(json['planContent'] ?? {}),
      status: json['status'],
      reviewNotes: json['reviewNotes'],
      patientFeedback: json['patientFeedback'],
      createdAt: json['createdAt'],
      reviewedAt: json['reviewedAt'],
      patientResponseAt: json['patientResponseAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'patientId': patientId,
      'patientName': patientName,
      'nutritionistId': nutritionistId,
      'nutritionistName': nutritionistName,
      'weekStartDate': weekStartDate,
      'energyRequirement': energyRequirement,
      'goal': goal,
      'specialRequirements': specialRequirements,
      'planContent': planContent,
      'status': status,
      'reviewNotes': reviewNotes,
      'patientFeedback': patientFeedback,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
      'patientResponseAt': patientResponseAt,
    };
  }

  // Método para verificar si el plan está completo
  bool get isComplete {
    return planContent.isNotEmpty && status != 'PENDING';
  }

  // Método para obtener el número de días del plan
  int get daysCount {
    if (planContent.containsKey('days')) {
      return (planContent['days'] as List?)?.length ?? 0;
    }
    return 0;
  }

  // Método para obtener las comidas de un día específico
  List<Map<String, dynamic>> getMealsForDay(int dayIndex) {
    if (planContent.containsKey('days') &&
        planContent['days'] is List &&
        dayIndex < (planContent['days'] as List).length) {
      final day = planContent['days'][dayIndex];
      if (day is Map && day.containsKey('meals')) {
        return List<Map<String, dynamic>>.from(day['meals'] ?? []);
      }
    }
    return [];
  }

  // Método para obtener información nutricional del día
  Map<String, dynamic>? getNutritionInfoForDay(int dayIndex) {
    if (planContent.containsKey('days') &&
        planContent['days'] is List &&
        dayIndex < (planContent['days'] as List).length) {
      final day = planContent['days'][dayIndex];
      if (day is Map && day.containsKey('nutrition_summary')) {
        return Map<String, dynamic>.from(day['nutrition_summary'] ?? {});
      }
    }
    return null;
  }

  // Método para verificar si el plan requiere revisión
  bool get requiresReview {
    return status == 'PENDING_REVIEW' || status == 'NEEDS_REVISION';
  }

  // Método para verificar si el plan está aprobado
  bool get isApproved {
    return status == 'APPROVED' || status == 'ACTIVE';
  }

  // Copia del objeto con cambios
  DetailedNutritionPlan copyWith({
    int? planId,
    int? patientId,
    String? patientName,
    int? nutritionistId,
    String? nutritionistName,
    String? weekStartDate,
    int? energyRequirement,
    String? goal,
    String? specialRequirements,
    Map<String, dynamic>? planContent,
    String? status,
    String? reviewNotes,
    String? patientFeedback,
    String? createdAt,
    String? reviewedAt,
    String? patientResponseAt,
  }) {
    return DetailedNutritionPlan(
      planId: planId ?? this.planId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      nutritionistId: nutritionistId ?? this.nutritionistId,
      nutritionistName: nutritionistName ?? this.nutritionistName,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      energyRequirement: energyRequirement ?? this.energyRequirement,
      goal: goal ?? this.goal,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      planContent: planContent ?? this.planContent,
      status: status ?? this.status,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      patientFeedback: patientFeedback ?? this.patientFeedback,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      patientResponseAt: patientResponseAt ?? this.patientResponseAt,
    );
  }
}
class RejectedByPatient {
  final int planId;
  final int patientId;
  final String patientName;
  final String weekStartDate;
  final int energyRequirement;
  final String goal;
  final String patientFeedback;
  final String patientResponseAt;

  RejectedByPatient({
    required this.planId,
    required this.patientId,
    required this.patientName,
    required this.weekStartDate,
    required this.energyRequirement,
    required this.goal,
    required this.patientFeedback,
    required this.patientResponseAt,
  });

  factory RejectedByPatient.fromJson(Map<String, dynamic> json) {
    return RejectedByPatient(
      planId: json['planId'],
      patientId: json['patientId'],
      patientName: json['patientName'],
      weekStartDate: json['weekStartDate'],
      energyRequirement: json['energyRequirement'],
      goal: json['goal'],
      patientFeedback: json['patientFeedback'],
      patientResponseAt: json['patientResponseAt'],
    );
  }
}
// ================ REQUEST MODELS ================
class CreateMedicalHistoryRequest {
  final DateTime consultationDate;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? bodyFatPercentage;
  final double? bloodGlucose;
  final double? waterConsumption;
  final double? caloricIntake;
  final String? bloodPressure;
  final String? lipidProfile;
  final String? eatingHabits;
  final String? supplementation;
  final String? macronutrients;
  final String? foodPreferences;
  final String? foodRelationship;
  final String? nutritionalObjectives;
  final String? patientEvolution;
  final String? professionalNotes;
  final int? heartRate;
  final int? stressLevel;
  final int? sleepQuality;

  CreateMedicalHistoryRequest({
    required this.consultationDate,
    this.waistCircumference,
    this.hipCircumference,
    this.bodyFatPercentage,
    this.bloodGlucose,
    this.waterConsumption,
    this.caloricIntake,
    this.bloodPressure,
    this.lipidProfile,
    this.eatingHabits,
    this.supplementation,
    this.macronutrients,
    this.foodPreferences,
    this.foodRelationship,
    this.nutritionalObjectives,
    this.patientEvolution,
    this.professionalNotes,
    this.heartRate,
    this.stressLevel,
    this.sleepQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      'consultationDate': consultationDate.toIso8601String().split('T')[0],
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'bodyFatPercentage': bodyFatPercentage,
      'bloodGlucose': bloodGlucose,
      'waterConsumption': waterConsumption,
      'caloricIntake': caloricIntake,
      'bloodPressure': bloodPressure,
      'lipidProfile': lipidProfile,
      'eatingHabits': eatingHabits,
      'supplementation': supplementation,
      'macronutrients': macronutrients,
      'foodPreferences': foodPreferences,
      'foodRelationship': foodRelationship,
      'nutritionalObjectives': nutritionalObjectives,
      'patientEvolution': patientEvolution,
      'professionalNotes': professionalNotes,
      'heartRate': heartRate,
      'stressLevel': stressLevel,
      'sleepQuality': sleepQuality,
    };
  }
}
class UpdateMedicalHistoryRequest extends CreateMedicalHistoryRequest {
  UpdateMedicalHistoryRequest({
    required DateTime consultationDate,
    double? waistCircumference,
    double? hipCircumference,
    double? bodyFatPercentage,
    double? bloodGlucose,
    double? waterConsumption,
    double? caloricIntake,
    String? bloodPressure,
    String? lipidProfile,
    String? eatingHabits,
    String? supplementation,
    String? macronutrients,
    String? foodPreferences,
    String? foodRelationship,
    String? nutritionalObjectives,
    String? patientEvolution,
    String? professionalNotes,
    int? heartRate,
    int? stressLevel,
    int? sleepQuality,
  }) : super(
    consultationDate: consultationDate,
    waistCircumference: waistCircumference,
    hipCircumference: hipCircumference,
    bodyFatPercentage: bodyFatPercentage,
    bloodGlucose: bloodGlucose,
    waterConsumption: waterConsumption,
    caloricIntake: caloricIntake,
    bloodPressure: bloodPressure,
    lipidProfile: lipidProfile,
    eatingHabits: eatingHabits,
    supplementation: supplementation,
    macronutrients: macronutrients,
    foodPreferences: foodPreferences,
    foodRelationship: foodRelationship,
    nutritionalObjectives: nutritionalObjectives,
    patientEvolution: patientEvolution,
    professionalNotes: professionalNotes,
    heartRate: heartRate,
    stressLevel: stressLevel,
    sleepQuality: sleepQuality,
  );
}
class GeneratePlanRequest {
  final int patientId;
  final String weekStartDate;
  final int energyRequirement;
  final String goal;
  final String specialRequirements;
  final int mealsPerDay;

  GeneratePlanRequest({
    required this.patientId,
    required this.weekStartDate,
    required this.energyRequirement,
    required this.goal,
    required this.specialRequirements,
    required this.mealsPerDay,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientUserId': patientId,
      'weekStartDate': weekStartDate,
      'energyRequirement': energyRequirement,
      'goal': goal,
      'specialRequirements': specialRequirements,
      'mealsPerDay': mealsPerDay,
    };
  }
}
class ReviewPlanRequest {
  final String action; // "approve" or "reject"
  final String? reviewNotes;

  ReviewPlanRequest({
    required this.action,
    this.reviewNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'reviewNotes': reviewNotes,
    };
  }
}
class EditPlanRequest {
  final Map<String, dynamic> planContent;
  final String reviewNotes;

  EditPlanRequest({
    required this.planContent,
    required this.reviewNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'planContent': planContent,
      'reviewNotes': reviewNotes,
    };
  }
}


// ================ MODELOS DE DATOS ================
class PatientProfile {
  final int patientId;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? phone;
  final String? chronicDisease;
  final String? allergies;
  final String? dietaryPreferences;
  final String? emergencyContact;
  final DateTime? birthDate;
  final int? age;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? bmiCategory;
  final bool? hasMedicalCondition;
  final String? gender;
  final DateTime createdAt;

  PatientProfile({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.phone,
    this.chronicDisease,
    this.allergies,
    this.dietaryPreferences,
    this.emergencyContact,
    this.birthDate,
    this.age,
    this.height,
    this.weight,
    this.bmi,
    this.bmiCategory,
    this.hasMedicalCondition,
    this.gender,
    required this.createdAt,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    try {
      return PatientProfile(
        // Campos requeridos con validación null safety
        patientId: json['patientId'] ?? 0,
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',

        // Campos opcionales con manejo seguro de null
        phone: json['phone']?.toString(),
        chronicDisease: json['chronicDisease']?.toString(),
        allergies: json['allergies']?.toString(),
        dietaryPreferences: json['dietaryPreferences']?.toString(),
        emergencyContact: json['emergencyContact']?.toString(),

        // Fechas con manejo de errores
        birthDate: _parseDateTime(json['birthDate']),
        createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),

        // Números con conversión segura
        age: _parseInt(json['age']),
        height: _parseDouble(json['height']),
        weight: _parseDouble(json['weight']),
        bmi: _parseDouble(json['bmi']),

        // Strings opcionales
        bmiCategory: json['bmiCategory']?.toString(),
        gender: json['gender']?.toString(),

        // Boolean con valor por defecto
        hasMedicalCondition: _parseBool(json['hasMedicalCondition']),
      );
    } catch (e) {
      print('❌ Error al parsear PatientProfile: $e');
      print('📋 JSON recibido: $json');
      rethrow;
    }
  }

  // Métodos auxiliares para parsing seguro
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      print('⚠️ Error parsing DateTime: $value');
      return null;
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    try {
      return int.parse(value.toString());
    } catch (e) {
      print('⚠️ Error parsing int: $value');
      return null;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value.toString());
    } catch (e) {
      print('⚠️ Error parsing double: $value');
      return null;
    }
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return null;
  }
}
class PatientWithHistory {
  final PatientProfile patient;
  final List<MedicalHistory> medicalHistories;
  final MedicalHistory? latestHistory;
  final int totalHistories;

  PatientWithHistory({
    required this.patient,
    required this.medicalHistories,
    this.latestHistory,
    required this.totalHistories,
  });

  factory PatientWithHistory.fromJson(Map<String, dynamic> json) {
    return PatientWithHistory(
      patient: PatientProfile.fromJson(json['patient']),
      medicalHistories: (json['medicalHistories'] as List<dynamic>)
          .map((item) => MedicalHistory.fromJson(item))
          .toList(),
      latestHistory: json['latestHistory'] != null
          ? MedicalHistory.fromJson(json['latestHistory'])
          : null,
      totalHistories: json['totalHistories'],
    );
  }
}
class MedicalHistory {
  final int historyId;
  final int patientId;
  final DateTime consultationDate;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? bodyFatPercentage;
  final double? bloodGlucose;
  final double? waterConsumption;
  final double? caloricIntake;
  final String? bloodPressure;
  final String? lipidProfile;
  final String? eatingHabits;
  final String? supplementation;
  final String? macronutrients;
  final String? foodPreferences;
  final String? foodRelationship;
  final String? nutritionalObjectives;
  final String? patientEvolution;
  final String? professionalNotes;
  final int? heartRate;
  final int? stressLevel;
  final int? sleepQuality;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? waistHipRatio;

  MedicalHistory({
    required this.historyId,
    required this.patientId,
    required this.consultationDate,
    this.waistCircumference,
    this.hipCircumference,
    this.bodyFatPercentage,
    this.bloodGlucose,
    this.waterConsumption,
    this.caloricIntake,
    this.bloodPressure,
    this.lipidProfile,
    this.eatingHabits,
    this.supplementation,
    this.macronutrients,
    this.foodPreferences,
    this.foodRelationship,
    this.nutritionalObjectives,
    this.patientEvolution,
    this.professionalNotes,
    this.heartRate,
    this.stressLevel,
    this.sleepQuality,
    required this.createdAt,
    required this.updatedAt,
    this.waistHipRatio,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      historyId: json['historyId'],
      patientId: json['patientId'],
      consultationDate: DateTime.parse(json['consultationDate']),
      waistCircumference: json['waistCircumference']?.toDouble(),
      hipCircumference: json['hipCircumference']?.toDouble(),
      bodyFatPercentage: json['bodyFatPercentage']?.toDouble(),
      bloodGlucose: json['bloodGlucose']?.toDouble(),
      waterConsumption: json['waterConsumption']?.toDouble(),
      caloricIntake: json['caloricIntake']?.toDouble(),
      bloodPressure: json['bloodPressure'],
      lipidProfile: json['lipidProfile'],
      eatingHabits: json['eatingHabits'],
      supplementation: json['supplementation'],
      macronutrients: json['macronutrients'],
      foodPreferences: json['foodPreferences'],
      foodRelationship: json['foodRelationship'],
      nutritionalObjectives: json['nutritionalObjectives'],
      patientEvolution: json['patientEvolution'],
      professionalNotes: json['professionalNotes'],
      heartRate: json['heartRate'],
      stressLevel: json['stressLevel'],
      sleepQuality: json['sleepQuality'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      waistHipRatio: json['waistHipRatio']?.toDouble(),
    );
  }
}
class ChronicDiseaseFilter {
  final String code;
  final String description;

  ChronicDiseaseFilter({
    required this.code,
    required this.description,
  });

  factory ChronicDiseaseFilter.fromJson(Map<String, dynamic> json) {
    return ChronicDiseaseFilter(
      code: json['code'],
      description: json['description'],
    );
  }
}
class PatientHealthSummary {
  final int patientId;
  final String fullName;
  final int? age;
  final double? bmi;
  final String? bmiCategory;
  final bool? hasMedicalCondition;
  final String? chronicDisease;
  final String? gender;
  final DateTime? lastConsultationDate;
  final String? bloodPressure;
  final double? bloodGlucose;
  final int? stressLevel;
  final int? sleepQuality;
  final double? waistHipRatio;
  final int totalConsultations;

  PatientHealthSummary({
    required this.patientId,
    required this.fullName,
    this.age,
    this.bmi,
    this.bmiCategory,
    this.hasMedicalCondition,
    this.chronicDisease,
    this.gender,
    this.lastConsultationDate,
    this.bloodPressure,
    this.bloodGlucose,
    this.stressLevel,
    this.sleepQuality,
    this.waistHipRatio,
    required this.totalConsultations,
  });

  factory PatientHealthSummary.fromJson(Map<String, dynamic> json) {
    return PatientHealthSummary(
      patientId: json['patientId'],
      fullName: json['fullName'],
      age: json['age'],
      bmi: json['bmi']?.toDouble(),
      bmiCategory: json['bmiCategory'],
      hasMedicalCondition: json['hasMedicalCondition'],
      chronicDisease: json['chronicDisease'],
      gender: json['gender'],
      lastConsultationDate: json['lastConsultationDate'] != null
          ? DateTime.parse(json['lastConsultationDate'])
          : null,
      bloodPressure: json['bloodPressure'],
      bloodGlucose: json['bloodGlucose']?.toDouble(),
      stressLevel: json['stressLevel'],
      sleepQuality: json['sleepQuality'],
      waistHipRatio: json['waistHipRatio']?.toDouble(),
      totalConsultations: json['totalConsultations'],
    );
  }
}
class PatientProgress {
  final int periodDays;
  final int totalConsultations;
  final double? bodyFatChange;
  final double? waistCircumferenceChange;
  final double? averageSleepQuality;
  final double? averageStressLevel;

  PatientProgress({
    required this.periodDays,
    required this.totalConsultations,
    this.bodyFatChange,
    this.waistCircumferenceChange,
    this.averageSleepQuality,
    this.averageStressLevel,
  });

  factory PatientProgress.fromJson(Map<String, dynamic> json) {
    return PatientProgress(
      periodDays: json['periodDays'],
      totalConsultations: json['totalConsultations'],
      bodyFatChange: json['bodyFatChange']?.toDouble(),
      waistCircumferenceChange: json['waistCircumferenceChange']?.toDouble(),
      averageSleepQuality: json['averageSleepQuality']?.toDouble(),
      averageStressLevel: json['averageStressLevel']?.toDouble(),
    );
  }
}
// ================ SERVICIO DE DETECCIÓN DE URGENCIAS ================
enum UrgencyLevel {
  critical,
  high,
  medium,
  low,
}
enum UrgencyReason {
  criticalGlucose,           // Glucosa crítica
  severeHypertension,        // Hipertensión severa
  extremeBMI,               // IMC extremo
  chronicDiseaseDeterioration, // Deterioro enfermedad crónica
  noRecentConsultation,     // Sin consulta reciente
  planRejectedMultipleTimes, // Plan rechazado múltiples veces
  newPatientWithConditions, // Paciente nuevo con condiciones
  followUpRequired,         // Seguimiento requerido
}
class PatientUrgency {
  final int patientId;
  final PatientProfile? patient;
  final String patientName;
  final UrgencyLevel urgencyLevel;
  final List<UrgencyReason> reasons;
  final String description;
  final DateTime detectedAt;
  final int daysSinceLastConsultation;
  final DateTime? lastConsultationDate;
  final DateTime? nextPlanDueDate;
  final Map<String, dynamic> criticalValues;
  final bool requiresImmediateAction;

  PatientUrgency({
    required this.patientId,
    this.patient,
    required this.patientName,
    required this.urgencyLevel,
    required this.reasons,
    required this.description,
    required this.detectedAt,
    required this.daysSinceLastConsultation,
    this.lastConsultationDate,
    this.nextPlanDueDate,
    required this.criticalValues,
    required this.requiresImmediateAction,
  });

  // Getters útiles
  bool get isCritical => urgencyLevel == UrgencyLevel.critical;
  bool get isHigh => urgencyLevel == UrgencyLevel.high;
  bool get needsNewPlan => nextPlanDueDate != null && DateTime.now().isAfter(nextPlanDueDate!);

  String get urgencyIcon {
    switch (urgencyLevel) {
      case UrgencyLevel.critical:
        return '🚨';
      case UrgencyLevel.high:
        return '⚠️';
      case UrgencyLevel.medium:
        return '⚡';
      case UrgencyLevel.low:
        return '📋';
    }
  }

  String get urgencyColor {
    switch (urgencyLevel) {
      case UrgencyLevel.critical:
        return '#FF0000'; // Rojo
      case UrgencyLevel.high:
        return '#FF8C00'; // Naranja
      case UrgencyLevel.medium:
        return '#FFD700'; // Amarillo
      case UrgencyLevel.low:
        return '#32CD32'; // Verde
    }
  }

  String get urgencyText {
    switch (urgencyLevel) {
      case UrgencyLevel.critical:
        return 'CRÍTICO';
      case UrgencyLevel.high:
        return 'ALTA';
      case UrgencyLevel.medium:
        return 'MEDIA';
      case UrgencyLevel.low:
        return 'BAJA';
    }
  }
}
class PatientUrgencyDetector {

  static PatientUrgency analyzePatientUrgency(
      PatientProfile patient,
      MedicalHistory? latestHistory,
      List<MedicalHistory> allHistories,
      List<RejectedByPatient>? rejectedPlans,
      ) {
    final urgencyReasons = <UrgencyReason>[];
    final criticalValues = <String, dynamic>{};
    var urgencyLevel = UrgencyLevel.low;
    var description = '';

    final now = DateTime.now();
    final daysSinceLastConsultation = latestHistory != null
        ? now.difference(latestHistory.consultationDate).inDays
        : 9999;

    // 1. ANÁLISIS DE VALORES CRÍTICOS EN HISTORIAL RECIENTE (últimos 3 días)
    final recentHistories = allHistories.where((h) =>
    now.difference(h.consultationDate).inDays <= 3
    ).toList();

    for (final history in recentHistories) {
      // Glucosa crítica
      if (history.bloodGlucose != null) {
        final glucose = history.bloodGlucose!;
        if (glucose > 250 || glucose < 70) {
          urgencyReasons.add(UrgencyReason.criticalGlucose);
          criticalValues['glucose'] = glucose;
          urgencyLevel = UrgencyLevel.critical;
        } else if (glucose > 180 || glucose < 80) {
          urgencyReasons.add(UrgencyReason.criticalGlucose);
          criticalValues['glucose'] = glucose;
          if (urgencyLevel.index < UrgencyLevel.high.index) {
            urgencyLevel = UrgencyLevel.high;
          }
        }
      }

      // Presión arterial severa
      if (history.bloodPressure != null) {
        final bp = history.bloodPressure!;
        if (bp.contains('180') || bp.contains('110') ||
            bp.contains('90/60') || bp.contains('80/50')) {
          urgencyReasons.add(UrgencyReason.severeHypertension);
          criticalValues['bloodPressure'] = bp;
          urgencyLevel = UrgencyLevel.critical;
        }
      }

      // Estrés nivel crítico
      if (history.stressLevel != null && history.stressLevel! >= 9) {
        criticalValues['stressLevel'] = history.stressLevel;
        if (urgencyLevel.index < UrgencyLevel.high.index) {
          urgencyLevel = UrgencyLevel.high;
        }
      }

      // Calidad de sueño crítica
      if (history.sleepQuality != null && history.sleepQuality! <= 2) {
        criticalValues['sleepQuality'] = history.sleepQuality;
        if (urgencyLevel.index < UrgencyLevel.medium.index) {
          urgencyLevel = UrgencyLevel.medium;
        }
      }
    }

    // 2. ANÁLISIS DE IMC EXTREMO
    if (patient.bmi != null) {
      final bmi = patient.bmi!;
      if (bmi >= 40 || bmi <= 16) {
        urgencyReasons.add(UrgencyReason.extremeBMI);
        criticalValues['bmi'] = bmi;
        if (urgencyLevel.index < UrgencyLevel.high.index) {
          urgencyLevel = UrgencyLevel.high;
        }
      } else if (bmi >= 35 || bmi <= 18.5) {
        urgencyReasons.add(UrgencyReason.extremeBMI);
        criticalValues['bmi'] = bmi;
        if (urgencyLevel.index < UrgencyLevel.medium.index) {
          urgencyLevel = UrgencyLevel.medium;
        }
      }
    }

    // 3. ENFERMEDADES CRÓNICAS GRAVES
    if (patient.chronicDisease != null) {
      final disease = patient.chronicDisease!.toLowerCase();
      if (disease.contains('diabetes') || disease.contains('hipertension') ||
          disease.contains('cardio') || disease.contains('renal')) {
        urgencyReasons.add(UrgencyReason.chronicDiseaseDeterioration);
        if (urgencyLevel.index < UrgencyLevel.medium.index) {
          urgencyLevel = UrgencyLevel.medium;
        }
      }
    }

    // 4. TIEMPO SIN CONSULTA
    if (daysSinceLastConsultation > 30) {
      urgencyReasons.add(UrgencyReason.noRecentConsultation);
      if (urgencyLevel.index < UrgencyLevel.medium.index) {
        urgencyLevel = UrgencyLevel.medium;
      }
    } else if (daysSinceLastConsultation > 14) {
      urgencyReasons.add(UrgencyReason.followUpRequired);
      if (urgencyLevel.index < UrgencyLevel.low.index) {
        urgencyLevel = UrgencyLevel.low;
      }
    }

    // 5. PLANES RECHAZADOS MÚLTIPLES VECES
    if (rejectedPlans != null && rejectedPlans.length >= 2) {
      urgencyReasons.add(UrgencyReason.planRejectedMultipleTimes);
      if (urgencyLevel.index < UrgencyLevel.high.index) {
        urgencyLevel = UrgencyLevel.high;
      }
    }

    // 6. PACIENTE NUEVO CON CONDICIONES
    if (allHistories.isEmpty && patient.hasMedicalCondition == true) {
      urgencyReasons.add(UrgencyReason.newPatientWithConditions);
      if (urgencyLevel.index < UrgencyLevel.medium.index) {
        urgencyLevel = UrgencyLevel.medium;
      }
    }

    // 7. DETERMINAR SI NECESITA NUEVO PLAN (después de 7 días del último historial)
    DateTime? nextPlanDueDate;
    if (latestHistory != null) {
      nextPlanDueDate = latestHistory.consultationDate.add(const Duration(days: 7));
      if (now.isAfter(nextPlanDueDate)) {
        urgencyReasons.add(UrgencyReason.followUpRequired);
        if (urgencyLevel.index < UrgencyLevel.medium.index) {
          urgencyLevel = UrgencyLevel.medium;
        }
      }
    }

    // GENERAR DESCRIPCIÓN
    description = _generateDescription(urgencyReasons, criticalValues, daysSinceLastConsultation);

    return PatientUrgency(
      patientId: patient.patientId,
      patientName: patient.fullName,
      urgencyLevel: urgencyLevel,
      reasons: urgencyReasons,
      description: description,
      detectedAt: now,
      daysSinceLastConsultation: daysSinceLastConsultation,
      lastConsultationDate: latestHistory?.consultationDate,
      nextPlanDueDate: nextPlanDueDate,
      criticalValues: criticalValues,
      requiresImmediateAction: urgencyLevel == UrgencyLevel.critical,
    );
  }

  static String _generateDescription(
      List<UrgencyReason> reasons,
      Map<String, dynamic> values,
      int daysSinceConsultation
      ) {
    final descriptions = <String>[];

    if (reasons.contains(UrgencyReason.criticalGlucose)) {
      final glucose = values['glucose'];
      descriptions.add('Glucosa en nivel crítico: ${glucose}mg/dL');
    }

    if (reasons.contains(UrgencyReason.severeHypertension)) {
      final bp = values['bloodPressure'];
      descriptions.add('Presión arterial severa: $bp');
    }

    if (reasons.contains(UrgencyReason.extremeBMI)) {
      final bmi = values['bmi'];
      descriptions.add('IMC extremo: ${bmi.toStringAsFixed(1)}');
    }

    if (reasons.contains(UrgencyReason.chronicDiseaseDeterioration)) {
      descriptions.add('Requiere monitoreo por enfermedad crónica');
    }

    if (reasons.contains(UrgencyReason.noRecentConsultation)) {
      descriptions.add('Sin consulta hace $daysSinceConsultation días');
    }

    if (reasons.contains(UrgencyReason.planRejectedMultipleTimes)) {
      descriptions.add('Ha rechazado múltiples planes nutricionales');
    }

    if (reasons.contains(UrgencyReason.newPatientWithConditions)) {
      descriptions.add('Paciente nuevo con condiciones médicas');
    }

    if (reasons.contains(UrgencyReason.followUpRequired)) {
      descriptions.add('Requiere seguimiento nutricional');
    }

    return descriptions.isEmpty ? 'Paciente estable' : descriptions.join('. ');
  }

  // Método para obtener todos los pacientes con urgencia
  static List<PatientUrgency> detectUrgencies(
      List<PatientProfile> patients,
      Map<int, List<MedicalHistory>> patientsHistories,
      Map<int, List<RejectedByPatient>> rejectedPlansMap,
      ) {
    final urgencies = <PatientUrgency>[];

    for (final patient in patients) {
      final histories = patientsHistories[patient.patientId] ?? [];
      final latestHistory = histories.isNotEmpty ? histories.first : null;
      final rejectedPlans = rejectedPlansMap[patient.patientId];

      final urgency = analyzePatientUrgency(
          patient,
          latestHistory,
          histories,
          rejectedPlans
      );

      urgencies.add(urgency);
    }

    // Ordenar por prioridad: crítico > alto > medio > bajo
    urgencies.sort((a, b) {
      if (a.urgencyLevel != b.urgencyLevel) {
        return a.urgencyLevel.index.compareTo(b.urgencyLevel.index);
      }
      // Si tienen la misma urgencia, ordenar por días sin consulta (más días = más urgente)
      return b.daysSinceLastConsultation.compareTo(a.daysSinceLastConsultation);
    });

    return urgencies;
  }
}
extension NutritionistServiceUrgency on NutritionistService {

  /// Obtiene pacientes con análisis de urgencia
  Future<List<PatientUrgency>> getPatientsWithUrgency({
    String? chronicDisease,
    UrgencyLevel? minUrgencyLevel,
    required String token,
  }) async {
    try {
      // Obtener todos los pacientes
      final patients = await getAllPatients(
        chronicDisease: chronicDisease,
        sortBy: 'fullName',
        order: 'asc',
        token: token,
      );

      // Obtener historiales para cada paciente
      final patientsHistories = <int, List<MedicalHistory>>{};
      final rejectedPlansMap = <int, List<RejectedByPatient>>{};

      // Obtener planes rechazados
      final allRejectedPlans = await getRejectedByPatientPlans(token);
      for (final plan in allRejectedPlans) {
        rejectedPlansMap.putIfAbsent(plan.patientId, () => []).add(plan);
      }

      // Obtener historiales médicos
      for (final patient in patients) {
        try {
          final histories = await getPatientHistory(patient.patientId, token);
          // Ordenar por fecha más reciente primero
          histories.sort((a, b) => b.consultationDate.compareTo(a.consultationDate));
          patientsHistories[patient.patientId] = histories;
        } catch (e) {
          print('Error obteniendo historial del paciente ${patient.patientId}: $e');
          patientsHistories[patient.patientId] = [];
        }
      }

      // Detectar urgencias
      var urgencies = PatientUrgencyDetector.detectUrgencies(
        patients,
        patientsHistories,
        rejectedPlansMap,
      );

      // Filtrar por nivel mínimo de urgencia si se especifica
      if (minUrgencyLevel != null) {
        urgencies = urgencies.where((u) =>
        u.urgencyLevel.index <= minUrgencyLevel.index
        ).toList();
      }

      return urgencies;
    } catch (e) {
      throw Exception('Error al obtener pacientes con urgencia: $e');
    }
  }

  /// Obtiene solo pacientes críticos y de alta prioridad
  Future<List<PatientUrgency>> getUrgentPatients(String token) async {
    return await getPatientsWithUrgency(
      minUrgencyLevel: UrgencyLevel.high,
      token: token,
    );
  }

  List<PatientProfile> _filterUrgentPatients(List<PatientProfile> patients, int limit) {
    final now = DateTime.now();
    final urgentThreshold = now.subtract(const Duration(hours: 72));

    final urgentPatients = patients.where((patient) {
      bool hasUrgentCondition = patient.hasMedicalCondition == true;

      if (patient.chronicDisease != null) {
        final criticalDiseases = [
          'diabetes',
          'hipertension',
          'obesidad'
        ];

        hasUrgentCondition = hasUrgentCondition || criticalDiseases.any((disease) =>
            patient.chronicDisease!.toLowerCase().contains(disease.toLowerCase()));
      }

      if (patient.bmi != null) {
        // BMI < 16 (severamente bajo peso) o BMI > 40 (obesidad mórbida)
        if (patient.bmi! < 16.0 || patient.bmi! > 40.0) {
          hasUrgentCondition = true;
        }
      }

      final isNewPatient = patient.createdAt.isAfter(
          now.subtract(const Duration(days: 7)));

      return hasUrgentCondition || isNewPatient;
    }).toList();

    // Ordenar por prioridad de urgencia
    urgentPatients.sort((a, b) {
      // Calcular score de urgencia para cada paciente
      int getUrgencyScore(PatientProfile patient) {
        int score = 0;

        // BMI crítico = máxima prioridad
        if (patient.bmi != null && (patient.bmi! < 16.0 || patient.bmi! > 40.0)) {
          score += 100;
        }

        // Condiciones médicas
        if (patient.hasMedicalCondition == true) {
          score += 50;
        }

        // Enfermedades crónicas específicas
        if (patient.chronicDisease != null) {
          if (patient.chronicDisease!.toLowerCase().contains('diabetes')) {
            score += 80;
          } else if (patient.chronicDisease!.toLowerCase().contains('hipertensión')) {
            score += 70;
          } else if (patient.chronicDisease!.toLowerCase().contains('cardíaca')) {
            score += 90;
          }
        }

        // Pacientes nuevos
        final daysSinceCreation = now.difference(patient.createdAt).inDays;
        if (daysSinceCreation <= 7) {
          score += 30;
        }

        return score;
      }

      return getUrgencyScore(b).compareTo(getUrgencyScore(a));
    });

    return urgentPatients.take(limit).toList();
  }

  /// Obtiene estadísticas de urgencias
  Future<Map<String, int>> getUrgencyStats(String token) async {
    final urgencies = await getPatientsWithUrgency(token: token);

    final stats = <String, int>{
      'critical': 0,
      'high': 0,
      'medium': 0,
      'low': 0,
      'needNewPlan': 0,
      'noRecentConsultation': 0,
    };

    for (final urgency in urgencies) {
      switch (urgency.urgencyLevel) {
        case UrgencyLevel.critical:
          stats['critical'] = stats['critical']! + 1;
          break;
        case UrgencyLevel.high:
          stats['high'] = stats['high']! + 1;
          break;
        case UrgencyLevel.medium:
          stats['medium'] = stats['medium']! + 1;
          break;
        case UrgencyLevel.low:
          stats['low'] = stats['low']! + 1;
          break;
      }

      if (urgency.needsNewPlan) {
        stats['needNewPlan'] = stats['needNewPlan']! + 1;
      }

      if (urgency.daysSinceLastConsultation > 14) {
        stats['noRecentConsultation'] = stats['noRecentConsultation']! + 1;
      }
    }

    return stats;
  }
}
// Clases auxiliares
class UrgencyConfig {
  final Color color;
  final IconData icon;
  final String text;
  final bool pulse;

  UrgencyConfig({
    required this.color,
    required this.icon,
    required this.text,
    required this.pulse,
  });
}
enum ContactMethod { phone, whatsapp }

// NotificationItem

class NotificationItems {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? patientName;
  final String? patientAvatar;
  final int? patientId;
  final int? planId;
  final int? appointmentId;
  final String? actionUrl;
  final Map<String, dynamic>? extraData;

  NotificationItems({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.patientName,
    this.patientAvatar,
    this.patientId,
    this.planId,
    this.appointmentId,
    this.actionUrl,
    this.extraData,
  });

  factory NotificationItems.fromJson(Map<String, dynamic> json) {
    return NotificationItems(
      id: json['id']?.toString() ?? '',
      type: _getNotificationTypeFromString(json['type'] ?? 'reminder'),
      title: json['title'] ?? 'Nueva notificación',
      message: json['message'] ?? json['body'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? json['read'] ?? false,
      patientName: json['patient_name'],
      patientAvatar: json['patient_avatar'],
      patientId: json['patient_id'] != null ? int.tryParse(json['patient_id'].toString()) : null,
      planId: json['plan_id'] != null ? int.tryParse(json['plan_id'].toString()) : null,
      appointmentId: json['appointment_id'] != null ? int.tryParse(json['appointment_id'].toString()) : null,
      actionUrl: json['action_url'],
      extraData: json['extra_data'] ?? json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'patient_name': patientName,
      'patient_avatar': patientAvatar,
      'patient_id': patientId,
      'plan_id': planId,
      'appointment_id': appointmentId,
      'action_url': actionUrl,
      'extra_data': extraData,
    };
  }

  static NotificationType _getNotificationTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'new_patient':
      case 'patient_registered':
        return NotificationType.newPatient;
      case 'new_appointment':
      case 'appointment_scheduled':
        return NotificationType.newAppointment;
      case 'plan_update':
      case 'plan_accepted':
      case 'plan_rejected':
      case 'plan_created':
        return NotificationType.planUpdate;
      case 'chat_message':
      case 'new_message':
        return NotificationType.chatMessage;
      case 'app_update':
      case 'system_update':
        return NotificationType.appUpdate;
      case 'reminder':
      case 'appointment_reminder':
      default:
        return NotificationType.reminder;
    }
  }

  // Métodos de conveniencia
  bool get isPatientRelated => patientId != null;
  bool get isPlanRelated => planId != null;
  bool get isAppointmentRelated => appointmentId != null;

  String get displayPatientName => patientName ?? 'Paciente desconocido';

  // Crear notificaciones de prueba para desarrollo
  static NotificationItems createNewPatientNotification({
    required String patientName,
    required int patientId,
    String? patientAvatar,
  }) {
    return NotificationItems(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.newPatient,
      title: 'Nuevo paciente registrado',
      message: '$patientName se ha registrado en la plataforma',
      timestamp: DateTime.now(),
      isRead: false,
      patientName: patientName,
      patientId: patientId,
      patientAvatar: patientAvatar,
      extraData: {
        'action': 'view_patient',
        'patient_id': patientId,
      },
    );
  }

  static NotificationItems createPlanAcceptedNotification({
    required String patientName,
    required int patientId,
    required int planId,
    String? patientAvatar,
  }) {
    return NotificationItems(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.planUpdate,
      title: 'Plan nutricional aceptado',
      message: '$patientName ha aceptado su plan nutricional',
      timestamp: DateTime.now(),
      isRead: false,
      patientName: patientName,
      patientId: patientId,
      planId: planId,
      patientAvatar: patientAvatar,
      extraData: {
        'action': 'view_plan',
        'plan_id': planId,
        'patient_id': patientId,
        'status': 'accepted',
      },
    );
  }

  static NotificationItems createPlanRejectedNotification({
    required String patientName,
    required int patientId,
    required int planId,
    String? reason,
    String? patientAvatar,
  }) {
    return NotificationItems(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.planUpdate,
      title: 'Plan nutricional rechazado',
      message: '$patientName ha rechazado su plan nutricional${reason != null ? ': $reason' : ''}',
      timestamp: DateTime.now(),
      isRead: false,
      patientName: patientName,
      patientId: patientId,
      planId: planId,
      patientAvatar: patientAvatar,
      extraData: {
        'action': 'view_rejected_plan',
        'plan_id': planId,
        'patient_id': patientId,
        'status': 'rejected',
        'reason': reason,
      },
    );
  }
}

// Extensión para trabajar con listas de notificaciones
extension NotificationListExtension on List<NotificationItems> {
  List<NotificationItems> get unreadNotifications => where((n) => !n.isRead).toList();

  int get unreadCount => unreadNotifications.length;

  List<NotificationItems> filterByType(NotificationType type) {
    return where((n) => n.type == type).toList();
  }

  List<NotificationItems> filterByPatient(int patientId) {
    return where((n) => n.patientId == patientId).toList();
  }

  List<NotificationItems> sortByTimestamp({bool descending = true}) {
    final sorted = List<NotificationItems>.from(this);
    sorted.sort((a, b) => descending
        ? b.timestamp.compareTo(a.timestamp)
        : a.timestamp.compareTo(b.timestamp));
    return sorted;
  }
}
