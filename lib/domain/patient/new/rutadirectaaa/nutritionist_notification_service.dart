import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';


class NutritionistNotificationService {
  final String token;

  NutritionistNotificationService(this.token);

  // Enviar acción del paciente al backend
  Future<bool> sendPatientAction({
    required String patientId,
    required String nutritionistId,
    required int planId,
    required String patientName,
    required String actionType,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.patientPlanAction()}'),
        headers: ApiConstants.getHeaders(token),
        body: json.encode({
          'patientId': patientId,
          'nutritionistId': nutritionistId,
          'planId': planId,
          'patientName': patientName,
          'actionType': actionType,
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending patient action: $e');
      return false;
    }
  }

  // Registrar device token para push notifications
  Future<bool> registerDeviceToken(String deviceToken, String platform) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deviceToken}'),
        headers: ApiConstants.getHeaders(token),
        body: json.encode({
          'deviceToken': deviceToken,
          'platform': platform,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error registering device token: $e');
      return false;
    }
  }

  // Obtener historial de notificaciones
  Future<List<dynamic>> getNotificationHistory({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationHistory}?limit=$limit'),
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  // Notificar nuevo paciente asignado
  Future<bool> notifyNewPatient(String nutritionistId, String patientName) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.newPatientNotification()}?nutritionistId=$nutritionistId&patientName=$patientName'),
        headers: ApiConstants.getHeaders(token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error notifying new patient: $e');
      return false;
    }
  }
}