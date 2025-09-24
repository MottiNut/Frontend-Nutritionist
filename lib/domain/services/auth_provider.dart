import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../patient/new/rutadirectaaa/firebase_notification_handler.dart';
import 'firebase_auth_service.dart';

import 'package:connectivity_plus/connectivity_plus.dart';



enum VerificationMethod {
  email,
  sms,
  whatsapp;

  String get displayName {
    switch (this) {
      case VerificationMethod.email:
        return 'email';
      case VerificationMethod.sms:
        return 'sms';
      case VerificationMethod.whatsapp:
        return 'whatsApp';
    }
  }
}
class VerificationStatus1 {
  final bool emailVerified;
  final bool phoneVerified;
  final bool fullyVerified;
  final bool requiresVerification;

  VerificationStatus1({
    required this.emailVerified,
    required this.phoneVerified,
    required this.fullyVerified,
    required this.requiresVerification,
  });

  factory VerificationStatus1.fromMap(Map<String, dynamic> map) {
    return VerificationStatus1(
      emailVerified: map['emailVerified'] ?? false,
      phoneVerified: map['phoneVerified'] ?? false,
      fullyVerified: map['fullyVerified'] ?? false,
      requiresVerification: map['requiresVerification'] ?? false,
    );
  }
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isEmailVerified;
  final bool hasAcceptedTerms;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String loginProvider; // 'email', 'google', 'apple'

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.isEmailVerified,
    required this.hasAcceptedTerms,
    required this.createdAt,
    this.lastLoginAt,
    required this.loginProvider,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
      'hasAcceptedTerms': hasAcceptedTerms,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'loginProvider': loginProvider,
    };
  }

  // Crear desde Map de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      hasAcceptedTerms: map['hasAcceptedTerms'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.parse(map['lastLoginAt'])
          : null,
      loginProvider: map['loginProvider'] ?? 'email',
    );
  }

  // Crear copia con cambios
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
    bool? hasAcceptedTerms,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? loginProvider,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      loginProvider: loginProvider ?? this.loginProvider,
    );
  }
}
class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? userId;
  final String? email;
  final Map<String, dynamic>? user;
  final VerificationStatus1? verificationStatus;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.userId,
    this.email,
    this.user,
    this.verificationStatus,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final bool isSuccess = json['success'] ?? (json['token'] != null);

    Map<String, dynamic>? userData;
    if (json['user'] != null) {
      userData = Map<String, dynamic>.from(json['user']);
    } else if (json['token'] != null) {
      userData = {
        'userId': json['userId'],
        'email': json['email'],
        'role': json['role'],
        'fullName': json['fullName'],
        'emailVerified': json['emailVerified'] ?? false,
        'phoneVerified': json['phoneVerified'] ?? false,
        'fullyVerified': json['fullyVerified'] ?? false,
        'requiresVerification': json['requiresVerification'] ?? false,
      };
    }

    return AuthResponse(
      success: isSuccess,
      message: json['message'],
      token: json['token'],
      userId: json['userId']?.toString(),
      email: json['email'],
      user: userData,
      verificationStatus: json['verificationStatus'] != null
          ? VerificationStatus1.fromMap(
          Map<String, dynamic>.from(json['verificationStatus']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'token': token,
      'userId': userId,
      'email': email,
      'user': user,
      'verificationStatus': verificationStatus == null ? null : {
        'emailVerified': verificationStatus!.emailVerified,
        'phoneVerified': verificationStatus!.phoneVerified,
        'fullyVerified': verificationStatus!.fullyVerified,
        'requiresVerification': verificationStatus!.requiresVerification,
      },
    };
  }

}

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _userDataKey = 'cached_user_data';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 1);

  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final Connectivity _connectivity = Connectivity();

  // Guardar datos del usuario en caché
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, json.encode(userData));
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);

      // Precargar imagen de perfil si existe
      final String? imageUrl = _extractProfileImageUrl(userData);
      if (imageUrl != null) {
        await preloadProfileImage(imageUrl);
      }
    } catch (e) {
      debugPrint('Error caching user data: $e');
    }
  }

  // Obtener datos del usuario desde caché
  Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedData = prefs.getString(_userDataKey);
      final int? timestamp = prefs.getInt(_cacheTimestampKey);

      if (cachedData != null && timestamp != null) {
        final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final DateTime now = DateTime.now();

        if (now.difference(cacheTime) < _cacheDuration) {
          return Map<String, dynamic>.from(json.decode(cachedData));
        } else {
          // Caché expirado, limpiar
          await clearUserCache();
        }
      }
    } catch (e) {
      debugPrint('Error getting cached user data: $e');
    }
    return null;
  }

  // Verificar si hay caché válido
  Future<bool> hasValidCache() async {
    final prefs = await SharedPreferences.getInstance();
    final int? timestamp = prefs.getInt(_cacheTimestampKey);
    if (timestamp == null) return false;

    final DateTime cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) < _cacheDuration;
  }

  // Precargar imagen de perfil
  Future<void> preloadProfileImage(String imageUrl) async {
    try {
      await _cacheManager.downloadFile(
        imageUrl,
        key: 'profile_image_${_getUserIdFromUrl(imageUrl)}',
        authHeaders: await _getAuthHeaders(),
      );
    } catch (e) {
      debugPrint('Error preloading profile image: $e');
    }
  }

  Future<File> getCachedProfileImage(String imageUrl) async {
    try {
      final FileInfo? cachedFile = await _cacheManager.getFileFromCache(imageUrl);

      if (cachedFile != null) {
        return cachedFile.file;
      }

      // Si no está en caché, descargar
      final fileInfo = await _cacheManager.downloadFile(
        imageUrl,
        authHeaders: await _getAuthHeaders(),
        key: 'profile_image_${_getUserIdFromUrl(imageUrl)}',
      );
      return fileInfo.file;
    } catch (e) {
      debugPrint('Error getting cached profile image: $e');
      throw Exception('No se pudo cargar la imagen');
    }
  }

  // Limpiar caché
  Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_cacheTimestampKey);
      await _cacheManager.emptyCache();
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  Future<bool> isConnected() async {
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<Map<String, dynamic>> loadUserDataWithStrategy({
    required Future<Map<String, dynamic>> Function() fetchFromNetwork,
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      final freshData = await fetchFromNetwork();
      await cacheUserData(freshData);
      return freshData;
    }

    // Primero intentar desde caché
    final cachedData = await getCachedUserData();
    if (cachedData != null) {
      if (await isConnected()) {
        _refreshInBackground(fetchFromNetwork);
      }
      return cachedData;
    }

    // Si no hay caché, cargar desde red
    return await fetchFromNetwork();
  }

  // Actualizar en segundo plano
  void _refreshInBackground(Future<Map<String, dynamic>> Function() fetchFromNetwork) async {
    try {
      final freshData = await fetchFromNetwork();
      await cacheUserData(freshData);
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    }
  }

  // Headers de autenticación
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    if (token != null) {
      return {'Authorization': 'Bearer $token'};
    }
    return {};
  }

  String? _extractProfileImageUrl(Map<String, dynamic> userData) {
    return userData['profileImageUrl'] ??
        userData['profileImage'] ??
        userData['avatar'] ??
        userData['imageUrl'];
  }

  String _getUserIdFromUrl(String url) {
    // Extraer ID de usuario de la URL si es posible
    final uri = Uri.parse(url);
    return uri.pathSegments.lastWhere((segment) => segment.isNotEmpty, orElse: () => 'default');
  }
}
class AuthService {
  // URLs base
  static const String baseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/auth';
  static const String profileBaseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/auth/profile';
  static const String notificationsBaseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/notifications';
  static const String userSettingsBaseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/users';

  //static const String baseUrl = 'http://192.168.0.8:5000/api/bff/auth';
  //static const String profileBaseUrl = 'http://192.168.0.8:5000/api/bff/auth/profile';
  //static const String notificationsBaseUrl = 'http://192.168.0.8:5000/api/notifications';
  //static const String userSettingsBaseUrl = 'http://192.168.0.8:5000/api/users';


  // Endpoints específicos
  static const String loginEndpoint = '$baseUrl/login';
  static const String registerEndpoint = '$baseUrl/register/nutritionist';

  static const String verificationSendEmailEndpoint = '$baseUrl/verification/send/email';
  static const String verificationSendSmsEndpoint = '$baseUrl/verification/send/sms';
  static const String verificationSendWhatsappEndpoint = '$baseUrl/verification/send/whatsapp';
  static const String verificationResendEndpoint = '$baseUrl/verification/resend';
  static const String verificationVerifyEndpoint = '$baseUrl/verification/verify';

  static const String verificationSendEndpoint = '$baseUrl/verification/send';

  static const String passwordResetRequestEndpoint = '$baseUrl/password/reset-request';
  static const String passwordResetEndpoint = '$baseUrl/password/reset';
  static const String passwordUpdateEndpoint = '$baseUrl/password/update';
  static const String validateEndpoint = '$baseUrl/validate';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String nutritionistProfileEndpoint = '$profileBaseUrl/nutritionist';
  static const String nutritionistImageEndpoint = '$profileBaseUrl/nutritionist';
  static const String meEndpoint = '$baseUrl/me';

  // Profile sharing endpoints
  static const String shareGenerateLinkEndpoint = '$baseUrl/share/generate-link';
  static const String shareResolveEndpoint = '$baseUrl/share/resolve';
  static const String shareNutritionistEndpoint = '$baseUrl/share/nutritionist';


  final http.Client _client = http.Client();

  final CacheService _cacheService = CacheService();

  // Headers comunes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _headersWithAuth(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  // ========== MÉTODOS DE AUTENTICACIÓN ==========
  Future<bool> registerDeviceToken({
    required String token,
    required String deviceToken,
    required String platform,
  }) async {
    try {
      final url = '$notificationsBaseUrl/device-token';
      final headers = _headersWithAuth(token);
      final body = json.encode({
        'deviceToken': deviceToken,
        'platform': platform,
      });

      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 201) {
        return true;
      } else {

        return false;
      }
    } catch (e) {

      return false;
    }
  }

  // Obtener historial de notificaciones
  Future<List<dynamic>> getNotificationHistory({
    required String token,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$notificationsBaseUrl/history?limit=$limit'),
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {

      return [];
    }
  }

  // Enviar acción del paciente (para cuando el paciente acepta/rechaza planes)
  Future<bool> sendPatientActionNotification({
    required String token,
    required String patientId,
    required String nutritionistId,
    required int planId,
    required String patientName,
    required String actionType,
    String? reason,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$notificationsBaseUrl/nutritionist/patient-action'),
        headers: _headersWithAuth(token),
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

      return false;
    }
  }

  // Notificar nuevo paciente asignado
  Future<bool> notifyNewPatientAssignment({
    required String token,
    required String nutritionistId,
    required String patientName,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$notificationsBaseUrl/nutritionist/new-patient?nutritionistId=$nutritionistId&patientName=$patientName'),
        headers: _headersWithAuth(token),
      );

      return response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  Future<Map<String, String>> generateShareLink(String token) async {
    try {
      final response = await _client.post(
        Uri.parse(shareGenerateLinkEndpoint),
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, String>.from(responseData);
      } else {
        throw Exception('Error generating share link');
      }
    } catch (e) {
      debugPrint('Error generating share link: $e');
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getPublicNutritionistProfile(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$shareNutritionistEndpoint/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, dynamic>.from(responseData);
      } else {
        throw Exception('Profile not found or private');
      }
    } catch (e) {
      debugPrint('Error getting public profile: $e');
      throw Exception('Error obteniendo perfil: ${e.toString()}');
    }
  }

  /// Resolve short code to get profile information
  Future<Map<String, dynamic>> resolveShareCode(String shortCode) async {
    try {
      final response = await _client.get(
        Uri.parse('$shareResolveEndpoint/$shortCode'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, dynamic>.from(responseData);
      } else {
        throw Exception('Invalid or expired code');
      }
    } catch (e) {
      debugPrint('Error resolving share code: $e');
      throw Exception('Código inválido o expirado');
    }
  }

  Future<Map<String, dynamic>> getUserSettings(String token, String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$userSettingsBaseUrl/$userId/settings/onboarding'),
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'onboardingSeen': false};
    } catch (e) {
      return {'onboardingSeen': false};
    }
  }

  Future<bool> markOnboardingSeen(String token, String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$userSettingsBaseUrl/$userId/settings/onboarding'),
        headers: _headersWithAuth(token),
      );

      return response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  Future<bool> markToolTipsSeen(String token, String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$userSettingsBaseUrl/$userId/settings/tooltips'),
        headers: _headersWithAuth(token),
      );

      return response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  Future<Map<String, dynamic>> getUserTooltipSettings(String token, String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$userSettingsBaseUrl/$userId/settings/tooltips'),
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {
        'tooltipsSeen': false,
        'homeGuideShown': false,
        'patientsGuideShown': false,
        'patientDetailGuideShown': false
      };
    } catch (e) {

      return {
        'tooltipsSeen': false,
        'homeGuideShown': false,
        'patientsGuideShown': false,
        'patientDetailGuideShown': false
      };
    }
  }

  Future<bool> markTooltipAsSeen(String token, String userId, String tooltipKey) async {
    try {
      final response = await _client.post(
        Uri.parse('$userSettingsBaseUrl/$userId/settings/tooltips/$tooltipKey'),
        headers: _headersWithAuth(token),
      );

      return response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  Future<bool> markAllTooltipsSeen(String token, String userId) async {
    try {
      final response = await _client.post(
        Uri.parse('$userSettingsBaseUrl/$userId/settings/tooltips'),
        headers: _headersWithAuth(token),
      );

      return response.statusCode == 200;
    } catch (e) {

      return false;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(loginEndpoint),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error en el login',
        );
      }
    } catch (e) {

      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required File profileImage,
    required String email,
    required String password,
    required String phone,
    required String cnpCode,
    required File licenseFrontImage,
    required File licenseBackImage,
    required String specialty,
    String? masterDegree,
    String? otherSpecialty,
    required String location,
    required String address,
    required bool acceptTerms,
  }) async {
    try {
      // Crear multipart request para archivos
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(registerEndpoint),
      );

      // Agregar campos de texto
      request.fields.addAll({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'cnpCode': cnpCode,
        'specialty': specialty,
        'location': location,
        'address': address,
        'acceptTerms': acceptTerms.toString(),
      });

      // Agregar campos opcionales
      if (masterDegree != null) request.fields['masterDegree'] = masterDegree;
      if (otherSpecialty != null) request.fields['otherSpecialty'] = otherSpecialty;

      // Función helper para obtener el tipo MIME correcto
      String getMimeType(String filePath) {
        String extension = filePath.toLowerCase().split('.').last;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            return 'image/jpeg';
          case 'png':
            return 'image/png';
          case 'gif':
            return 'image/gif';
          case 'webp':
            return 'image/webp';
          default:
            return 'image/jpeg'; // fallback
        }
      }

      // Agregar imagen de perfil con Content-Type correcto
      if (profileImage.existsSync()) {
        request.files.add(
          http.MultipartFile(
            'profileImage',
            profileImage.readAsBytes().asStream(),
            profileImage.lengthSync(),
            filename: profileImage.path.split('/').last,
            contentType: MediaType.parse(getMimeType(profileImage.path)),
          ),
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'La imagen de perfil es requerida',
        );
      }

      // Agregar imagen frontal de licencia con Content-Type correcto
      if (licenseFrontImage.existsSync()) {
        request.files.add(
          http.MultipartFile(
            'licenseFrontImage',
            licenseFrontImage.readAsBytes().asStream(),
            licenseFrontImage.lengthSync(),
            filename: licenseFrontImage.path.split('/').last,
            contentType: MediaType.parse(getMimeType(licenseFrontImage.path)),
          ),
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'La imagen frontal de la licencia es requerida',
        );
      }

      // Agregar imagen posterior de licencia con Content-Type correcto
      if (licenseBackImage.existsSync()) {
        request.files.add(
          http.MultipartFile(
            'licenseBackImage',
            licenseBackImage.readAsBytes().asStream(),
            licenseBackImage.lengthSync(),
            filename: licenseBackImage.path.split('/').last,
            contentType: MediaType.parse(getMimeType(licenseBackImage.path)),
          ),
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'La imagen posterior de la licencia es requerida',
        );
      }

      // Agregar headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error en el registro',
        );
      }
    } catch (e) {

      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // ========== VERIFICACIÓN ==========

  Future<AuthResponse> sendVerificationCode({
    required String email,
    required VerificationMethod method,
    String? phoneNumber,
  }) async {
    try {
      String endpoint;
      Map<String, dynamic> requestBody = {
        'email': email,
      };

      // Seleccionar el endpoint correcto según el método
      switch (method) {
        case VerificationMethod.email:
          endpoint = verificationSendEmailEndpoint;
          break;
        case VerificationMethod.sms:
          endpoint = verificationSendSmsEndpoint;
          requestBody['phoneNumber'] = phoneNumber;
          break;
        case VerificationMethod.whatsapp:
          endpoint = verificationSendWhatsappEndpoint;
          requestBody['phoneNumber'] = phoneNumber;
          break;
      }

      if (phoneNumber != null) debugPrint('📤 Teléfono: $phoneNumber');

      final response = await _client.post(
        Uri.parse(endpoint),
        headers: _headers,
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error enviando código',
        );
      }
    } catch (e) {

      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(verificationVerifyEndpoint),
        headers: _headers,
        body: json.encode({
          'code': code,
          'type': 'email', // O el tipo correspondiente
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Código inválido',
        );
      }
    } catch (e) {

      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(verificationResendEndpoint),
        headers: _headers,
        body: json.encode({
          'email': email,
          'type': 'email', // Ajusta según necesites
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error reenviando código',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // ========== GESTIÓN DE CONTRASEÑAS ==========

  Future<AuthResponse> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(passwordResetRequestEndpoint),
        headers: _headers,
        body: json.encode({
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error solicitando reset',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(passwordResetEndpoint),
        headers: _headers,
        body: json.encode({
          'email': email,
          'token': token,
          'newPassword': newPassword,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error reseteando contraseña',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse(passwordUpdateEndpoint),
        headers: _headersWithAuth(token),
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error actualizando contraseña',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // ========== VALIDACIÓN DE TOKEN ==========

  Future<AuthResponse> validateToken(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(validateEndpoint),
        headers: _headersWithAuth(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: 'Token inválido',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error validando token: ${e.toString()}',
      );
    }
  }

  // ========== OBTENER PERFIL DE USUARIO ==========

  // Cache manager para avatares de nutricionistas
  static final CacheManager avatarCacheManager = CacheManager(
    Config(
      'nutritionist_avatar_cache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 50,
      repo: JsonCacheInfoRepository(databaseName: 'avatar_cache'),
    ),
  );

  // ========== MÉTODOS DE CACHÉ PARA IMÁGENES ==========
  Future<AuthResponse> getCurrentUser(String token, {bool forceRefresh = false}) async {
    try {
      final userData = await _cacheService.loadUserDataWithStrategy(
        forceRefresh: forceRefresh,
        fetchFromNetwork: () async {
          final response = await _client.get(
            Uri.parse(meEndpoint),
            headers: _headersWithAuth(token),
          );

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            return Map<String, dynamic>.from(responseData);
          }
          throw Exception('Error obteniendo datos del usuario');
        },
      );

      return AuthResponse(
        success: true,
        user: userData,
        token: token,
      );
    } catch (e) {

      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  static Future<File> getCachedAvatarImage({
    required String imageUrl,
    required String? token,
    String? userId,
  }) async {
    try {
      final Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Verificar si la imagen ya está en caché
      final FileInfo? cachedFile = await avatarCacheManager.getFileFromCache(imageUrl);

      if (cachedFile != null) {
        return cachedFile.file;
      }

      final File file = await avatarCacheManager.getSingleFile(
        imageUrl,
        headers: headers,
      );

      // Guardar copia local adicional para acceso rápido
      await _saveImageToLocalStorage(file, userId);

      return file;
    } catch (e) {

      throw Exception('No se pudo cargar la imagen: $e');
    }
  }

  /// Guarda la imagen en almacenamiento local
  static Future<void> _saveImageToLocalStorage(File imageFile, String? userId) async {
    try {
      if (userId != null) {
        final directory = await getApplicationDocumentsDirectory();
        final localPath = '${directory.path}/nutritionist_avatar_$userId.jpg';

        await imageFile.copy(localPath);

      }
    } catch (e) {
      debugPrint('⚠️ Error guardando imagen localmente: $e');
    }
  }

  /// Precarga la imagen del avatar
  static Future<void> preloadAvatarImage({
    required String imageUrl,
    required String? token,
    String? userId,
  }) async {
    try {
      final Map<String, String> headers = {};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      await avatarCacheManager.downloadFile(
        imageUrl,
        authHeaders: headers,
      );

      // También guardar localmente
      final File file = await avatarCacheManager.getSingleFile(imageUrl, headers: headers);
      await _saveImageToLocalStorage(file, userId);

    } catch (e) {
      debugPrint('⚠️ Error precargando imagen: $e');
    }
  }

  /// Limpia el caché de avatares
  static Future<void> clearAvatarCache() async {
    try {
      await avatarCacheManager.emptyCache();
    } catch (e) {

    }
  }

  /// Obtiene la imagen local si existe
  static Future<File?> getLocalAvatarImage(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/nutritionist_avatar_$userId.jpg';
      final File localFile = File(localPath);

      if (await localFile.exists()) {

        return localFile;
      }
      return null;
    } catch (e) {

      return null;
    }
  }

  // En tu AuthService, modifica el método getNutritionistProfile
  Future<AuthResponse> getNutritionistProfile(String token, {bool forceRefresh = false}) async {
    try {
      // Usar estrategia de caché
      final userData = await _cacheService.loadUserDataWithStrategy(
        forceRefresh: forceRefresh,
        fetchFromNetwork: () async {
          final response = await _client.get(
            Uri.parse(nutritionistProfileEndpoint),
            headers: _headersWithAuth(token),
          );

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            return _extractUserData(responseData);
          }
          throw Exception('Error obteniendo perfil');
        },
      );

      return AuthResponse(
        success: true,
        user: userData,
        token: token,
      );
    } catch (e) {

      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Map<String, dynamic> _extractUserData(dynamic responseData) {
    if (responseData['data'] != null && responseData['data'] is Map) {
      return Map<String, dynamic>.from(responseData['data']);
    } else if (responseData['user'] != null && responseData['user'] is Map) {
      return Map<String, dynamic>.from(responseData['user']);
    } else if (responseData is Map) {
      return Map<String, dynamic>.from(responseData);
    }
    return {};
  }

  // Método estático para construir URL de imagen de perfil
  static String buildProfileImageUrl(String userId) {
    return '$nutritionistImageEndpoint/$userId/image';
  }

  /// Extrae la URL de la imagen del perfil de los datos del usuario
  String? _extractProfileImageUrl(Map<String, dynamic> userData) {
    return userData['profileImageUrl'] ??
        userData['profileImage'] ??
        userData['profile_image'] ??
        userData['avatar'] ??
        userData['photo'] ??
        userData['imageUrl'] ??
        userData['image_url'];
  }

  // ========== LOGOUT ==========

  Future<AuthResponse> logout(String token) async {
    try {
      final response = await _client.post(
        Uri.parse(logoutEndpoint),
        headers: _headersWithAuth(token),
      );

      if (response.statusCode == 200) {
        return AuthResponse(success: true);
      } else {
        return AuthResponse(
          success: false,
          message: 'Error en logout',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }
  // ========== CLEANUP ==========

  void dispose() {
    _client.close();
  }
}
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  final CacheService _cacheService = CacheService();
  //final FirebaseAuthService _authServiceGogle = FirebaseAuthService();

  final FirebaseNotificationService _firebaseNotificationService = FirebaseNotificationService();

  // Estado de autenticación
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _token;
  String? _userId;
  String? _email;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  // Estado de verificación
  bool _isVerificationPending = false;
  String? _verificationMethod;
  String? _pendingVerificationEmail;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isVerificationPending => _isVerificationPending;

  // Nuevas propiedades para notificaciones
  int _unreadNotifications = 0;
  List<dynamic> _notifications = [];
  String? _fcmToken;

  // Getters para notificaciones
  int get unreadNotifications => _unreadNotifications;
  List<dynamic> get notifications => _notifications;
  String? get fcmToken => _fcmToken;

  Map<String, String>? _shareLinks;
  bool _isGeneratingShareLink = false;

  bool _onboardingSeen = false;
  bool _toolTipsSeen = false;
  bool _isCheckingOnboarding = false;

  Map<String, bool> _tooltipStatus = {};
  bool _isCheckingTooltips = false;

  bool get onboardingSeen => _onboardingSeen;
  bool get toolTipsSeen => _toolTipsSeen;
  bool get isCheckingOnboarding => _isCheckingOnboarding;

  Map<String, bool> get tooltipStatus => _tooltipStatus;
  bool get isCheckingTooltips => _isCheckingTooltips;

  Map<String, String>? get shareLinks => _shareLinks;
  bool get isGeneratingShareLink => _isGeneratingShareLink;

  AuthProvider() {
    _loadStoredAuth();
  }


  // ========== GESTIÓN DE SESIÓN ==========

  void setFcmToken(String token) {
    _fcmToken = token;
    _registerDeviceTokenIfPossible();
  }

  // Registrar device token cuando el usuario esté autenticado
  Future<void> _registerDeviceTokenIfPossible() async {
    if (_token != null && _fcmToken != null) {
      try {

        final success = await _authService.registerDeviceToken(
          token: _token!,
          deviceToken: _fcmToken!,
          platform: Platform.isAndroid ? 'android' : 'ios',
        );

        if (success) {
          debugPrint('✅ Device token registrado exitosamente');
        } else {
          debugPrint('❌ Error registrando device token - success: false');
        }
      } catch (e) {
        debugPrint('❌ Exception registrando device token: $e');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
    } else {
      debugPrint('No se puede registrar token - token auth: ${_token != null}, fcm token: ${_fcmToken != null}');
    }
  }

  // Cargar historial de notificaciones
  Future<void> loadNotificationHistory() async {
    if (_token == null) return;

    try {
      _notifications = await _authService.getNotificationHistory(
        token: _token!,
        limit: 50,
      );

      _unreadNotifications = _notifications
          .where((n) => n['isRead'] == false)
          .length;

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification history: $e');
    }
  }

  Future<void> checkOnboardingStatus() async {
    if (_token == null || _userId == null) {
      _onboardingSeen = false;
      return;
    }

    _isCheckingOnboarding = true;
    notifyListeners();

    try {
      final settings = await _authService.getUserSettings(_token!, _userId!);
      _onboardingSeen = settings['onboardingSeen'] ?? false;
      _toolTipsSeen = settings['toolTipsSeen'] ?? false;

    } catch (e) {

      _onboardingSeen = false;
      _toolTipsSeen = false;
    } finally {
      _isCheckingOnboarding = false;
      notifyListeners();
    }
  }

  Future<bool> markOnboardingSeen() async {
    if (_token == null || _userId == null) {
      return false;
    }

    try {
      final success = await _authService.markOnboardingSeen(_token!, _userId!);
      if (success) {
        _onboardingSeen = true;
        notifyListeners();

      }
      return success;
    } catch (e) {

      return false;
    }
  }

  Future<bool> markToolTipsSeen() async {
    if (_token == null || _userId == null) {
      return false;
    }

    try {
      final success = await _authService.markToolTipsSeen(_token!, _userId!);
      if (success) {
        _toolTipsSeen = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error marking tooltips as seen: $e');
      return false;
    }
  }

  Future<void> checkTooltipStatus() async {
    if (_token == null || _userId == null) {
      _tooltipStatus = {};
      return;
    }

    _isCheckingTooltips = true;
    notifyListeners();

    try {
      final settings = await _authService.getUserTooltipSettings(_token!, _userId!);

      _tooltipStatus = {
        'home_guide_shown': settings['homeGuideShown'] ?? false,
        'patients_guide_shown': settings['patientsGuideShown'] ?? false,
        'patient_detail_guide_shown': settings['patientDetailGuideShown'] ?? false,
      };

    } catch (e) {

      _tooltipStatus = {
        'home_guide_shown': false,
        'patients_guide_shown': false,
        'patient_detail_guide_shown': false,
      };
    } finally {
      _isCheckingTooltips = false;
      notifyListeners();
    }
  }

  Future<bool> markTooltipAsSeen(String tooltipKey) async {
    if (_token == null || _userId == null) {
      return false;
    }

    try {
      final success = await _authService.markTooltipAsSeen(_token!, _userId!, tooltipKey);
      if (success) {
        _tooltipStatus[tooltipKey] = true;
        notifyListeners();

      }
      return success;
    } catch (e) {

      return false;
    }
  }

  Future<void> _handleAuthSuccess(AuthResponse response) async {
    _token = response.token;
    _userId = response.userId;
    _email = response.email ?? _email;
    _user = response.user;
    _isAuthenticated = true;

    if (_token != null && _userId != null && _email != null) {
      await _saveAuth(
        token: _token!,
        userId: _userId!,
        email: _email!,
        userData: _user,
      );

      // Verificar estado del onboarding después del login
      await checkOnboardingStatus();

      // Registrar device token después del login exitoso
      await _initializeFirebaseNotifications();
      await _registerDeviceTokenIfPossible();
      await loadNotificationHistory();
    }

    notifyListeners();
  }

  Future<void> _initializeFirebaseNotifications() async {
    try {
      // 1. Solicitar permisos
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Obtener token FCM
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {

          // 3. Configurar el token en el provider
          setFcmToken(fcmToken);

          // 4. Configurar handlers de notificaciones
          _setupNotificationHandlers();
        }
      } else {
        debugPrint('Permisos de notificación denegados');
      }
    } catch (e) {
      debugPrint('Error inicializando Firebase Notifications: $e');
    }
  }

  void _setupNotificationHandlers() {
    // Manejar notificaciones cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Notificación recibida en foreground: ${message.notification?.title}');
      // Mostrar notificación local o actualizar UI
    });

    // Manejar notificaciones cuando la app se abre desde una notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App abierta desde notificación: ${message.notification?.title}');
      // Navegar a pantalla específica
    });
  }

  // Método para enviar notificación de acción del paciente
  Future<bool> sendPatientAction({
    required String patientId,
    required int planId,
    required String patientName,
    required String actionType,
    String? reason,
  }) async {
    if (_token == null || _userId == null) {
      return false;
    }

    try {
      return await _authService.sendPatientActionNotification(
        token: _token!,
        patientId: patientId,
        nutritionistId: _userId!,
        planId: planId,
        patientName: patientName,
        actionType: actionType,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Error sending patient action: $e');
      return false;
    }
  }

  // Método para notificar nuevo paciente
  Future<bool> notifyNewPatient(String patientName) async {
    if (_token == null || _userId == null) {
      return false;
    }

    try {
      return await _authService.notifyNewPatientAssignment(
        token: _token!,
        nutritionistId: _userId!,
        patientName: patientName,
      );
    } catch (e) {
      debugPrint('Error notifying new patient: $e');
      return false;
    }
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      _userId = prefs.getString('user_id');
      _email = prefs.getString('user_email');

      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _user = Map<String, dynamic>.from(jsonDecode(userJson));
      }

      if (_token != null) {
        // Validar token con el servidor
        final response = await _authService.validateToken(_token!);
        if (response.success) {
          _isAuthenticated = true;
          if (response.user != null) {
            _user = response.user;
          }
        } else {
          await _clearAuth();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
      await _clearAuth();
    }
  }

  Future<void> _saveAuth({
    required String token,
    required String userId,
    required String email,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_id', userId);
      await prefs.setString('user_email', email);

      if (userData != null) {
        await prefs.setString('user_data', jsonEncode(userData));
      }
    } catch (e) {
      debugPrint('Error saving auth: $e');
    }
  }

  Future<void> _clearAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_data');

      _isAuthenticated = false;
      _token = null;
      _userId = null;
      _email = null;
      _user = null;
    } catch (e) {
      debugPrint('Error clearing auth: $e');
    }
  }

  // ========== MÉTODOS DE AUTENTICACIÓN ==========

  Future<bool> login(String email, String password) async {
    _setLoading(true);
     clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success) {
        await _handleAuthSuccess(response);
        return true;
      } else {
        _setError(response.message ?? 'Error en el login');
        return false;
      }
    } catch (e) {
      _setError(_getConnectionErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required File profileImage,
    required String email,
    required String password,
    required String phone,
    required String cnpCode,
    required File licenseFrontImage,
    required File licenseBackImage,
    required String specialty,
    String? masterDegree,
    String? otherSpecialty,
    required String location,
    required String address,
    required bool acceptTerms,
  }) async {
    _setLoading(true);
     clearError();

    try {

      // Verificar que los archivos existan
      if (!profileImage.existsSync()) {
        throw Exception('El archivo de imagen de perfil no existe');
      }
      if (!licenseFrontImage.existsSync()) {
        throw Exception('El archivo de imagen frontal de licencia no existe');
      }
      if (!licenseBackImage.existsSync()) {
        throw Exception('El archivo de imagen posterior de licencia no existe');
      }

      final response = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        profileImage: profileImage,
        email: email,
        password: password,
        phone: phone,
        cnpCode: cnpCode,
        licenseFrontImage: licenseFrontImage,
        licenseBackImage: licenseBackImage,
        specialty: specialty,
        masterDegree: masterDegree,
        otherSpecialty: otherSpecialty,
        location: location,
        address: address,
        acceptTerms: acceptTerms,
      );

      if (response.success) {

        // Verificar si el response tiene información de verificación requerida
        if (response.user != null) {
          final userData = response.user!;
          final requiresVerification = userData['requiresVerification'] ?? false;
          final emailVerified = userData['emailVerified'] ?? false;
          final fullyVerified = userData['fullyVerified'] ?? false;


          if (requiresVerification || !emailVerified || !fullyVerified) {
            // Usuario registrado pero necesita verificación
            debugPrint('=== CONFIGURANDO VERIFICACIÓN PENDIENTE ===');
            _isVerificationPending = true;
            _pendingVerificationEmail = email;

            // Guardar datos temporalmente si hay token
            if (response.token != null && response.userId != null) {
              _token = response.token;
              _userId = response.userId;
              _email = response.email ?? email;
              _user = response.user;
              // NO marcar como autenticado hasta que se verifique
              _isAuthenticated = false;
            }

            notifyListeners();
            return true;
          } else {

            await _handleAuthSuccess(response);
            return true;
          }
        } else {


          if (response.token != null) {

            _isVerificationPending = true;
            _pendingVerificationEmail = email;
            _token = response.token;
            _userId = response.userId;
            _email = response.email ?? email;
            _isAuthenticated = false;

            notifyListeners();
            return true;
          } else {

            _isVerificationPending = true;
            _pendingVerificationEmail = email;
            notifyListeners();
            return true;
          }
        }
      } else {
        _setError(response.message ?? 'Error en el registro');
        return false;
      }
    } catch (e) {
      _setError(_getConnectionErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  bool get isFullyVerified => _user?['fullyVerified'] == true;
  bool get isEmailVerified => _user?['emailVerified'] == true;
  bool get isPhoneVerified => _user?['phoneVerified'] == true;

  // ========== VERIFICACIÓN ==========

  Future<bool> loadUserProfile({bool forceRefresh = false}) async {
    if (_token == null) return false;

    _setLoading(true);

    try {
      final response = await _authService.getNutritionistProfile(
          _token!,
          forceRefresh: forceRefresh
      );

      if (response.success && response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUserData() async {
    await loadUserProfile(forceRefresh: true);
  }

  Future<bool> loadCurrentUser() async {
    if (_token == null) return false;

    _setLoading(true);

    try {
      final response = await _authService.getCurrentUser(_token!);

      if (response.success && response.user != null) {
        _user = response.user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendVerificationCode({
    required VerificationMethod method,
    String? phoneNumber,
  }) async {
    if (_pendingVerificationEmail == null && _email == null) {
      _setError('No hay usuario pendiente de verificación');
      return false;
    }

    _setLoading(true);
     clearError();

    try {

      final response = await _authService.sendVerificationCode(
        email: _pendingVerificationEmail ?? _email!,
        method: method,
        phoneNumber: phoneNumber,
      );

      if (response.success) {
        _verificationMethod = method.name;
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Error enviando código');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> verifyCode(String code) async {
    if (_pendingVerificationEmail == null && _email == null) {
      _setError('No hay verificación pendiente');
      return {
        'success': false,
        'message': 'No hay verificación pendiente'
      };
    }

    _setLoading(true);
     clearError();

    try {
      final response = await _authService.verifyCode(
        email: _pendingVerificationEmail ?? _email!,
        code: code,
      );

      // CORRECCIÓN PRINCIPAL: Verificar también el mensaje para casos de éxito
      bool isActualSuccess = response.success;

      // Si el backend responde con success=false pero mensaje indica éxito
      if (!isActualSuccess && response.message != null) {
        String message = response.message!.toLowerCase();
        if (message.contains('verificado exitosamente') ||
            message.contains('email verificado') ||
            message.contains('verificado correctamente') ||
            message.contains('verification successful')) {
          isActualSuccess = true;
        }
      }

      if (isActualSuccess) {
        // Limpiar estado de verificación
        _isVerificationPending = false;
        _verificationMethod = null;
        _pendingVerificationEmail = null;

        return {
          'success': true,
          'message': response.message ?? 'Verificación exitosa',
          'verificationStatus': response.verificationStatus,
          'isAuthenticated': false,
          'requiresLogin': true
        };
      } else {
        _setError(response.message ?? 'Código inválido');
        return {
          'success': false,
          'message': response.message ?? 'Código inválido'
        };
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}'
      };
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendVerificationCode() async {
    if (_pendingVerificationEmail == null && _email == null) {
      _setError('No hay verificación pendiente');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final response = await _authService.resendVerificationCode(
        email: _pendingVerificationEmail ?? _email!,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.message ?? 'Error reenviando código');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== GESTIÓN DE CONTRASEÑAS ==========

  Future<bool> requestPasswordReset(String email) async {
    _setLoading(true);
    clearError();

    try {
      final response = await _authService.requestPasswordReset(email: email);

      if (response.success) {
        return true;
      } else {
        _setError(response.message ?? 'Error solicitando reset');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
     clearError();

    try {
      final response = await _authService.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.message ?? 'Error reseteando contraseña');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_token == null) {
      _setError('Usuario no autenticado');
      return false;
    }

    _setLoading(true);
     clearError();

    try {
      final response = await _authService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        token: _token!,
      );

      if (response.success) {
        return true;
      } else {
        _setError(response.message ?? 'Error actualizando contraseña');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }


  /// Share nutritionist profile using native share functionality
  Future<Map<String, String>?> generateShareLinks() async {
    if (_token == null || _user == null) {
      _setError('Usuario no autenticado');
      return null;
    }

    _isGeneratingShareLink = true;
    notifyListeners();

    try {
      final shareLinks = await _authService.generateShareLink(_token!);
      _shareLinks = shareLinks;

      debugPrint('Share links generated: $shareLinks');
      notifyListeners();
      return shareLinks;
    } catch (e) {
      _setError('Error generando enlace de compartir: ${e.toString()}');
      return null;
    } finally {
      _isGeneratingShareLink = false;
      notifyListeners();
    }
  }

  /// Share nutritionist profile using native share functionality
  Future<void> shareProfile() async {
    if (_user == null) {
      _setError('No hay información de perfil disponible');
      return;
    }

    try {
      // First generate the share links if not available
      Map<String, String>? links = _shareLinks;
      if (links == null) {
        links = await generateShareLinks();
        if (links == null) {
          throw Exception('No se pudo generar el enlace de compartir');
        }
      }

      // Get the appropriate share URL
      String shareUrl = links['shortUrl'] ?? links['fullUrl'] ?? '';

      if (shareUrl.isEmpty) {
        throw Exception('No se encontró URL válida para compartir');
      }

      // Prepare share content
      final String firstName = _user!['firstName'] ?? _user!['first_name'] ?? '';
      final String lastName = _user!['lastName'] ?? _user!['last_name'] ?? '';
      final String fullName = '$firstName $lastName'.trim();

      final String shareText = fullName.isNotEmpty
          ? '¡Mira mi perfil de nutricionista en Mottinut! $shareUrl'
          : '¡Mira mi perfil de nutricionista en Mottinut! $shareUrl';

      final String subject = fullName.isNotEmpty
          ? 'Perfil de $fullName'
          : 'Perfil de Nutricionista';

      // Use Share.share (you'll need to add share_plus package to pubspec.yaml)
      await Share.share(
        shareText,
        subject: subject,
      );

      debugPrint('Profile shared successfully');

    } catch (e) {
      debugPrint('Error sharing profile: $e');
      _setError('Error compartiendo perfil: ${e.toString()}');
    }
  }

  /// Copy share link to clipboard - CORRECTED VERSION
  Future<void> copyShareLinkToClipboard() async {
    if (_shareLinks == null) {
      // Generate links if not available
      await generateShareLinks();
    }

    if (_shareLinks != null) {
      final String shareUrl = _shareLinks!['shortUrl'] ?? _shareLinks!['fullUrl'] ?? '';

      if (shareUrl.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: shareUrl));

        // You can show a snackbar or toast here to confirm the action
        debugPrint('Share link copied to clipboard: $shareUrl');
      } else {
        _setError('No hay enlace disponible para copiar');
      }
    } else {
      _setError('Error generando enlace para copiar');
    }
  }

  /// Get public nutritionist profile (for viewing shared profiles)
  Future<Map<String, dynamic>?> getPublicNutritionistProfile(String userId) async {
    try {
      final profile = await _authService.getPublicNutritionistProfile(userId);
      return profile;
    } catch (e) {
      debugPrint('Error getting public profile: $e');
      _setError('Error obteniendo perfil público: ${e.toString()}');
      return null;
    }
  }

  /// Resolve share code to get profile information
  Future<Map<String, dynamic>?> resolveShareCode(String shortCode) async {
    _setLoading(true);
    clearError();

    try {
      final resolveData = await _authService.resolveShareCode(shortCode);
      return resolveData;
    } catch (e) {
      debugPrint('Error resolving share code: $e');
      _setError('Error resolviendo código: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get formatted profile share text
  String getProfileShareText({String? customUrl}) {
    if (_user == null) return 'Mottinut - Encuentra tu nutricionista ideal';

    final String firstName = _user!['firstName'] ?? _user!['first_name'] ?? '';
    final String lastName = _user!['lastName'] ?? _user!['last_name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();

    final String url = customUrl ?? _shareLinks?['shortUrl'] ?? _shareLinks?['fullUrl'] ?? '';

    if (fullName.isNotEmpty && url.isNotEmpty) {
      return '¡Mira mi perfil de nutricionista en Mottinut! $url';
    } else if (url.isNotEmpty) {
      return '¡Mira mi perfil de nutricionista en Mottinut! $url';
    } else {
      return 'Mottinut - Encuentra tu nutricionista ideal';
    }
  }

  /// Clear share links cache
  void clearShareLinks() {
    _shareLinks = null;
    notifyListeners();
  }


  // ========== LOGOUT ==========

  @override
  Future<void> logout() async {
    // Clear sharing data
    _shareLinks = null;
    _isGeneratingShareLink = false;

    // Call parent logout
    if (_token != null) {
      await _authService.logout(_token!);
    }

    await _cacheService.clearUserCache();

    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _email = null;
    _user = null;
    _isVerificationPending = false;
    _verificationMethod = null;
    _pendingVerificationEmail = null;

    await _clearAuth();
    notifyListeners();
  }

  String _getConnectionErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();

    if (errorString.contains('connection refused') ||
        errorString.contains('errno = 111')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet e intenta nuevamente.';
    }

    if (errorString.contains('timeout')) {
      return 'La conexión tardó demasiado. Por favor, intenta nuevamente.';
    }

    if (errorString.contains('no internet') ||
        errorString.contains('network unreachable')) {
      return 'Sin conexión a internet. Verifica tu conexión e intenta de nuevo.';
    }

    if (errorString.contains('socketexception') ||
        errorString.contains('clientexception')) {
      return 'Problema de conexión. Verifica tu internet e intenta nuevamente.';
    }

    // Error genérico para cualquier otro caso
    return 'Ocurrió un error inesperado. Por favor, intenta nuevamente.';
  }

  // ========== MÉTODOS PRIVADOS ==========

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}

//pasa al principal
/*class AuthProviderGoogle with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  bool _needsTermsAcceptance = false;

  // Getters
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get needsTermsAcceptance => _needsTermsAcceptance;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges.listen((User? user) async {
      _user = user;
      if (user != null) {
        await _loadUserModel();
      } else {
        _userModel = null;
        _needsTermsAcceptance = false;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserModel() async {
    if (_user != null) {
      _userModel = await _authService.getUserData(_user!.uid);
      _needsTermsAcceptance = _userModel?.hasAcceptedTerms == false;
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // === AUTENTICACIÓN CON EMAIL ===

  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = await _authService.signInWithEmail(email, password);

      if (credential?.user != null) {
        await _loadUserModel();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = await _authService.createUserWithEmail(email, password, displayName);

      if (credential?.user != null) {
        await _loadUserModel();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // === AUTENTICACIÓN CON GOOGLE ===

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = await _authService.signInWithGoogle();

      if (credential?.user != null) {
        await _loadUserModel();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // === AUTENTICACIÓN CON APPLE ===

  Future<bool> signInWithApple() async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = await _authService.signInWithApple();

      if (credential?.user != null) {
        await _loadUserModel();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // === GESTIÓN DE TÉRMINOS Y CONDICIONES ===

  Future<bool> acceptTermsAndConditions() async {
    try {
      if (_user != null) {
        await _authService.acceptTermsAndConditions(_user!.uid);
        _needsTermsAcceptance = false;
        await _loadUserModel(); // Recargar datos del usuario
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // === OTRAS FUNCIONES ===

  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
      _needsTermsAcceptance = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      await _user!.reload();
      _user = _authService.currentUser;
      await _loadUserModel();
    }
  }

  void clearError() {
    _setError(null);
  }
}*/

