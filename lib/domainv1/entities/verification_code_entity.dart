class VerificationCodeEntity {
  final String code;
  final String email;
  final DateTime expiresAt;
  final VerificationType type;
  final bool isUsed;

  const VerificationCodeEntity({
    required this.code,
    required this.email,
    required this.expiresAt,
    required this.type,
    this.isUsed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;
}

enum VerificationType {
  emailVerification,
  passwordReset,
  loginVerification
}