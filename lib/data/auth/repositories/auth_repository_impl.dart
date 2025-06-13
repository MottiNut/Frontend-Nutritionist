import 'package:dartz/dartz.dart';
import '../../../domain/auth/entities/user_profile.dart';
import '../models/register_user_remote_model.dart';
import '../models/user_profile_model.dart';
import '../../core/exceptions.dart';
import '../../../domain/core/failures.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserProfile>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String photoPath,
    required String cnpCode,
    required List<String> cnpPhotoPaths,
    required String specialty,
    String? masterDegree,
    String? otherSpecialty,
    required String location,
    required String address,
  }) async {
    try {
      // Subir foto de perfil si existe
      String? photoUrl;
      if (photoPath.isNotEmpty) {
        photoUrl = await remoteDataSource.uploadImage(photoPath);
      }

      // Subir fotos del CNP
      final cnpPhotoUrls = await remoteDataSource.uploadMultipleImages(cnpPhotoPaths);

      // Crear modelo para enviar al servidor
      final userModel = RegisterUserRemoteModel(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        photoUrl: photoUrl,
        cnpCode: cnpCode,
        cnpPhotoUrls: cnpPhotoUrls,
        specialty: specialty,
        masterDegree: masterDegree,
        otherSpecialty: otherSpecialty,
        location: location,
        address: address,
      );

      // Registrar usuario
      final response = await remoteDataSource.registerUser(userModel);

      // Convertir respuesta a UserProfile
      final userProfile = UserProfileModel.fromJson(response['user'] ?? response);

      return Right(userProfile);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on CustomException catch (e) {
      return Left(UnknownFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyEmailExists(String email) async {
    try {
      final exists = await remoteDataSource.verifyEmailExists(email);
      return Right(exists);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Error verificando email: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyCNPCode(String cnpCode) async {
    try {
      final isValid = await remoteDataSource.verifyCNPCode(cnpCode);
      return Right(isValid);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Error verificando CNP: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(String imagePath) async {
    try {
      final imageUrl = await remoteDataSource.uploadImage(imagePath);
      return Right(imageUrl);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Error subiendo imagen: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> uploadMultipleImages(List<String> imagePaths) async {
    try {
      final imageUrls = await remoteDataSource.uploadMultipleImages(imagePaths);
      return Right(imageUrls);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Error subiendo imágenes: ${e.toString()}'));
    }
  }
}