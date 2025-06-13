abstract class AuthException implements Exception {
  final String message;
  final String code;

  const AuthException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'AuthException: $message (Code: $code)';
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super(
    message: 'Invalid email or password',
    code: 'INVALID_CREDENTIALS',
  );
}

class EmailAlreadyExistsException extends AuthException {
  const EmailAlreadyExistsException()
      : super(
    message: 'An account with this email already exists',
    code: 'EMAIL_EXISTS',
  );
}

class InvalidVerificationCodeException extends AuthException {
  const InvalidVerificationCodeException()
      : super(
    message: 'Invalid or expired verification code',
    code: 'INVALID_VERIFICATION_CODE',
  );
}

class CNPCodeInvalidException extends AuthException {
  const CNPCodeInvalidException()
      : super(
    message: 'Invalid CNP code',
    code: 'INVALID_CNP_CODE',
  );
}

class NetworkException extends AuthException {
  const NetworkException()
      : super(
    message: 'Network connection error',
    code: 'NETWORK_ERROR',
  );
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException()
      : super(
    message: 'Unauthorized access',
    code: 'UNAUTHORIZED',
  );
}

class ServerException extends AuthException {
  const ServerException([String? message])
      : super(
    message: message ?? 'Server error occurred',
    code: 'SERVER_ERROR',
  );
}

class BiometricAuthException extends AuthException {
  const BiometricAuthException()
      : super(
    message: 'Biometric authentication failed',
    code: 'BIOMETRIC_AUTH_FAILED',
  );
}