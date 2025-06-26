
class Password {
  final String value;

  Password._(this.value);

  factory Password(String input) {
    if (input.isEmpty) {
      throw ArgumentError('Contraseña no puede estar vacía');
    }
    if (input.length < 8) {
      throw ArgumentError('Contraseña debe tener al menos 8 caracteres');
    }
    if (!_hasUpperCase(input)) {
      throw ArgumentError('Contraseña debe tener al menos una mayúscula');
    }
    if (!_hasLowerCase(input)) {
      throw ArgumentError('Contraseña debe tener al menos una minúscula');
    }
    if (!_hasNumber(input)) {
      throw ArgumentError('Contraseña debe tener al menos un número');
    }
    return Password._(input);
  }

  static bool _hasUpperCase(String password) => password.contains(RegExp(r'[A-Z]'));
  static bool _hasLowerCase(String password) => password.contains(RegExp(r'[a-z]'));
  static bool _hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Password && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '***'; // No mostrar la contraseña real
}