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

import 'firebase_auth_service.dart';

///pruebas de comprimir
class ImageCompressionUtils {
  /// Comprime una imagen y retorna un archivo temporal
  /// [imageFile] - Archivo de imagen original
  /// [quality] - Calidad de compresión (0-100, default: 85)
  /// [maxWidth] - Ancho máximo en píxeles (default: 1200)
  /// [maxHeight] - Alto máximo en píxeles (default: 1600)
  static Future<File> compressImage(
      File imageFile, {
        int quality = 85,
        int maxWidth = 1200,
        int maxHeight = 1600,
      }) async {
    try {
      debugPrint('=== COMPRIMIENDO IMAGEN ===');
      debugPrint('Archivo original: ${imageFile.path}');
      debugPrint('Tamaño original: ${imageFile.lengthSync()} bytes');

      // Leer la imagen original
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decodificar la imagen
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      debugPrint('Dimensiones originales: ${originalImage.width}x${originalImage.height}');

      // Calcular nuevas dimensiones manteniendo la proporción
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxWidth || newHeight > maxHeight) {
        double aspectRatio = newWidth / newHeight;

        if (aspectRatio > 1) {
          // Imagen horizontal
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        } else {
          // Imagen vertical
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      }

      // Redimensionar la imagen si es necesario
      img.Image resizedImage = originalImage;
      if (newWidth != originalImage.width || newHeight != originalImage.height) {
        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
        debugPrint('Nuevas dimensiones: ${newWidth}x${newHeight}');
      }

      // Comprimir la imagen
      List<int> compressedBytes;
      String extension = path.extension(imageFile.path).toLowerCase();

      if (extension == '.png') {
        // Para PNG, convertir a JPEG para mejor compresión
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        extension = '.jpg';
      } else {
        // Para JPEG y otros formatos
        compressedBytes = img.encodeJpg(resizedImage, quality: quality);
        extension = '.jpg';
      }

      // Crear archivo temporal con la imagen comprimida
      final String fileName = path.basenameWithoutExtension(imageFile.path);
      final String tempPath = '${imageFile.parent.path}/${fileName}_compressed$extension';
      final File compressedFile = File(tempPath);

      await compressedFile.writeAsBytes(compressedBytes);

      debugPrint('Archivo comprimido: ${compressedFile.path}');
      debugPrint('Tamaño comprimido: ${compressedFile.lengthSync()} bytes');
      debugPrint('Reducción: ${((1 - compressedFile.lengthSync() / imageFile.lengthSync()) * 100).toStringAsFixed(1)}%');

      return compressedFile;
    } catch (e) {
      debugPrint('Error comprimiendo imagen: $e');
      // Si hay error, retornar el archivo original
      return imageFile;
    }
  }

  /// Comprime múltiples imágenes de forma paralela
  static Future<List<File>> compressMultipleImages(
      List<File> imageFiles, {
        int quality = 85,
        int maxWidth = 1200,
        int maxHeight = 1600,
      }) async {
    final List<Future<File>> compressionTasks = imageFiles.map((file) =>
        compressImage(file, quality: quality, maxWidth: maxWidth, maxHeight: maxHeight)
    ).toList();

    return await Future.wait(compressionTasks);
  }

  /// Limpia archivos temporales de compresión
  static Future<void> cleanupTempFiles(List<File> files) async {
    for (File file in files) {
      if (file.path.contains('_compressed') && file.existsSync()) {
        try {
          await file.delete();
        } catch (e) {
          debugPrint('Error eliminando archivo temporal: $e');
        }
      }
    }
  }
}

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


class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? userId;
  final String? email;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? verificationStatus; // Nueva propiedad

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
    // Si hay token, entonces es success
    bool isSuccess = json['success'] ?? (json['token'] != null);

    // Construir user data desde la respuesta directa si no hay campo 'user'
    Map<String, dynamic>? userData;
    if (json['user'] != null) {
      userData = Map<String, dynamic>.from(json['user']);
    } else if (json['token'] != null) {
      // Construir userData desde los campos directos de la respuesta
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
      verificationStatus: json['verificationStatus'] as Map<String, dynamic>?, // Nueva propiedad
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
      'verificationStatus': verificationStatus, // Nueva propiedad
    };
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
class AuthService {
  static const String baseUrl = 'https://mottinut-backend-2025-djf0f5c0hjckhpgp.centralus-01.azurewebsites.net/api/bff/auth';

  final http.Client _client = http.Client();

  // Headers comunes
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _headersWithAuth(String token) => {
    ..._headers,
    'Authorization': 'Bearer $token',
  };

  String? getProfileImageUrl(int? userId) {
    if (userId == null) return null;

    return '$baseUrl/profile/nutritionist/$userId/image';
  }

  // ========== MÉTODOS DE AUTENTICACIÓN ==========

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/login'),
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
        Uri.parse('$baseUrl/register/nutritionist'),
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

  Future<AuthResponse> updateProfile({
    required String token,
    required int userId,
    String? firstName,
    String? lastName,
    String? phone,
    int? yearOfExperience,
    String? biography,
  }) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/profile/nutritionist/$userId'),
        headers: _headersWithAuth(token),
        body: json.encode({
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (phone != null) 'phone': phone,
          if (yearOfExperience != null) 'yearOfExperience': yearOfExperience,
          if (biography != null) 'biography': biography,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error actualizando perfil',
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
      final response = await _client.post(
        Uri.parse('$baseUrl/verification/send'),
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
        Uri.parse('$baseUrl/verification/verify'),
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
        Uri.parse('$baseUrl/verification/resend'),
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
        Uri.parse('$baseUrl/password/reset-request'),
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
        Uri.parse('$baseUrl/password/reset'),
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
        Uri.parse('$baseUrl/password/update'),
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
        Uri.parse('$baseUrl/validate'),
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

  // Obtener perfil completo del nutricionista
  Future<AuthResponse> getNutritionistProfile(String token) async {
    try {
      print('🔄 Obteniendo perfil con token: ${token.substring(0, 20)}...');

      final response = await _client.get(
        Uri.parse('$baseUrl/me'),
        headers: _headersWithAuth(token),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Validar que la respuesta tenga la estructura correcta
        if (responseData is Map<String, dynamic>) {
          return AuthResponse(
            success: true,
            message: 'Perfil obtenido exitosamente',
            user: responseData, // Pasar directamente los datos del usuario
          );
        } else {
          return AuthResponse(
            success: false,
            message: 'Estructura de respuesta inválida',
          );
        }
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error obteniendo perfil',
        );
      }
    } catch (e) {
      print('❌ Error en getNutritionistProfile: $e');
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  Future<AuthResponse> checkProfileImageExists(String token, int userId) async {
    try {
      final response = await _client.head(
        Uri.parse('$baseUrl/profile/nutritionist/$userId/image'),
        headers: _headersWithAuth(token),
      );

      return AuthResponse(
        success: response.statusCode == 200,
        message: response.statusCode == 200 ? 'Imagen disponible' : 'Imagen no encontrada',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error verificando imagen: ${e.toString()}',
      );
    }
  }

  // ========== LOGOUT ==========
  Future<AuthResponse> logout(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/logout'),
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

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    int? yearOfExperience,
    String? biography,
  }) async {
    if (_token == null || _userId == null) {
      _setError('Usuario no autenticado');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      // Usar el método updateProfile del AuthService
      final response = await _authService.updateProfile(
        token: _token!,
        userId: int.parse(_userId!),
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        yearOfExperience: yearOfExperience,
        biography: biography,
      );

      if (response.success) {
        // Actualizar los datos locales si la respuesta fue exitosa
        if (_user != null) {
          // Actualizar solo los campos que se enviaron
          if (firstName != null) _user!['firstName'] = firstName;
          if (lastName != null) _user!['lastName'] = lastName;
          if (phone != null) _user!['phone'] = phone;
          if (yearOfExperience != null) _user!['yearOfExperience'] = yearOfExperience;
          if (biography != null) _user!['biography'] = biography;

          // Guardar los datos actualizados en SharedPreferences
          await _saveAuth(
            token: _token!,
            userId: _userId!,
            email: _email!,
            userData: _user,
          );
        }

        // Si el response incluye datos del usuario actualizados, usarlos
        if (response.user != null) {
          _user = response.user;
          await _saveAuth(
            token: _token!,
            userId: _userId!,
            email: _email!,
            userData: _user,
          );
        }

        // Notificar a los listeners que los datos han cambiado
        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Error al actualizar el perfil');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      debugPrint('Error en updateProfile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== VERIFICACIÓN ==========

  Future<bool> loadUserProfile() async {
    if (_token == null) {
      print('❌ No hay token disponible');
      _setError('No hay token de autenticación');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      print('🔄 Cargando perfil del usuario...');
      final response = await _authService.getNutritionistProfile(_token!);

      print('📱 Response success: ${response.success}');
      print('📱 Response user: ${response.user}');

      if (response.success && response.user != null) {
        _user = response.user;
        _setError(null);

        print('✅ Perfil cargado exitosamente');
        print('👤 Datos del usuario: $_user');

        notifyListeners();
        return true;
      } else {
        _setError(response.message ?? 'Error desconocido al cargar perfil');
        print('❌ Error cargando perfil: ${response.message}');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      print('❌ Excepción en loadUserProfile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String? getProfileImageUrl() {
    if (user == null) return null;

    // Primero verifica si hay una URL directa en los datos del usuario
    final userId = user!['id'] ?? user!['userId'];
    final directUrl = user!['profileImageUrl'] ??
        user!['profileImage'] ??
        user!['profile_image'] ??
        user!['avatar'] ??
        user!['photo'] ??
        user!['imageUrl'] ??
        user!['image_url'];

    // Si no hay URL directa, construye la URL del endpoint
    if ((directUrl == null || directUrl.isEmpty) && userId != null) {
      return _authService.getProfileImageUrl(userId);
    }

    return directUrl;
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

