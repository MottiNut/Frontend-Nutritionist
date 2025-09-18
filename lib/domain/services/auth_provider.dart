import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

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

  // Endpoints específicos
  static const String loginEndpoint = '$baseUrl/login';
  static const String registerEndpoint = '$baseUrl/register/nutritionist';
  static const String verificationSendEndpoint = '$baseUrl/verification/send';
  static const String verificationVerifyEndpoint = '$baseUrl/verification/verify';
  static const String verificationResendEndpoint = '$baseUrl/verification/resend';
  static const String passwordResetRequestEndpoint = '$baseUrl/password/reset-request';
  static const String passwordResetEndpoint = '$baseUrl/password/reset';
  static const String passwordUpdateEndpoint = '$baseUrl/password/update';
  static const String validateEndpoint = '$baseUrl/validate';
  static const String logoutEndpoint = '$baseUrl/logout';
  static const String nutritionistProfileEndpoint = '$profileBaseUrl/nutritionist';
  static const String nutritionistImageEndpoint = '$profileBaseUrl/nutritionist';
  static const String meEndpoint = '$baseUrl/me';

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

      debugPrint('Login Response Status: ${response.statusCode}');
      debugPrint('Login Response Body: ${response.body}');

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
      debugPrint('Login Error: $e');
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
      debugPrint('=== AUTHSERVICE: Preparando request multipart ===');

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

      debugPrint('Register Response Status: ${response.statusCode}');
      debugPrint('Register Response Body: ${response.body}');

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
      debugPrint('Register Error: $e');
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
      final response = await _client.post(
        Uri.parse(verificationSendEndpoint),
        headers: _headers,
        body: json.encode({
          'email': email,
          'method': method.name,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        }),
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
          'type': 'email',
          'email': email,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Crear AuthResponse con la información de verificación
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
      debugPrint('Error getting current user: $e');
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
        debugPrint('✅ Imagen encontrada en caché: $imageUrl');
        return cachedFile.file;
      }

      // Si no está en caché, descargarla
      debugPrint('⬇️ Descargando imagen: $imageUrl');
      final File file = await avatarCacheManager.getSingleFile(
        imageUrl,
        headers: headers,
      );

      // Guardar copia local adicional para acceso rápido
      await _saveImageToLocalStorage(file, userId);

      return file;
    } catch (e) {
      debugPrint('❌ Error obteniendo imagen en caché: $e');
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
        debugPrint('💾 Imagen guardada localmente: $localPath');
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

      debugPrint('🚀 Imagen precargada: $imageUrl');

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
      debugPrint('🧹 Caché de avatares limpiado');
    } catch (e) {
      debugPrint('❌ Error limpiando caché: $e');
    }
  }

  /// Obtiene la imagen local si existe
  static Future<File?> getLocalAvatarImage(String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/nutritionist_avatar_$userId.jpg';
      final File localFile = File(localPath);

      if (await localFile.exists()) {
        debugPrint('📁 Imagen encontrada localmente para userId: $userId');
        return localFile;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo imagen local: $e');
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
      debugPrint('Error getting profile: $e');
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

  AuthProvider() {
    _loadStoredAuth();
  }

  // ========== GESTIÓN DE SESIÓN ==========

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
      _setError('Error de conexión: ${e.toString()}');
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
      debugPrint('=== INICIANDO REGISTRO NUTRICIONISTA ===');
      debugPrint('Email: $email');
      debugPrint('CNP Code: $cnpCode');
      debugPrint('Specialty: $specialty');
      debugPrint('Location: $location');
      debugPrint('Address: $address');
      debugPrint('Profile Image exists: ${profileImage.existsSync()}');
      debugPrint('License Front exists: ${licenseFrontImage.existsSync()}');
      debugPrint('License Back exists: ${licenseBackImage.existsSync()}');

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

      debugPrint('=== RESPUESTA DEL AUTHSERVICE ===');
      debugPrint('Success: ${response.success}');
      debugPrint('Token: ${response.token != null ? "SÍ" : "NO"}');
      debugPrint('UserId: ${response.userId}');
      debugPrint('Email: ${response.email}');
      debugPrint('Message: ${response.message}');

      if (response.success) {
        debugPrint('=== PROCESANDO RESPUESTA EXITOSA ===');

        // Verificar si el response tiene información de verificación requerida
        if (response.user != null) {
          final userData = response.user!;
          final requiresVerification = userData['requiresVerification'] ?? false;
          final emailVerified = userData['emailVerified'] ?? false;
          final fullyVerified = userData['fullyVerified'] ?? false;

          debugPrint('=== ESTADO DE VERIFICACIÓN ===');
          debugPrint('RequiresVerification: $requiresVerification');
          debugPrint('EmailVerified: $emailVerified');
          debugPrint('FullyVerified: $fullyVerified');

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

            debugPrint('✅ Verificación pendiente configurada para: $_pendingVerificationEmail');
            notifyListeners();
            return true;
          } else {
            // Usuario completamente verificado
            debugPrint('=== USUARIO COMPLETAMENTE VERIFICADO ===');
            await _handleAuthSuccess(response);
            return true;
          }
        } else {
          // Si no hay user data pero hay token y success, necesita verificación
          debugPrint('=== NO HAY USER DATA, VERIFICANDO TOKEN ===');

          if (response.token != null) {
            debugPrint('=== HAY TOKEN, CONFIGURANDO VERIFICACIÓN PENDIENTE ===');
            _isVerificationPending = true;
            _pendingVerificationEmail = email;
            _token = response.token;
            _userId = response.userId;
            _email = response.email ?? email;
            _isAuthenticated = false;

            debugPrint('✅ Verificación pendiente configurada (sin user data)');
            notifyListeners();
            return true;
          } else {
            debugPrint('=== NO HAY TOKEN, REGISTRO BÁSICO EXITOSO ===');
            _isVerificationPending = true;
            _pendingVerificationEmail = email;
            notifyListeners();
            return true;
          }
        }
      } else {
        debugPrint('=== REGISTRO FALLÓ ===');
        _setError(response.message ?? 'Error en el registro');
        return false;
      }
    } catch (e) {
      debugPrint('=== ERROR EN REGISTRO ===');
      debugPrint('Error: $e');
      _setError('Error de conexión: ${e.toString()}');
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
      debugPrint('Error loading current user: $e');
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

      debugPrint('🔍 Raw response from service:');
      debugPrint('  - success: ${response.success}');
      debugPrint('  - message: ${response.message}');
      debugPrint('  - verificationStatus: ${response.verificationStatus}');

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
          debugPrint('🔧 CORRECCIÓN: Detectado éxito por mensaje a pesar de success=false');
        }
      }

      if (isActualSuccess) {
        debugPrint('✅ Verificación exitosa detectada');

        // Limpiar estado de verificación
        _isVerificationPending = false;
        _verificationMethod = null;
        _pendingVerificationEmail = null;

        // NO autenticar automáticamente - usuario debe hacer login
        debugPrint('✅ Verificación exitosa - Usuario debe hacer login');

        return {
          'success': true,
          'message': response.message ?? 'Verificación exitosa',
          'verificationStatus': response.verificationStatus,
          'isAuthenticated': false, // Siempre false después de verificación
          'requiresLogin': true     // Indicar que necesita login
        };
      } else {
        debugPrint('❌ Verificación falló');
        _setError(response.message ?? 'Código inválido');
        return {
          'success': false,
          'message': response.message ?? 'Código inválido'
        };
      }
    } catch (e) {
      debugPrint('💥 Error en verificación: $e');
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

  // ========== LOGOUT ==========

  Future<void> logout() async {
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

  // ========== MÉTODOS PRIVADOS ==========

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
    }

    notifyListeners();
  }

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

