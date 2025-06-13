class Email {
  final String value;

  const Email._(this.value);

  factory Email.create(String email) {
    if (email.isEmpty) {
      throw ArgumentError('Email cannot be empty');
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email format');
    }

    return Email._(email.toLowerCase());
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Email && other.value == value);

  @override
  int get hashCode => value.hashCode;
}