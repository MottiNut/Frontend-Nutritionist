
abstract class CustomException implements Exception {
  final String message;
  final String? code;

  const CustomException(this.message, {this.code});

  @override
  String toString() => 'CustomException(message: $message, code: $code)';
}

class ServerException extends CustomException {
  const ServerException({required String message, String? code})
      : super(message, code: code);
}

class NetworkException extends CustomException {
  const NetworkException(String message) : super(message);
}

class CacheException extends CustomException {
  const CacheException(String message) : super(message);
}

class UnknownException extends CustomException {
  const UnknownException(String message) : super(message);
}