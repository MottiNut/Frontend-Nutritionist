import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

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
class AuthService {
  static const String baseUrl = 'http://192.168.0.4:5000/api/bff/auth';

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
      final response = await _client.get(
        Uri.parse('$baseUrl/me'), // o crear endpoint específico
        headers: _headersWithAuth(token),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(responseData);
      } else {
        return AuthResponse(
          success: false,
          message: responseData['message'] ?? 'Error obteniendo perfil',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
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

  // ========== VERIFICACIÓN ==========

  Future<bool> loadUserProfile() async {
    if (_token == null) return false;

    _setLoading(true);

    try {
      final response = await _authService.getNutritionistProfile(_token!);

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

