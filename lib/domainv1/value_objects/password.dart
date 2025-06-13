class Password {
  final String value;

  const Password._(this.value);

  factory Password.create(String password) {
    if (password.isEmpty) {
      throw ArgumentError('Password cannot be empty');
    }

    if (password.length < 8) {
      throw ArgumentError('Password must be at least 8 characters long');
    }

    if (!_hasUpperCase(password)) {
      throw ArgumentError('Password must contain at least one uppercase letter');
    }

    if (!_hasLowerCase(password)) {
      throw ArgumentError('Password must contain at least one lowercase letter');
    }

    if (!_hasDigit(password)) {
      throw ArgumentError('Password must contain at least one digit');
    }

    if (!_hasSpecialChar(password)) {
      throw ArgumentError('Password must contain at least one special character');
    }

    return Password._(password);
  }

  // Métodos de validación privados
  static bool _hasUpperCase(String str) => RegExp(r'[A-Z]').hasMatch(str);
  static bool _hasLowerCase(String str) => RegExp(r'[a-z]').hasMatch(str);
  static bool _hasDigit(String str) => RegExp(r'\d').hasMatch(str);
  static bool _hasSpecialChar(String str) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(str);

  // Para ocultar el valor real si se imprime
  @override
  String toString() => '***';

  // Obtener el valor real si es necesario
  String get rawValue => value;

  // Comparación por valor
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Password && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
