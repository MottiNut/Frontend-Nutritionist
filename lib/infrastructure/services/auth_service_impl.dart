/*

import '../../domain/repositories/auth_repository.dart';
import '../../domainv1/models/auth_result.dart';
import '../../domainv1/models/sign_up_data.dart';
import '../../domainv1/services/auth_service.dart';
import '../../domainv1/services/biometric_service.dart';

class AuthServiceImpl implements AuthService {
  final AuthRepository _authRepository;
  final BiometricService _biometricService;

  AuthServiceImpl({
    required AuthRepository authRepository,
    required BiometricService biometricService,
  })  : _authRepository = authRepository,
        _biometricService = biometricService;

  @override
  Future<AuthResult> register(SignUpData data) async {
    return await _authRepository.signUp(data);
  }

  @override
  Future<AuthResult> login(String email, String password) async {
    return await _authRepository.signIn(email, password);
  }

  @override
  Future<AuthResult> loginWithBiometrics() async {
    try {
      final isAvailable = await _biometricService.isAvailable();
      if (!isAvailable) {
        return AuthResult.failure('Biometría no disponible');
      }

      final authenticated = await _biometricService.authenticate(
          'Usar huella dactilar para iniciar sesión'
      );

      if (!authenticated) {
        return AuthResult.failure('Autenticación biométrica fallida');
      }

      return await _authRepository.signInWithBiometrics();
    } catch (e) {
      return AuthResult.failure('Error en autenticación biométrica');
    }
  }

  @override
  Future<void> logout() async {
    await _authRepository.signOut();
  }

  @override
  Future<bool> sendEmailVerification(String email) async {
    return await _authRepository.sendVerificationCode(email);
  }

  @override
  Future<bool> verifyEmailCode(String email, String code) async {
    return await _authRepository.verifyEmail(email, code);
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await _authRepository.getCurrentUser();
  }

  @override
  Future<bool> refreshAuthentication() async {
    try {
      // Implementar lógica de refresh token
      return true;
    } catch (e) {
      return false;
    }
  }
}*/