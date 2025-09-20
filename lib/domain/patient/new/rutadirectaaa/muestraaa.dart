import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';

class PatientPlanStats {
  final int totalPlans;
  final int approvedPlans;
  final int rejectedPlans;
  final int pendingPlans;
  final int activePlans;
  final String? lastPlanDate;
  final double? averageEnergyRequirement;
  final Map<String, int> goalDistribution;

  PatientPlanStats({
    required this.totalPlans,
    required this.approvedPlans,
    required this.rejectedPlans,
    required this.pendingPlans,
    required this.activePlans,
    this.lastPlanDate,
    this.averageEnergyRequirement,
    required this.goalDistribution,
  });

  factory PatientPlanStats.fromJson(Map<String, dynamic> json) {
    return PatientPlanStats(
      totalPlans: json['totalPlans'] ?? 0,
      approvedPlans: json['approvedPlans'] ?? 0,
      rejectedPlans: json['rejectedPlans'] ?? 0,
      pendingPlans: json['pendingPlans'] ?? 0,
      activePlans: json['activePlans'] ?? 0,
      lastPlanDate: json['lastPlanDate'],
      averageEnergyRequirement: json['averageEnergyRequirement']?.toDouble(),
      goalDistribution: Map<String, int>.from(json['goalDistribution'] ?? {}),
    );
  }
}
class NutritionistService {
  static final Map<int, Uint8List> _imageCache = HashMap<int, Uint8List>();

  Future<List<PatientProfile>> getDiabetesPatients({
    String sortBy = 'fullName',
    String order = 'asc',
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{
        'sortBy': sortBy,
        'order': order,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}')
          .replace(queryParameters: queryParams);

      print('🔍 Cargando pacientes con diabetes...');

      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allPatients = data.map((json) => PatientProfile.fromJson(json)).toList();

        print('📊 Total de pacientes obtenidos: ${allPatients.length}');

        // Filtrado ESPECÍFICO para diabetes únicamente
        final diabetesPatients = allPatients.where((p) {
          if (p.chronicDisease == null ||
              p.chronicDisease!.trim().isEmpty ||
              p.chronicDisease!.toLowerCase().trim() == 'ninguna') {
            return false;
          }

          final disease = p.chronicDisease!.toLowerCase().trim();

          // Solo diabetes, sin otras enfermedades
          bool isDiabetes = disease.contains('diabetes') ||
              disease.contains('diabético') ||
              disease.contains('diabética') ||
              disease.contains('diabetico') ||
              disease.contains('diabetica');

          // Excluir si también tiene otras enfermedades
          bool hasOtherDiseases = disease.contains('hipertensión') ||
              disease.contains('hipertension') ||
              disease.contains('obesidad') ||
              disease.contains('obeso') ||
              disease.contains('obesa') ||
              disease.contains('sobrepeso');

          return isDiabetes && !hasOtherDiseases;
        }).toList();

        print('🩺 Pacientes SOLO con diabetes encontrados: ${diabetesPatients.length}');

        return diabetesPatients;
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      print('❌ Error al cargar pacientes con diabetes: $e');
      throw Exception('Error al obtener pacientes con diabetes: $e');
    }
  }

  /// Obtiene un paciente específico por ID
  Future<PatientProfile> getPatientById(int patientId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.patientById(patientId)}'),
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
  Future<PatientWithHistory> getPatientWithHistory(
      int patientId, String token) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.patientWithHistory(patientId)}'),
      headers: ApiConstants.getHeaders(token),
    );

    if (response.statusCode == 200) {
      return PatientWithHistory.fromJson(json.decode(response.body));
    } else {
      throw Exception(
          'Error al obtener paciente con historial: ${response.body}');
    }
  }

  /// Obtiene las enfermedades crónicas para filtros
  Future<List<ChronicDiseaseFilter>> getChronicDiseaseFilters(
      String token) async {
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
        Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.patientProfileImage(userId)}'),
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

  // pacientes con hipertensión
  Future<List<PatientProfile>> getHypertensionPatients({
    String sortBy = 'fullName',
    String order = 'asc',
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{
        'sortBy': sortBy,
        'order': order,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}')
          .replace(queryParameters: queryParams);

      print('🔍 Cargando pacientes con hipertensión...');

      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allPatients =
            data.map((json) => PatientProfile.fromJson(json)).toList();

        print('📊 Total de pacientes obtenidos: ${allPatients.length}');

        // Filtrado ESPECÍFICO para hipertensión únicamente
        final hypertensionPatients = allPatients.where((p) {
          if (p.chronicDisease == null ||
              p.chronicDisease!.trim().isEmpty ||
              p.chronicDisease!.toLowerCase().trim() == 'ninguna') {
            return false;
          }

          final disease = p.chronicDisease!.toLowerCase().trim();

          // Solo hipertensión
          bool isHypertension = disease.contains('hipertensión') ||
              disease.contains('hipertension') ||
              disease.contains('hipertensión arterial') ||
              disease.contains('hipertension arterial') ||
              (disease.contains('presión') && disease.contains('alta')) ||
              (disease.contains('presion') && disease.contains('alta'));

          // Excluir si también tiene otras enfermedades
          bool hasOtherDiseases = disease.contains('diabetes') ||
              disease.contains('diabético') ||
              disease.contains('diabética') ||
              disease.contains('obesidad') ||
              disease.contains('obeso') ||
              disease.contains('obesa') ||
              disease.contains('sobrepeso');

          return isHypertension && !hasOtherDiseases;
        }).toList();

        print(
            '🩺 Pacientes SOLO con hipertensión encontrados: ${hypertensionPatients.length}');

        return hypertensionPatients;
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      print('❌ Error al cargar pacientes con hipertensión: $e');
      throw Exception('Error al obtener pacientes con hipertensión: $e');
    }
  }

  // Obtiene todos los pacientes con obesidad o sobrepeso
  Future<List<PatientProfile>> getObesityPatients({
    String sortBy = 'fullName',
    String order = 'asc',
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{
        'sortBy': sortBy,
        'order': order,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}')
          .replace(queryParameters: queryParams);

      print('🔍 Cargando pacientes con obesidad/sobrepeso...');

      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allPatients =
            data.map((json) => PatientProfile.fromJson(json)).toList();

        print('📊 Total de pacientes obtenidos: ${allPatients.length}');

        // Filtrado ESPECÍFICO para obesidad únicamente
        final obesityPatients = allPatients.where((p) {
          // Filtrar por enfermedad crónica SOLO
          bool hasObesityDisease = false;
          if (p.chronicDisease != null &&
              p.chronicDisease!.trim().isNotEmpty &&
              p.chronicDisease!.toLowerCase().trim() != 'ninguna') {
            final disease = p.chronicDisease!.toLowerCase().trim();

            // Solo obesidad/sobrepeso
            hasObesityDisease = disease.contains('obesidad') ||
                disease.contains('obeso') ||
                disease.contains('obesa') ||
                disease.contains('sobrepeso') ||
                disease.contains('sobre peso');

            // Excluir si también tiene otras enfermedades
            bool hasOtherDiseases = disease.contains('diabetes') ||
                disease.contains('diabético') ||
                disease.contains('diabética') ||
                disease.contains('hipertensión') ||
                disease.contains('hipertension');

            hasObesityDisease = hasObesityDisease && !hasOtherDiseases;
          }

          // Para pacientes sin enfermedad específica, filtrar por IMC
          bool hasHighBMI = false;
          if (!hasObesityDisease &&
              (p.chronicDisease == null ||
                  p.chronicDisease!.trim().isEmpty ||
                  p.chronicDisease!.toLowerCase().trim() == 'ninguna')) {
            if (p.bmi != null && p.bmi! >= 25.0) {
              hasHighBMI = true;
            }

            // O por categoría de IMC
            if (p.bmiCategory != null) {
              final category = p.bmiCategory!.toLowerCase();
              hasHighBMI = hasHighBMI ||
                  category.contains('sobrepeso') ||
                  category.contains('obesidad') ||
                  category.contains('obeso') ||
                  category.contains('obesa');
            }
          }

          return hasObesityDisease || hasHighBMI;
        }).toList();

        print(
            '⚖️ Pacientes SOLO con obesidad/sobrepeso encontrados: ${obesityPatients.length}');

        return obesityPatients;
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      print('❌ Error al cargar pacientes con obesidad/sobrepeso: $e');
      throw Exception('Error al obtener pacientes con obesidad/sobrepeso: $e');
    }
  }

//  múltiples enfermedades
  Future<List<PatientProfile>> getMultipleDiseasePatients({
    String sortBy = 'fullName',
    String order = 'asc',
    required String token,
  }) async {
    try {
      final queryParams = <String, String>{
        'sortBy': sortBy,
        'order': order,
      };

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patients}')
          .replace(queryParameters: queryParams);

      print('🔍 Cargando pacientes con múltiples enfermedades...');

      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allPatients =
            data.map((json) => PatientProfile.fromJson(json)).toList();

        // Filtrado para pacientes con más de una enfermedad
        final multipleDiseasesPatients = allPatients.where((p) {
          if (p.chronicDisease == null ||
              p.chronicDisease!.trim().isEmpty ||
              p.chronicDisease!.toLowerCase().trim() == 'ninguna') {
            return false;
          }

          final disease = p.chronicDisease!.toLowerCase().trim();
          int diseaseCount = 0;

          if (disease.contains('diabetes') ||
              disease.contains('diabético') ||
              disease.contains('diabética')) {
            diseaseCount++;
          }
          if (disease.contains('hipertensión') ||
              disease.contains('hipertension')) {
            diseaseCount++;
          }
          if (disease.contains('obesidad') ||
              disease.contains('obeso') ||
              disease.contains('obesa') ||
              disease.contains('sobrepeso')) {
            diseaseCount++;
          }

          return diseaseCount > 1;
        }).toList();

        print(
            '🩺 Pacientes con múltiples enfermedades encontrados: ${multipleDiseasesPatients.length}');

        return multipleDiseasesPatients;
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      print('❌ Error al cargar pacientes con múltiples enfermedades: $e');
      throw Exception(
          'Error al obtener pacientes con múltiples enfermedades: $e');
    }
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

    final uri = Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.patientHistory(patientId)}')
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
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.patientHistory(patientId)}'),
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
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.updateHistory(historyId)}'),
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
  Future<PatientHealthSummary> getPatientHealthSummary(
      int patientId, String token) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.patientHealthSummary(patientId)}'),
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
    final uri = Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.patientProgress(patientId)}')
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

  /// Obtiene el historial completo de planes nutricionales de un paciente
  Future<List<NutritionPlanResponse>> getPatientNutritionHistory(
      int patientId,
      String token, {
        String? status, // Filtrar por estado específico
        DateTime? startDate,
        DateTime? endDate,
        int? limit,
      }) async {
    try {
      final queryParams = <String, String>{};

      if (status != null) queryParams['status'] = status;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientNutritionHistory(patientId)}')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      print('🔍 Cargando historial de planes para paciente $patientId...');

      final response = await http.get(
        uri,
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final plans = data.map((json) => NutritionPlanResponse.fromJson(json)).toList();

        // Ordenar por fecha de creación (más reciente primero)
        plans.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));

        print('📋 Planes encontrados: ${plans.length}');
        return plans;
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      print('❌ Error al cargar historial de planes: $e');
      throw Exception('Error al obtener historial de planes: $e');
    }
  }

  /// Obtiene estadísticas del historial de planes del paciente
  Future<PatientPlanStats> getPatientPlanStats(int patientId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientPlanStats(patientId)}'),
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        return PatientPlanStats.fromJson(json.decode(response.body));
      } else {
        throw _handleHttpError(response.statusCode, response.body);
      }
    } catch (e) {
      print('❌ Error al cargar estadísticas de planes: $e');
      throw Exception('Error al obtener estadísticas de planes: $e');
    }
  }

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
  Future<List<RejectedByPatient>> getRejectedByPatientPlans(
      String token) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.rejectedByPatientPlans}'),
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
  final String? reviewNotes;
  final bool planContentValid;

  EditPlanRequest({
    required this.planContent,
    this.reviewNotes,
    required this.planContentValid,
  });

  Map<String, dynamic> toJson() {
    return {
      'planContent': planContent,
      'reviewNotes': reviewNotes,
      'planContentValid': planContentValid,
    };
  }

  factory EditPlanRequest.fromJson(Map<String, dynamic> json) {
    return EditPlanRequest(
      planContent: json['planContent'] ?? {},
      reviewNotes: json['reviewNotes'],
      planContentValid: json['planContentValid'] ?? true,
    );
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
