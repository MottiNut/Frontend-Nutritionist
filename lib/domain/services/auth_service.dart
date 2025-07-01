/*import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.0.4:5000/api/bff/auth';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Headers comunes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Headers con token
  Map<String, String> _headersWithToken(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // ========== AUTENTICACIÓN ==========

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> registerNutritionist({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String cnpCode,
    required List<File> cnpPhotos,
    required String specialty,
    String? masterDegree,
    String? otherSpecialty,
    required String location,
    required String address,
    File? profilePhoto,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register/nutritionist'),
      );

      // Agregar campos de texto
      request.fields.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'cnpCode': cnpCode,
        'specialty': specialty,
        'location': location,
        'address': address,
      });

      // Agregar campos opcionales
      if (masterDegree?.isNotEmpty == true) {
        request.fields['masterDegree'] = masterDegree!;
      }
      if (otherSpecialty?.isNotEmpty == true) {
        request.fields['otherSpecialty'] = otherSpecialty!;
      }

      // Agregar foto de perfil
      if (profilePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profilePhoto', profilePhoto.path),
        );
      }

      // Agregar fotos del CNP
      for (int i = 0; i < cnpPhotos.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('cnpPhotos', cnpPhotos[i].path),
        );
      }

      // Agregar headers
      request.headers.addAll(_headers);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  // ========== VERIFICACIÓN ==========

  Future<AuthResponse> getVerificationStatus({required String userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verification/status?userId=$userId'),
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> sendEmailVerification({
    required String email,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/send/email'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          if (userId != null) 'userId': userId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> sendSmsVerification({
    required String phoneNumber,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/send/sms'),
        headers: _headers,
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          if (userId != null) 'userId': userId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> sendWhatsAppVerification({
    required String phoneNumber,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/send/whatsapp'),
        headers: _headers,
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          if (userId != null) 'userId': userId,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> resendVerificationCode({
    required String userId,
    required String method, // 'email', 'sms', 'whatsapp'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/resend'),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'method': method,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> verifyCode({
    required String userId,
    required String code,
    required String method, // 'email', 'sms', 'whatsapp'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verification/verify'),
        headers: _headers,
        body: jsonEncode({
          'userId': userId,
          'code': code,
          'method': method,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  // ========== GESTIÓN DE CONTRASEÑAS ==========

  Future<AuthResponse> requestPasswordReset({required String email}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/reset-request'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/password/reset'),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  Future<AuthResponse> updatePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/password/update'),
        headers: _headersWithToken(token),
        body: jsonEncode({
          'userId': userId,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return AuthResponse.error('Error de conexión: ${e.toString()}');
    }
  }

  // ========== UTILIDADES ==========

  AuthResponse _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResponse.success(data);
      } else {
        final errorMessage = data['message'] ??
            data['error'] ??
            'Error desconocido';
        return AuthResponse.error(errorMessage);
      }
    } catch (e) {
      return AuthResponse.error('Error al procesar la respuesta');
    }
  }
}

// ========== MODELOS DE RESPUESTA ==========

class AuthResponse {
  final bool isSuccess;
  final String? message;
  final Map<String, dynamic>? data;

  AuthResponse._({
    required this.isSuccess,
    this.message,
    this.data,
  });

  factory AuthResponse.success(Map<String, dynamic> data) {
    return AuthResponse._(
      isSuccess: true,
      data: data,
      message: data['message'] as String?,
    );
  }

  factory AuthResponse.error(String message) {
    return AuthResponse._(
      isSuccess: false,
      message: message,
    );
  }

  // Getters de conveniencia
  String? get token => data?['token'] as String?;
  String? get userId => data?['userId'] as String?;
  String? get email => data?['email'] as String?;
  bool get isVerified => data?['isVerified'] as bool? ?? false;
  Map<String, dynamic>? get user => data?['user'] as Map<String, dynamic>?;

  // Para verificación
  String? get verificationMethod => data?['verificationMethod'] as String?;
  bool get verificationSent => data?['verificationSent'] as bool? ?? false;
  int? get expiresIn => data?['expiresIn'] as int?;

  @override
  String toString() {
    return 'AuthResponse(isSuccess: $isSuccess, message: $message, data: $data)';
  }
}

*/