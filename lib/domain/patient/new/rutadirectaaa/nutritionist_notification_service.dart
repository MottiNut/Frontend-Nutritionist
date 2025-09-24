import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_endpoints.dart';

class NutritionistNotificationService {
  final String token;

  NutritionistNotificationService(this.token);

  /// Enviar acción del paciente al backend
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

      if (response.statusCode == 200) {
        debugPrint('✅ Acción de paciente enviada correctamente');
        return true;
      } else {
        debugPrint('⚠️ Error en sendPatientAction: ${response.statusCode} → ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Excepción en sendPatientAction: $e');
      return false;
    }
  }

  /// Inicializar notificaciones
  Future<void> initialize() async {
    try {
      await _setupLocalNotifications();
      await _requestPermissions();
      await _setupMessageHandlers();
      await _cleanupInvalidTokens();
      await _getToken(); // opcional, para debug
    } catch (e) {
      debugPrint('❌ Error inicializando NutritionistNotificationService: $e');
    }
  }

  /// Limpiar tokens inválidos
  Future<void> _cleanupInvalidTokens() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
      debugPrint('🧹 Tokens antiguos eliminados');
    } catch (e) {
      debugPrint('⚠️ Error limpiando tokens: $e');
    }
  }

  /// Obtener token de FCM
  Future<void> _getToken() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        debugPrint('✅ FCM Token obtenido (${token.length} chars)');
        debugPrint('🔑 Token preview: ${token.substring(0, math.min(50, token.length))}...');
      } else {
        debugPrint('⚠️ No se pudo obtener el FCM token');
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo FCM token: $e');
    }
  }

  /// Registrar device token para push notifications
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

      if (response.statusCode == 201) {
        debugPrint('✅ Device token registrado correctamente');
        return true;
      } else {
        debugPrint('⚠️ Error registrando device token: ${response.statusCode} → ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Excepción en registerDeviceToken: $e');
      return false;
    }
  }

  /// Obtener historial de notificaciones
  Future<List<dynamic>> getNotificationHistory({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.notificationHistory}?limit=$limit'),
        headers: ApiConstants.getHeaders(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        debugPrint('⚠️ Error en getNotificationHistory: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Excepción en getNotificationHistory: $e');
      return [];
    }
  }

  /// Notificar nuevo paciente asignado
  Future<bool> notifyNewPatient(String nutritionistId, String patientName) async {
    try {
      final uri = Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.newPatientNotification()}'
            '?nutritionistId=$nutritionistId&patientName=$patientName',
      );

      final response = await http.post(uri, headers: ApiConstants.getHeaders(token));

      if (response.statusCode == 200) {
        debugPrint('✅ Notificación de nuevo paciente enviada');
        return true;
      } else {
        debugPrint('⚠️ Error en notifyNewPatient: ${response.statusCode} → ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Excepción en notifyNewPatient: $e');
      return false;
    }
  }

  /// Métodos privados de configuración (debes implementarlos en tu proyecto)
  Future<void> _setupLocalNotifications() async {
    // TODO: Implementar configuración de notificaciones locales
  }

  Future<void> _requestPermissions() async {
    await FirebaseMessaging.instance.requestPermission();
  }

  Future<void> _setupMessageHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Notificación recibida en primer plano: ${message.notification?.title}');
      // TODO: manejar notificación
    });
  }
}
