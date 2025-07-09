class CNPCode {
  final String value;

  CNPCode._(this.value);

  factory CNPCode(String input) {
    if (input.isEmpty) {
      throw ArgumentError('Código CNP no puede estar vacío');
    }
    if (input.length != 4) {
      throw ArgumentError('Código CNP debe tener exactamente 4 dígitos');
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(input)) {
      throw ArgumentError('Código CNP debe contener solo números');
    }
    return CNPCode._(input);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CNPCode && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}