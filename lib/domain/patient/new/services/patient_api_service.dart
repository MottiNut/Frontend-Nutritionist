// services/patient_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../patient_models.dart';

class PatientApiService {
  static const String _baseUrl = 'http://192.168.0.4:5000';
  static const String _endpoint = '/api/bff/patients';

  final http.Client _client;
  final String? _token;

  PatientApiService({http.Client? client, String? token})
      : _client = client ?? http.Client(),
        _token = token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Obtener todos los pacientes
  Future<List<PatientProfileDto>> getAllPatients({
    String chronicDisease = 'all',
    String sortBy = 'name',
    String order = 'asc',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint').replace(queryParameters: {
        'chronicDisease': chronicDisease,
        'sortBy': sortBy,
        'order': order,
      });

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => PatientProfileDto.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener pacientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener paciente por ID
  Future<PatientProfileDto> getPatientById(int patientId) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/$patientId');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return PatientProfileDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener paciente con historial
  Future<PatientWithHistoryDto> getPatientWithHistory(int patientId) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/$patientId/with-history');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return PatientWithHistoryDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener paciente con historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener historial médico del paciente
  Future<List<MedicalHistoryDto>> getPatientHistory(
      int patientId, {
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0];
      }

      final uri = Uri.parse('$_baseUrl$_endpoint/$patientId/history')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => MedicalHistoryDto.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Crear historial médico
  Future<MedicalHistoryDto> createMedicalHistory(
      int patientId,
      CreateMedicalHistoryRequest request,
      ) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/$patientId/history');
      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        return MedicalHistoryDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Actualizar historial médico
  Future<MedicalHistoryDto> updateMedicalHistory(
      int historyId,
      UpdateMedicalHistoryRequest request,
      ) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/history/$historyId');
      final response = await _client.put(
        uri,
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return MedicalHistoryDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar historial: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener filtros de enfermedades crónicas
  Future<List<ChronicDiseaseFilterDto>> getChronicDiseaseFilters() async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/chronic-diseases');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => ChronicDiseaseFilterDto.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener filtros: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener opciones de ordenamiento
  Future<PatientSortOptionsDto> getSortOptions() async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/sort-options');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return PatientSortOptionsDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener opciones de ordenamiento: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener resumen de salud del paciente
  Future<PatientHealthSummaryDto> getPatientHealthSummary(int patientId) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/$patientId/health-summary');
      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return PatientHealthSummaryDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener resumen de salud: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Obtener progreso del paciente
  Future<PatientProgressDto> getPatientProgress(int patientId, {int days = 30}) async {
    try {
      final uri = Uri.parse('$_baseUrl$_endpoint/$patientId/progress')
          .replace(queryParameters: {'days': days.toString()});

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return PatientProgressDto.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener progreso: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}