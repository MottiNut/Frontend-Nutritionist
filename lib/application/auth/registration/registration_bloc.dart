import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mottinutnutriotinist/application/auth/registration/registration_event.dart';
import 'package:mottinutnutriotinist/application/auth/registration/registration_state.dart';
import '../../../domain/auth/enums/registration_status.dart';
import '../../../domain/auth/value_objects/cnp_code.dart';
import '../../../domain/auth/value_objects/email.dart';
import '../../../domain/auth/value_objects/password.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/register_user_usecase.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final RegisterUserUseCase _registerUserUseCase;
  final AuthRepository _authRepository;

  RegistrationBloc({
    required RegisterUserUseCase registerUserUseCase,
    required AuthRepository authRepository,
  })  : _registerUserUseCase = registerUserUseCase,
        _authRepository = authRepository,
        super(const RegistrationState()) {
    on<PersonalInfoSubmitted>(_onPersonalInfoSubmitted);
    on<EmailPasswordSubmitted>(_onEmailPasswordSubmitted);
    on<ColegiaturaSubmitted>(_onColegiaturaSubmitted);
    on<SpecialtySubmitted>(_onSpecialtySubmitted);
    on<LocationSubmitted>(_onLocationSubmitted);
    on<EmailVerificationRequested>(_onEmailVerificationRequested);
    on<CNPVerificationRequested>(_onCNPVerificationRequested);
    on<FinalRegistrationSubmitted>(_onFinalRegistrationSubmitted);
    on<RegistrationReset>(_onRegistrationReset);
    on<StepChanged>(_onStepChanged);
  }

  Future<void> _onPersonalInfoSubmitted(
      PersonalInfoSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    final isValid = _validatePersonalInfo(event.firstName, event.lastName);

    emit(state.copyWith(
      firstName: event.firstName,
      lastName: event.lastName,
      photo: event.photo,
      isPersonalInfoValid: isValid,
      status: isValid ? RegistrationStatus.personalInfoCompleted : RegistrationStatus.initial,
      errorMessage: isValid ? null : 'Por favor, completa la información personal',
    ));
  }

  Future<void> _onEmailPasswordSubmitted(
      EmailPasswordSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    final isValid = _validateEmailPassword(event.email, event.password, event.confirmPassword);

    emit(state.copyWith(
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
      isEmailPasswordValid: isValid,
      status: isValid ? RegistrationStatus.emailPasswordCompleted : RegistrationStatus.initial,
      errorMessage: isValid ? null : 'Por favor, verifica el email y contraseña',
    ));

    // Verificar si el email ya existe
    if (isValid) {
      add(EmailVerificationRequested(event.email));
    }
  }

  Future<void> _onColegiaturaSubmitted(
      ColegiaturaSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    final isValid = _validateColegiatura(event.cnpCode, event.cnpPhotos, event.termsAccepted);

    emit(state.copyWith(
      cnpCode: event.cnpCode,
      cnpPhotos: event.cnpPhotos,
      termsAccepted: event.termsAccepted,
      isColegiaturaValid: isValid,
      // NO cambiar el status aquí, dejarlo como está hasta que la verificación termine
      errorMessage: isValid ? null : 'Por favor, completa la verificación de colegiatura',
    ));

    // Verificar código CNP solo si la validación básica pasa
    if (isValid) {
      add(CNPVerificationRequested(event.cnpCode));
    }
  }

  Future<void> _onSpecialtySubmitted(
      SpecialtySubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    final isValid = _validateSpecialty(event.specialty);

    emit(state.copyWith(
      specialty: event.specialty,
      masterDegree: event.masterDegree,
      otherSpecialty: event.otherSpecialty,
      isSpecialtyValid: isValid,
      status: isValid ? RegistrationStatus.specialtyCompleted : RegistrationStatus.initial,
      errorMessage: isValid ? null : 'Por favor, selecciona una especialidad',
    ));
  }

  Future<void> _onLocationSubmitted(
      LocationSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    final isValid = _validateLocation(event.location, event.address);

    emit(state.copyWith(
      location: event.location,
      address: event.address,
      isLocationValid: isValid,
      status: isValid ? RegistrationStatus.locationCompleted : RegistrationStatus.initial,
      errorMessage: isValid ? null : 'Por favor, completa la información de ubicación',
    ));
  }

  Future<void> _onEmailVerificationRequested(
      EmailVerificationRequested event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(state.copyWith(emailVerificationInProgress: true));

    final result = await _authRepository.verifyEmailExists(event.email);

    result.fold(
          (failure) => emit(state.copyWith(
        emailVerificationInProgress: false,
        errorMessage: 'Error verificando email: ${failure.message}',
      )),
          (exists) => emit(state.copyWith(
        emailVerificationInProgress: false,
        emailExists: exists,
        errorMessage: exists ? 'Este email ya está registrado' : null,
      )),
    );
  }

  Future<void> _onCNPVerificationRequested(
      CNPVerificationRequested event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(state.copyWith(cnpVerificationInProgress: true));

    final result = await _authRepository.verifyCNPCode(event.cnpCode);

    result.fold(
          (failure) => emit(state.copyWith(
        cnpVerificationInProgress: false,
        cnpIsValid: false, // Importante: marcar como inválido en caso de error
        errorMessage: 'Error verificando CNP: ${failure.message}',
      )),
          (isValid) => emit(state.copyWith(
        cnpVerificationInProgress: false,
        cnpIsValid: isValid,
        status: isValid ? RegistrationStatus.colegiaturaVerified : RegistrationStatus.initial,
        errorMessage: !isValid ? 'Código CNP inválido' : null,
      )),
    );
  }

  Future<void> _onFinalRegistrationSubmitted(
      FinalRegistrationSubmitted event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(state.copyWith(status: RegistrationStatus.loading));

    final params = RegisterUserParams(
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      password: state.password,
      photoPath: state.photo?.path,
      cnpCode: state.cnpCode,
      cnpPhotoPaths: state.cnpPhotos.map((file) => file.path).toList(),
      specialty: state.specialty,
      masterDegree: state.masterDegree,
      otherSpecialty: state.otherSpecialty,
      location: state.location,
      address: state.address,
    );

    final result = await _registerUserUseCase(params);

    result.fold(
          (failure) => emit(state.copyWith(
        status: RegistrationStatus.failure,
        errorMessage: failure.message,
      )),
          (user) => emit(state.copyWith(
        status: RegistrationStatus.success,
        registeredUser: user,
        successMessage: '¡Registro completado exitosamente!',
      )),
    );
  }

  Future<void> _onRegistrationReset(
      RegistrationReset event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(const RegistrationState());
  }

  Future<void> _onStepChanged(
      StepChanged event,
      Emitter<RegistrationState> emit,
      ) async {
    emit(state.copyWith(currentStep: event.step));
  }

  // ========== VALIDATION METHODS ==========

  bool _validatePersonalInfo(String firstName, String lastName) {
    return firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;
  }

  bool _validateEmailPassword(String email, String password, String confirmPassword) {
    try {
      Email(email);
      Password(password);
      return password == confirmPassword;
    } catch (e) {
      return false;
    }
  }

  bool _validateColegiatura(String cnpCode, List<File> photos, bool termsAccepted) {
    try {
      CNPCode(cnpCode);
      return photos.isNotEmpty && termsAccepted;
    } catch (e) {
      return false;
    }
  }

  bool _validateSpecialty(String specialty) {
    return specialty.trim().isNotEmpty;
  }

  bool _validateLocation(String location, String address) {
    return location.trim().isNotEmpty && address.trim().isNotEmpty;
  }
}

