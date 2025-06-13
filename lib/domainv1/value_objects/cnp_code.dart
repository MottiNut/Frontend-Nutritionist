class CNPCode {
  final String value;

  const CNPCode._(this.value);

  factory CNPCode.create(String code) {
    if (code.isEmpty) {
      throw ArgumentError('Código CNP no puede estar vacío');
    }
    if (code.length != 4) {
      throw ArgumentError('Código CNP debe tener exactamente 4 dígitos');
    }
    if (!_isNumeric(code)) {
      throw ArgumentError('Código CNP debe contener solo números');
    }
    return CNPCode._(code);
  }

  static bool _isNumeric(String s) => RegExp(r'^\d{4}$').hasMatch(s);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CNPCode && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
