import 'package:dartz/dartz.dart';
import '../auth/entities/user_profile.dart';
import '../core/failures.dart';

abstract class AuthRepository {
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
  });

  Future<Either<Failure, bool>> verifyEmailExists(String email);

  Future<Either<Failure, bool>> verifyCNPCode(String cnpCode);

  Future<Either<Failure, String>> uploadImage(String imagePath);

  Future<Either<Failure, List<String>>> uploadMultipleImages(List<String> imagePaths);
}