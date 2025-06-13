import 'package:dartz/dartz.dart';

import '../auth/entities/user_profile.dart';
import '../auth/value_objects/cnp_code.dart';
import '../auth/value_objects/email.dart';
import '../auth/value_objects/password.dart';
import '../core/failures.dart';
import '../repositories/auth_repository.dart';

class RegisterUserParams {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? photoPath;
  final String cnpCode;
  final List<String> cnpPhotoPaths;
  final String specialty;
  final String? masterDegree;
  final String? otherSpecialty;
  final String location;
  final String address;

  RegisterUserParams({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.photoPath,
    required this.cnpCode,
    required this.cnpPhotoPaths,
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
    required this.location,
    required this.address,
  });

  // Validación de parámetros
  Either<ValidationFailure, RegisterUserParams> validate() {
    try {
      // Validar email
      Email(email);
      // Validar password
      Password(password);
      // Validar CNP
      CNPCode(cnpCode);

      if (firstName.trim().isEmpty) {
        return Left(ValidationFailure('El nombre es requerido'));
      }

      if (lastName.trim().isEmpty) {
        return Left(ValidationFailure('El apellido es requerido'));
      }

      if (specialty.trim().isEmpty) {
        return Left(ValidationFailure('La especialidad es requerida'));
      }

      if (location.trim().isEmpty) {
        return Left(ValidationFailure('La ubicación es requerida'));
      }

      if (address.trim().isEmpty) {
        return Left(ValidationFailure('La dirección es requerida'));
      }

      if (cnpPhotoPaths.isEmpty) {
        return Left(ValidationFailure('Las fotos del carné CNP son requeridas'));
      }

      return Right(this);
    } catch (e) {
      return Left(ValidationFailure(e.toString()));
    }
  }
}

class RegisterUserUseCase {
  final AuthRepository repository;

  RegisterUserUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(RegisterUserParams params) async {
    // Validar parámetros
    final validationResult = params.validate();
    if (validationResult.isLeft()) {
      return Left(validationResult.fold((failure) => failure, (_) => UnknownFailure('Error de validación')));
    }

    // Verificar si el email ya existe
    final emailExistsResult = await repository.verifyEmailExists(params.email);
    if (emailExistsResult.isLeft()) {
      return Left(emailExistsResult.fold((failure) => failure, (_) => UnknownFailure('Error verificando email')));
    }

    final emailExists = emailExistsResult.fold((_) => false, (exists) => exists);
    if (emailExists) {
      return Left(ValidationFailure('El email ya está registrado'));
    }

    // Verificar CNP
    final cnpResult = await repository.verifyCNPCode(params.cnpCode);
    if (cnpResult.isLeft()) {
      return Left(cnpResult.fold((failure) => failure, (_) => UnknownFailure('Error verificando CNP')));
    }

    // Proceder con el registro
    return await repository.registerUser(
      firstName: params.firstName,
      lastName: params.lastName,
      email: params.email,
      password: params.password,
      photoPath: params.photoPath ?? '',
      cnpCode: params.cnpCode,
      cnpPhotoPaths: params.cnpPhotoPaths,
      specialty: params.specialty,
      masterDegree: params.masterDegree,
      otherSpecialty: params.otherSpecialty,
      location: params.location,
      address: params.address,
    );
  }
}