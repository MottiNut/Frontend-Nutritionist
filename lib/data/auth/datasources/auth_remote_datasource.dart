import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/exceptions.dart';
import '../models/register_user_remote_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> registerUser(RegisterUserRemoteModel userModel);
  Future<bool> verifyEmailExists(String email);
  Future<bool> verifyCNPCode(String cnpCode);
  Future<String> uploadImage(String imagePath);
  Future<List<String>> uploadMultipleImages(List<String> imagePaths);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  AuthRemoteDataSourceImpl({
    required this.client,
    this.baseUrl = 'https://684685267dbda7ee7aaf4e65.mockapi.io/',
  });

  @override
  Future<Map<String, dynamic>> registerUser(RegisterUserRemoteModel userModel) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userModel.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ServerException(
          message: errorData['message'] ?? 'Error de validación',
          code: response.statusCode.toString(),
        );
      } else if (response.statusCode == 409) {
        throw ServerException(
          message: 'El usuario ya existe',
          code: response.statusCode.toString(),
        );
      } else {
        throw ServerException(
          message: 'Error del servidor: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on SocketException {
      throw NetworkException('No hay conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw UnknownException('Error inesperado: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyEmailExists(String email) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/auth/verify-email?email=$email'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] as bool;
      } else {
        throw ServerException(
          message: 'Error verificando email',
          code: response.statusCode.toString(),
        );
      }
    } on SocketException {
      throw NetworkException('No hay conexión a internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw UnknownException('Error verificando email: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyCNPCode(String cnpCode) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/auth/verify-cnp?code=$cnpCode'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['valid'] as bool;
      } else {
        throw ServerException(
          message: 'Error verificando código CNP',
          code: response.statusCode.toString(),
        );
      }
    } on SocketException {
      throw NetworkException('No hay conexión a internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw UnknownException('Error verificando CNP: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadImage(String imagePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/image'),
      );

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'] as String;
      } else {
        throw ServerException(
          message: 'Error subiendo imagen',
          code: response.statusCode.toString(),
        );
      }
    } on SocketException {
      throw NetworkException('No hay conexión a internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw UnknownException('Error subiendo imagen: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> uploadMultipleImages(List<String> imagePaths) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/images'),
      );

      for (int i = 0; i < imagePaths.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath('images', imagePaths[i]),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['urls']);
      } else {
        throw ServerException(
          message: 'Error subiendo imágenes',
          code: response.statusCode.toString(),
        );
      }
    } on SocketException {
      throw NetworkException('No hay conexión a internet');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw UnknownException('Error subiendo imágenes: ${e.toString()}');
    }
  }
}

class AuthRemoteDataSourceMock implements AuthRemoteDataSource {
  @override
  Future<Map<String, dynamic>> registerUser(RegisterUserRemoteModel userModel) async {
    // Simular delay de red
    await Future.delayed(Duration(seconds: 2));

    // Simular respuesta exitosa
    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'message': 'Usuario registrado exitosamente',
      'user': userModel.toJson(),
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<bool> verifyEmailExists(String email) async {
    await Future.delayed(Duration(milliseconds: 500));

    // Simular que algunos emails ya existen
    final existingEmails = [
      'test@example.com',
      'admin@test.com',
      'usuario@gmail.com',
    ];

    return existingEmails.contains(email.toLowerCase());
  }

  @override
  Future<bool> verifyCNPCode(String cnpCode) async {
    await Future.delayed(Duration(milliseconds: 800));

    // Simular que códigos CNP inválidos
    final invalidCodes = ['0000', '1111', '9999'];

    return !invalidCodes.contains(cnpCode);
  }

  @override
  Future<String> uploadImage(String imagePath) async {
    await Future.delayed(Duration(seconds: 1));

    // Simular URL de imagen subida
    final fileName = imagePath.split('/').last;
    return 'https://mockapi.io/uploads/images/$fileName';
  }

  @override
  Future<List<String>> uploadMultipleImages(List<String> imagePaths) async {
    await Future.delayed(Duration(seconds: 2));

    // Simular URLs de imágenes subidas
    return imagePaths.map((path) {
      final fileName = path.split('/').last;
      return 'https://mockapi.io/uploads/images/$fileName';
    }).toList();
  }
}
