import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../infrastructure/config/api_config.dart';
import '../entity/patient.dart';

class PatientService {
  final http.Client _client = http.Client();

  // Obtener todos los pacientes
  Future<List<Patient>> getPatients() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.patientsUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener pacientes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener paciente por ID
  Future<Patient> getPatientById(String id) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConfig.patientByIdUrl(id)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Patient.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al obtener paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Crear nuevo paciente
  Future<Patient> createPatient(Patient patient) async {
    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.patientsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(patient.toJson()),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201) {
        return Patient.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al crear paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Actualizar paciente
  Future<Patient> updatePatient(Patient patient) async {
    try {
      final response = await _client.put(
        Uri.parse(ApiConfig.patientByIdUrl(patient.id)),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(patient.toJson()),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        return Patient.fromJson(json.decode(response.body));
      } else {
        throw Exception('Error al actualizar paciente: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Buscar pacientes por nombre o DNI
  Future<List<Patient>> searchPatients(String query) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.patientsUrl}/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Patient.fromJson(json)).toList();
      } else {
        throw Exception('Error en búsqueda: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}