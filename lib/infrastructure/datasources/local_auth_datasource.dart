import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domainv1/entities/auth_token_entity.dart';
import '../../domainv1/entities/user_entity.dart';


abstract class LocalAuthDataSource {
  Future<void> saveToken(AuthTokenEntity token);
  Future<AuthTokenEntity?> getToken();
  Future<void> clearToken();
  Future<void> saveUser(UserEntity user);
  Future<UserEntity?> getUser();
  Future<void> clearUser();
  Future<void> saveBiometricData(String email, String hashedPassword);
  Future<Map<String, String>?> getBiometricData();
  Future<void> clearBiometricData();
  Future<void> saveRememberMe(bool remember);
  Future<bool> getRememberMe();
  Future<void> clearAll();
}

class LocalAuthDataSourceImpl implements LocalAuthDataSource {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  LocalAuthDataSourceImpl({
    required SharedPreferences prefs,
    required FlutterSecureStorage secureStorage,
  }) : _prefs = prefs, _secureStorage = secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userKey = 'user_data';
  static const String _biometricEmailKey = 'biometric_email';
  static const String _biometricPasswordKey = 'biometric_password';
  static const String _rememberMeKey = 'remember_me';

  @override
  Future<void> saveToken(AuthTokenEntity token) async {
    await _secureStorage.write(key: _tokenKey, value: token.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: token.refreshToken);
    await _prefs.setString(_tokenExpiryKey, token.expiresAt.toIso8601String());
  }

  @override
  Future<AuthTokenEntity?> getToken() async {
    final accessToken = await _secureStorage.read(key: _tokenKey);
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    final expiryString = _prefs.getString(_tokenExpiryKey);

    if (accessToken == null || refreshToken == null || expiryString == null) {
      return null;
    }

    final expiresAt = DateTime.parse(expiryString);

    return AuthTokenEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _prefs.remove(_tokenExpiryKey);
  }

  @override
  Future<void> saveUser(UserEntity user) async {
    final userData = jsonEncode({
      'id': user.id,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'email': user.email,
      'phone': user.phone,
      'cnpCode': user.cnpCode,
      'specialty': user.specialty,
      'masterDegree': user.masterDegree,
      'otherSpecialty': user.otherSpecialty,
      'location': user.location,
      'address': user.address,
      'isEmailVerified': user.isEmailVerified,
      'isActive': user.isActive,
      'status': user.status.name,
      'createdAt': user.createdAt?.toIso8601String(),
      'updatedAt': user.updatedAt?.toIso8601String(),
    });

    await _secureStorage.write(key: _userKey, value: userData);
  }

  @override
  Future<UserEntity?> getUser() async {
    final userData = await _secureStorage.read(key: _userKey);
    if (userData == null) return null;

    try {
      final json = jsonDecode(userData);
      return UserEntity(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        email: json['email'],
        phone: json['phone'],
        cnpCode: json['cnpCode'],
        cnpPhotos: [], // Las fotos no se guardan localmente por seguridad
        specialty: json['specialty'],
        masterDegree: json['masterDegree'],
        otherSpecialty: json['otherSpecialty'],
        location: json['location'],
        address: json['address'],
        isEmailVerified: json['isEmailVerified'] ?? false,
        isActive: json['isActive'] ?? false,
        status: UserStatus.values.firstWhere(
              (status) => status.name == json['status'],
          orElse: () => UserStatus.pending,
        ),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  @override
  Future<void> clearUser() async {
    await _secureStorage.delete(key: _userKey);
  }

  @override
  Future<void> saveBiometricData(String email, String hashedPassword) async {
    await _secureStorage.write(key: _biometricEmailKey, value: email);
    await _secureStorage.write(key: _biometricPasswordKey, value: hashedPassword);
  }

  @override
  Future<Map<String, String>?> getBiometricData() async {
    final email = await _secureStorage.read(key: _biometricEmailKey);
    final password = await _secureStorage.read(key: _biometricPasswordKey);

    if (email == null || password == null) return null;

    return {
      'email': email,
      'password': password,
    };
  }

  @override
  Future<void> clearBiometricData() async {
    await _secureStorage.delete(key: _biometricEmailKey);
    await _secureStorage.delete(key: _biometricPasswordKey);
  }

  @override
  Future<void> saveRememberMe(bool remember) async {
    await _prefs.setBool(_rememberMeKey, remember);
  }

  @override
  Future<bool> getRememberMe() async {
    return _prefs.getBool(_rememberMeKey) ?? false;
  }

  @override
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
    await clearBiometricData();
    await _prefs.remove(_rememberMeKey);
  }
}