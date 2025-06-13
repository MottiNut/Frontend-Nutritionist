import '../entities/auth_token_entity.dart';
import '../entities/user_entity.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserEntity? user;
  final AuthTokenEntity? token;
  final String? verificationCode;

  const AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.user,
    this.token,
    this.verificationCode,
  });

  factory AuthResult.success({
    UserEntity? user,
    AuthTokenEntity? token,
    String? verificationCode,
  }) {
    return AuthResult(
      isSuccess: true,
      user: user,
      token: token,
      verificationCode: verificationCode,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}