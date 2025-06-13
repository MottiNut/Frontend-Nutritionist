import '../entities/user_entity.dart';
import '../models/auth_result.dart';
import '../models/sign_up_data.dart';

abstract class AuthService {
  Future<AuthResult> register(SignUpData data);
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> loginWithBiometrics();
  Future<void> logout();
  Future<bool> sendEmailVerification(String email);
  Future<bool> verifyEmailCode(String email, String code);
  Future<bool> isLoggedIn();
  Future<UserEntity?> getCurrentUser();
  Future<bool> refreshAuthentication();
}

