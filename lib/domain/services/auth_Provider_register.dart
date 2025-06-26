/*import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';


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
  String? _pendingVerificationUserId;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isVerificationPending => _isVerificationPending;
  String? get verificationMethod => _verificationMethod;
  String? get pendingVerificationUserId => _pendingVerificationUserId;

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

      _isAuthenticated = _token != null && _userId != null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
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
    } catch (e) {
      debugPrint('Error clearing auth: $e');
    }
  }

  // ========== AUTENTICACIÓN ==========

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.isSuccess) {
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

  Future<RegisterResult> registerNutritionist({
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
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.registerNutritionist(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        cnpCode: cnpCode,
        cnpPhotos: cnpPhotos,
        specialty: specialty,
        masterDegree: masterDegree,
        otherSpecialty: otherSpecialty,
        location: location,
        address: address,
        profilePhoto: profilePhoto,
      );

      if (response.isSuccess) {
        _pendingVerificationUserId = response.userId;
        _email = email;
        _isVerificationPending = true;
        notifyListeners();

        return RegisterResult.success(
          userId: response.userId!,
          message: response.message ?? 'Registro exitoso',
        );
      } else {
        _setError(response.message ?? 'Error en el registro');
        return RegisterResult.error(response.message ?? 'Error en el registro');
      }
    } catch (e) {
      final errorMsg = 'Error de conexión: ${e.toString()}';
      _setError(errorMsg);
      return RegisterResult.error(errorMsg);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _email = null;
    _user = null;
    _isVerificationPending = false;
    _verificationMethod = null;
    _pendingVerificationUserId = null;

    await _clearAuth();
    notifyListeners();
  }

  // ========== VERIFICACIÓN ==========

  Future<bool> sendVerificationCode({
    required VerificationMethod method,
    String? phoneNumber,
  }) async {
    if (_pendingVerificationUserId == null && _email == null) {
      _setError('No hay usuario pendiente de verificación');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      AuthResponse response;

      switch (method) {
        case VerificationMethod.email:
          response = await _authService.sendEmailVerification(
            email: _email!,
            userId: _pendingVerificationUserId,
          );
          break;
        case VerificationMethod.sms:
          if (phoneNumber == null) {
            _setError('Número de teléfono requerido para SMS');
            return false;
          }
          response = await _authService.sendSmsVerification(
            phoneNumber: phoneNumber,
            userId: _pendingVerificationUserId,
          );
          break;
        case VerificationMethod.whatsapp:
          if (phoneNumber == null) {
            _setError('Número de teléfono requerido para WhatsApp');
            return false;
          }
          response = await _authService.sendWhatsAppVerification(
            phoneNumber: phoneNumber,
            userId: _pendingVerificationUserId,
          );
          break;
      }

      if (response.isSuccess) {
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

  Future<bool> verifyCode({
    required String code,
  }) async {
    if (_pendingVerificationUserId == null || _verificationMethod == null) {
      _setError('No hay verificación pendiente');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyCode(
        userId: _pendingVerificationUserId!,
        code: code,
        method: _verificationMethod!,
      );

      if (response.isSuccess) {
        if (response.token != null) {
          // Usuario verificado y autenticado
          await _handleAuthSuccess(response);
        }

        // Limpiar estado de verificación
        _isVerificationPending = false;
        _verificationMethod = null;
        _pendingVerificationUserId = null;

        return true;
      } else {
        _setError(response.message ?? 'Código de verificación inválido');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendVerificationCode() async {
    if (_pendingVerificationUserId == null || _verificationMethod == null) {
      _setError('No hay verificación pendiente');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resendVerificationCode(
        userId: _pendingVerificationUserId!,
        method: _verificationMethod!,
      );

      if (response.isSuccess) {
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

  Future<bool> requestPasswordReset({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.requestPasswordReset(email: email);

      if (response.isSuccess) {
        return true;
      } else {
        _setError(response.message ?? 'Error solicitando reset de contraseña');
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
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resetPassword(
        token: token,
        newPassword: newPassword,
      );

      if (response.isSuccess) {
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
    if (_userId == null || _token == null) {
      _setError('Usuario no autenticado');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.updatePassword(
        userId: _userId!,
        currentPassword: currentPassword,
        newPassword: newPassword,
        token: _token!,
      );

      if (response.isSuccess) {
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

  void _clearError() {
    _errorMessage = null;
  }
}

// ========== ENUMS Y MODELOS ==========

enum VerificationMethod {
  email,
  sms,
  whatsapp,
}

extension VerificationMethodExtension on VerificationMethod {
  String get displayName {
    switch (this) {
      case VerificationMethod.email:
        return 'Email';
      case VerificationMethod.sms:
        return 'SMS';
      case VerificationMethod.whatsapp:
        return 'WhatsApp';
    }
  }

  String get description {
    switch (this) {
      case VerificationMethod.email:
        return 'Te enviaremos un código a tu correo electrónico';
      case VerificationMethod.sms:
        return 'Recibirás un código por mensaje de texto';
      case VerificationMethod.whatsapp:
        return 'Te llegará un código por WhatsApp';
    }
  }
}

class RegisterResult {
  final bool isSuccess;
  final String message;
  final String? userId;

  RegisterResult._({
    required this.isSuccess,
    required this.message,
    this.userId,
  });

  factory RegisterResult.success({
    required String userId,
    required String message,
  }) {
    return RegisterResult._(
      isSuccess: true,
      message: message,
      userId: userId,
    );
  }

  factory RegisterResult.error(String message) {
    return RegisterResult._(
      isSuccess: false,
      message: message,
    );
  }
}*/