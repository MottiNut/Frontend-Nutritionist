import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'mottinut_app',
      synchronizable: false,
    ),
  );

  // Constantes para las llaves
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _userTokenKey = 'user_token';
  static const String _userIdKey = 'user_id';

  // ✅ Guardar credenciales de login
  static Future<bool> saveLoginCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      if (rememberMe) {
        await _secureStorage.write(key: _emailKey, value: email);
        await _secureStorage.write(key: _passwordKey, value: password);
        await _secureStorage.write(key: _rememberMeKey, value: 'true');
      } else {
        await clearLoginCredentials();
      }
      return true;
    } catch (e) {
      print('❌ Error guardando credenciales: $e');
      return false;
    }
  }

  // ✅ Cargar credenciales guardadas
  static Future<Map<String, dynamic>> loadLoginCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);
      final rememberMe = await _secureStorage.read(key: _rememberMeKey);

      return {
        'email': email ?? '',
        'password': password ?? '',
        'rememberMe': rememberMe == 'true',
        'hasCredentials': email != null && password != null && rememberMe == 'true',
      };
    } catch (e) {
      print('❌ Error cargando credenciales: $e');
      return {
        'email': '',
        'password': '',
        'rememberMe': false,
        'hasCredentials': false,
      };
    }
  }

  // ✅ Limpiar credenciales de login
  static Future<bool> clearLoginCredentials() async {
    try {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.delete(key: _rememberMeKey);
      return true;
    } catch (e) {
      print('❌ Error limpiando credenciales: $e');
      return false;
    }
  }

  // ✅ Guardar token de sesión
  static Future<bool> saveUserSession({
    required String token,
    required String userId,
  }) async {
    try {
      await _secureStorage.write(key: _userTokenKey, value: token);
      await _secureStorage.write(key: _userIdKey, value: userId);
      return true;
    } catch (e) {
      print('❌ Error guardando sesión: $e');
      return false;
    }
  }

  // ✅ Obtener token de sesión
  static Future<String?> getUserToken() async {
    try {
      return await _secureStorage.read(key: _userTokenKey);
    } catch (e) {
      print('❌ Error obteniendo token: $e');
      return null;
    }
  }

  // ✅ Obtener ID de usuario
  static Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: _userIdKey);
    } catch (e) {
      print('❌ Error obteniendo user ID: $e');
      return null;
    }
  }

  // ✅ Limpiar toda la sesión (logout)
  static Future<bool> clearUserSession() async {
    try {
      await _secureStorage.delete(key: _userTokenKey);
      await _secureStorage.delete(key: _userIdKey);
      return true;
    } catch (e) {
      print('❌ Error limpiando sesión: $e');
      return false;
    }
  }

  // ✅ Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    try {
      final token = await _secureStorage.read(key: _userTokenKey);
      final userId = await _secureStorage.read(key: _userIdKey);
      return token != null && userId != null;
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      return false;
    }
  }

  // ✅ Limpiar todo el almacenamiento
  static Future<bool> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      print('❌ Error limpiando todo: $e');
      return false;
    }
  }
}