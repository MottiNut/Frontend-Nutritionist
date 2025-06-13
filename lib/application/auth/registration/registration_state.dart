import 'package:equatable/equatable.dart';
import 'dart:io';

import '../../../domain/auth/entities/user_profile.dart';
import '../../../domain/auth/enums/registration_status.dart';

class RegistrationState extends Equatable {
  final int currentStep;
  final RegistrationStatus status;
  final String? errorMessage;
  final String? successMessage;

  // Personal Info
  final String firstName;
  final String lastName;
  final File? photo;

  // Email & Password
  final String email;
  final String password;
  final String confirmPassword;
  final bool emailExists;
  final bool emailVerificationInProgress;

  // Colegiatura
  final String cnpCode;
  final List<File> cnpPhotos;
  final bool termsAccepted;
  final bool cnpVerificationInProgress;
  final bool cnpIsValid;

  // Specialty
  final String specialty;
  final String? masterDegree;
  final String? otherSpecialty;

  // Location
  final String location;
  final String address;

  // Registration Progress
  final bool isPersonalInfoValid;
  final bool isEmailPasswordValid;
  final bool isColegiaturaValid;
  final bool isSpecialtyValid;
  final bool isLocationValid;
  final UserProfile? registeredUser;

  const RegistrationState({
    this.currentStep = 0,
    this.status = RegistrationStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.firstName = '',
    this.lastName = '',
    this.photo,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailExists = false,
    this.emailVerificationInProgress = false,
    this.cnpCode = '',
    this.cnpPhotos = const [],
    this.termsAccepted = false,
    this.cnpVerificationInProgress = false,
    this.cnpIsValid = false,
    this.specialty = '',
    this.masterDegree,
    this.otherSpecialty,
    this.location = '',
    this.address = '',
    this.isPersonalInfoValid = false,
    this.isEmailPasswordValid = false,
    this.isColegiaturaValid = false,
    this.isSpecialtyValid = false,
    this.isLocationValid = false,
    this.registeredUser,
  });

  bool get canProceedToNext {
    switch (currentStep) {
      case 0:
        return isPersonalInfoValid;
      case 1:
        return isEmailPasswordValid && !emailExists;
      case 2:
        return isColegiaturaValid && cnpIsValid && !cnpVerificationInProgress;
      case 3:
        return isSpecialtyValid;
      case 4:
        return isLocationValid;
      default:
        return false;
    }
  }

  bool get isLoading => status == RegistrationStatus.loading;
  bool get isSuccess => status == RegistrationStatus.success;
  bool get isFailure => status == RegistrationStatus.failure;

  RegistrationState copyWith({
    int? currentStep,
    RegistrationStatus? status,
    String? errorMessage,
    String? successMessage,
    String? firstName,
    String? lastName,
    File? photo,
    String? email,
    String? password,
    String? confirmPassword,
    bool? emailExists,
    bool? emailVerificationInProgress,
    String? cnpCode,
    List<File>? cnpPhotos,
    bool? termsAccepted,
    bool? cnpVerificationInProgress,
    bool? cnpIsValid,
    String? specialty,
    String? masterDegree,
    String? otherSpecialty,
    String? location,
    String? address,
    bool? isPersonalInfoValid,
    bool? isEmailPasswordValid,
    bool? isColegiaturaValid,
    bool? isSpecialtyValid,
    bool? isLocationValid,
    UserProfile? registeredUser,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photo: photo ?? this.photo,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailExists: emailExists ?? this.emailExists,
      emailVerificationInProgress: emailVerificationInProgress ?? this.emailVerificationInProgress,
      cnpCode: cnpCode ?? this.cnpCode,
      cnpPhotos: cnpPhotos ?? this.cnpPhotos,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      cnpVerificationInProgress: cnpVerificationInProgress ?? this.cnpVerificationInProgress,
      cnpIsValid: cnpIsValid ?? this.cnpIsValid,
      specialty: specialty ?? this.specialty,
      masterDegree: masterDegree ?? this.masterDegree,
      otherSpecialty: otherSpecialty ?? this.otherSpecialty,
      location: location ?? this.location,
      address: address ?? this.address,
      isPersonalInfoValid: isPersonalInfoValid ?? this.isPersonalInfoValid,
      isEmailPasswordValid: isEmailPasswordValid ?? this.isEmailPasswordValid,
      isColegiaturaValid: isColegiaturaValid ?? this.isColegiaturaValid,
      isSpecialtyValid: isSpecialtyValid ?? this.isSpecialtyValid,
      isLocationValid: isLocationValid ?? this.isLocationValid,
      registeredUser: registeredUser ?? this.registeredUser,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    status,
    errorMessage,
    successMessage,
    firstName,
    lastName,
    photo,
    email,
    password,
    confirmPassword,
    emailExists,
    emailVerificationInProgress,
    cnpCode,
    cnpPhotos,
    termsAccepted,
    cnpVerificationInProgress,
    cnpIsValid,
    specialty,
    masterDegree,
    otherSpecialty,
    location,
    address,
    isPersonalInfoValid,
    isEmailPasswordValid,
    isColegiaturaValid,
    isSpecialtyValid,
    isLocationValid,
    registeredUser,
  ];
}