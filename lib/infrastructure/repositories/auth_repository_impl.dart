import 'dart:io';

import '../../domain/repositories/auth_repository.dart';
import '../../domainv1/entities/auth_token_entity.dart';
import '../../domainv1/entities/user_entity.dart';
import '../../domainv1/exceptions/auth_exceptions.dart';
import '../../domainv1/models/auth_result.dart';
import '../../domainv1/models/sign_up_data.dart';
import '../datasources/local_auth_datasource.dart';
import '../datasources/remote_auth_datasource.dart';
import '../services/encryption_service_impl.dart';


/*class AuthRepositoryImpl implements AuthRepository {
  final RemoteAuthDataSource _remoteDataSource;
  final LocalAuthDataSource _localDataSource;
  final EncryptionServiceImpl _encryptionService;

  AuthRepositoryImpl({
    required RemoteAuthDataSource remoteDataSource,
    required LocalAuthDataSource localDataSource,
    required EncryptionServiceImpl encryptionService,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _encryptionService = encryptionService;

  @override
  Future<AuthResult> signUp(SignUpData data) async {
    try {
      // Verificar si el email ya existe
      final emailExists = await checkEmailExists(data.email);
      if (emailExists) {
        return AuthResult.failure('El email ya está registrado');
      }

      // Verificar código CNP
      final cnpValid = await verifyCNPCode(data.cnpCode);
      if (!cnpValid) {
        return AuthResult.failure('Código CNP inválido');
      }

      // Realizar registro
      final response = await _remoteDataSource.signUp(data);

      // Convertir respuesta a entidades
      final user = _mapResponseToUser(response['user']);
      final token = _mapResponseToToken(response['token']);

      // Guardar localmente
      await _localDataSource.saveUser(user);
      await _localDataSource.saveToken(token);

      return AuthResult.success(user: user, token: token);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Error inesperado en el registro');
    }
  }

  @override
  Future<AuthResult> signIn(String email, String password) async {
    try {
      final response = await _remoteDataSource.signIn(email, password);

      final user = _mapResponseToUser(response['user']);
      final token = _mapResponseToToken(response['token']);

      // Guardar localmente
      await _localDataSource.saveUser(user);
      await _localDataSource.saveToken(token);

      return AuthResult.success(user: user, token: token);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Error en el inicio de sesión');
    }
  }

  @override
  Future<AuthResult> signInWithBiometrics() async {
    try {
      final biometricData = await _localDataSource.getBiometricData();
      if (biometricData == null) {
        return AuthResult.failure('No hay datos biométricos guardados');
      }

      return await signIn(biometricData['email']!, biometricData['password']!);
    } catch (e) {
      return AuthResult.failure('Error en autenticación biométrica');
    }
  }

  @override
  Future<AuthResult> refreshToken(String refreshToken) async {
    try {
      final response = await _remoteDataSource.refreshToken(refreshToken);
      final token = _mapResponseToToken(response['token']);

      await _localDataSource.saveToken(token);

      return AuthResult.success(token: token);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Error al renovar token');
    }
  }

  @override
  Future<void> signOut() async {
    await _localDataSource.clearAll();
  }

  @override
  Future<bool> sendVerificationCode(String email) async {
    try {
      return await _remoteDataSource.sendVerificationCode(email);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> verifyEmail(String email, String code) async {
    try {
      return await _remoteDataSource.verifyEmail(email, code);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> resetPassword(String email) async {
    try {
      return await _remoteDataSource.sendVerificationCode(email);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> changePassword(String email, String oldPassword, String newPassword) async {
    // Implementar según tu API
    return false;
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    return await _remoteDataSource.checkEmailExists(email);
  }

  @override
  Future<bool> verifyCNPCode(String cnpCode) async {
    return await _remoteDataSource.verifyCNPCode(cnpCode);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final token = await _localDataSource.getToken();
      if (token == null || token.isExpired) {
        return null;
      }

      final response = await _remoteDataSource.getCurrentUser(token.accessToken);
      final user = _mapResponseToUser(response['user']);

      await _localDataSource.saveUser(user);
      return user;
    } catch (e) {
      return await _localDataSource.getUser();
    }
  }

  @override
  Future<bool> updateProfile(UserEntity user) async {
    try {
      // Implementar según tu API
      await _localDataSource.saveUser(user);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Métodos helper para mapear respuestas
  UserEntity _mapResponseToUser(Map<String, dynamic> userData) {
    return UserEntity(
      id: userData['id']?.toString(),
      firstName: userData['firstName'] ?? userData['first_name'] ?? '',
      lastName: userData['lastName'] ?? userData['last_name'] ?? '',
      email: userData['email'] ?? '',
      phone: userData['phone'],
      cnpCode: userData['cnpCode'] ?? userData['cnp_code'] ?? '',
      cnpPhotos: [], // Las fotos no se devuelven en la respuesta
      specialty: userData['specialty'] ?? '',
      masterDegree: userData['masterDegree'] ?? userData['master_degree'],
      otherSpecialty: userData['otherSpecialty'] ?? userData['other_specialty'],
      location: userData['location'] ?? '',
      address: userData['address'] ?? '',
      isEmailVerified: userData['isEmailVerified'] ?? userData['is_email_verified'] ?? false,
      isActive: userData['isActive'] ?? userData['is_active'] ?? false,
      status: _mapStringToUserStatus(userData['status']),
      createdAt: userData['createdAt'] != null || userData['created_at'] != null
          ? DateTime.parse(userData['createdAt'] ?? userData['created_at'])
          : null,
      updatedAt: userData['updatedAt'] != null || userData['updated_at'] != null
          ? DateTime.parse(userData['updatedAt'] ?? userData['updated_at'])
          : null,
    );
  }

  AuthTokenEntity _mapResponseToToken(Map<String, dynamic> tokenData) {
    return AuthTokenEntity(
      accessToken: tokenData['accessToken'] ?? tokenData['access_token'] ?? '',
      refreshToken: tokenData['refreshToken'] ?? tokenData['refresh_token'] ?? '',
      expiresAt: tokenData['expiresAt'] != null || tokenData['expires_at'] != null
          ? DateTime.parse(tokenData['expiresAt'] ?? tokenData['expires_at'])
          : DateTime.now().add(const Duration(hours: 24)),
      tokenType: tokenData['tokenType'] ?? tokenData['token_type'] ?? 'Bearer',
    );
  }

  UserStatus _mapStringToUserStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return UserStatus.verified;
      case 'active':
        return UserStatus.active;
      case 'suspended':
        return UserStatus.suspended;
      case 'rejected':
        return UserStatus.rejected;
      default:
        return UserStatus.pending;
    }
  }
}*/