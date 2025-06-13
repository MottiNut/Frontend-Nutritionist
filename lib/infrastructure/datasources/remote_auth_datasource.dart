
import 'package:dio/dio.dart';

import '../../domainv1/exceptions/auth_exceptions.dart';
import '../../domainv1/models/sign_up_data.dart';

abstract class RemoteAuthDataSource {
  Future<Map<String, dynamic>> signUp(SignUpData data);
  Future<Map<String, dynamic>> signIn(String email, String password);
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<bool> sendVerificationCode(String email);
  Future<bool> verifyEmail(String email, String code);
  Future<bool> checkEmailExists(String email);
  Future<bool> verifyCNPCode(String cnpCode);
  Future<Map<String, dynamic>> getCurrentUser(String token);
}

class RemoteAuthDataSourceImpl implements RemoteAuthDataSource {
  final Dio _dio;
  final String baseUrl;

  RemoteAuthDataSourceImpl({
    required Dio dio,
    required this.baseUrl,
  }) : _dio = dio {
    _configureDio();
  }

  void _configureDio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Interceptor para logs
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print(obj),
    ));

    // Interceptor para manejo de errores
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        _handleDioError(error);
        handler.next(error);
      },
    ));
  }

  @override
  Future<Map<String, dynamic>> signUp(SignUpData data) async {
    try {
      final formData = FormData();

      // Agregar datos básicos
      formData.fields.addAll([
        MapEntry('firstName', data.firstName),
        MapEntry('lastName', data.lastName),
        MapEntry('email', data.email),
        MapEntry('password', data.password),
        MapEntry('cnpCode', data.cnpCode),
        MapEntry('specialty', data.specialty),
        MapEntry('location', data.location),
        MapEntry('address', data.address),
        MapEntry('termsAccepted', data.termsAccepted.toString()),
      ]);

      // Agregar campos opcionales
      if (data.phone != null) {
        formData.fields.add(MapEntry('phone', data.phone!));
      }
      if (data.masterDegree != null) {
        formData.fields.add(MapEntry('masterDegree', data.masterDegree!));
      }
      if (data.otherSpecialty != null) {
        formData.fields.add(MapEntry('otherSpecialty', data.otherSpecialty!));
      }

      // Agregar foto de perfil
      if (data.profilePhoto != null) {
        formData.files.add(MapEntry(
          'profilePhoto',
          await MultipartFile.fromFile(
            data.profilePhoto!.path,
            filename: 'profile.jpg',
          ),
        ));
      }

      // Agregar fotos del CNP
      for (int i = 0; i < data.cnpPhotos.length; i++) {
        formData.files.add(MapEntry(
          'cnpPhotos',
          await MultipartFile.fromFile(
            data.cnpPhotos[i].path,
            filename: 'cnp_$i.jpg',
          ),
        ));
      }

      final response = await _dio.post('/auth/register', data: formData);
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> sendVerificationCode(String email) async {
    try {
      final response = await _dio.post('/auth/send-verification', data: {
        'email': email,
      });
      return response.statusCode == 200;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await _dio.post('/auth/verify-email', data: {
        'email': email,
        'code': code,
      });
      return response.statusCode == 200;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _dio.get('/auth/check-email/$email');
      return response.data['exists'] ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> verifyCNPCode(String cnpCode) async {
    try {
      final response = await _dio.post('/auth/verify-cnp', data: {
        'cnp_code': cnpCode,
      });
      return response.data['valid'] ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser(String token) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  void _handleDioError(DioException error) {
    print('Dio Error: ${error.type} - ${error.message}');
    if (error.response != null) {
      print('Response data: ${error.response?.data}');
      print('Response status: ${error.response?.statusCode}');
    }
  }

  AuthException _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return const NetworkException();
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data['message'] ?? 'Unknown error';

          switch (statusCode) {
            case 400:
              if (message.contains('email')) {
                return const EmailAlreadyExistsException();
              } else if (message.contains('cnp')) {
                return const CNPCodeInvalidException();
              }
              break;
            case 401:
              return const InvalidCredentialsException();
            case 422:
              return const InvalidVerificationCodeException();
            default:
              return ServerException(message);
          }
          break;
        default:
          return const ServerException();
      }
    }
    return ServerException(error.toString());
  }
}