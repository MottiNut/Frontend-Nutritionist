class Email {
  final String value;

  Email._(this.value);

  factory Email(String input) {
    if (input.isEmpty) {
      throw ArgumentError('Email no puede estar vacío');
    }
    if (!_isValidEmail(input)) {
      throw ArgumentError('Email inválido');
    }
    return Email._(input);
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Email && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
