
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Failure &&
              runtimeType == other.runtimeType &&
              message == other.message &&
              code == other.code;

  @override
  int get hashCode => Object.hash(message, code);

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code}) : super(message, code: code);
}

class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code}) : super(message, code: code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String? code}) : super(message, code: code);
}

class AuthFailure extends Failure {
  const AuthFailure(String message, {String? code}) : super(message, code: code);
}

class UnknownFailure extends Failure {
  const UnknownFailure(String message, {String? code}) : super(message, code: code);
}
