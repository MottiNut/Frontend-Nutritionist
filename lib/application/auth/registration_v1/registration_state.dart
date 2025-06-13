import 'dart:io';
import 'package:equatable/equatable.dart';

enum RegistrationStatus {
  initial,
  loading,
  success,
  failure,
}

class RegistrationState extends Equatable {
  final int currentStep;
  final RegistrationStatus status;
  final String? errorMessage;

  // Información personal
  final String firstName;
  final String lastName;
  final File? photo;
  final bool isPersonalInfoValid;

  // Email y contraseña
  final String email;
  final String password;
  final String confirmPassword;
  final bool isEmailPasswordValid;
  final bool emailExists;
  final bool emailCheckInProgress;

  // Colegiatura
  final String cnp;
  final String colegio;
  final bool isCnpValid;
  final List<File> cnpPhotos;
  final bool isColegiaturaValid;
  final bool cnpVerificationInProgress;

  // Especialidad
  final String specialty;
  final String subSpecialty;
  final bool isSpecialtyValid;

  // Ubicación
  final String department;
  final String province;
  final String district;
  final bool isLocationValid;

  // Registro final
  final bool isRegistrationComplete;

  const RegistrationState(this.cnpPhotos, {
    this.currentStep = 0,
    this.status = RegistrationStatus.initial,
    this.errorMessage,
    this.firstName = '',
    this.lastName = '',
    this.photo,
    this.isPersonalInfoValid = false,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.isEmailPasswordValid = false,
    this.emailExists = false,
    this.emailCheckInProgress = false,
    this.cnp = '',
    this.colegio = '',
    this.isCnpValid = false,
    this.isColegiaturaValid = false,
    this.cnpVerificationInProgress = false,
    this.specialty = '',
    this.subSpecialty = '',
    this.isSpecialtyValid = false,
    this.department = '',
    this.province = '',
    this.district = '',
    this.isLocationValid = false,
    this.isRegistrationComplete = false,
  });

  /*RegistrationState copyWith({
    int? currentStep,
    RegistrationStatus? status,
    String? errorMessage,
    String? firstName,
    String? lastName,
    File? photo,
    bool? isPersonalInfoValid,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isEmailPasswordValid,
    bool? emailExists,
    bool? emailCheckInProgress,
    String? cnp,
    String? colegio,
    bool? isCnpValid,
    bool? isColegiaturaValid,
    bool? cnpVerificationInProgress,
    String? specialty,
    String? subSpecialty,
    bool? isSpecialtyValid,
    String? department,
    String? province,
    String? district,
    bool? isLocationValid,
    bool? isRegistrationComplete,
  }) {
    return RegistrationState(
    //  currentStep: currentStep ?? this.currentStep,
      //status: status ?? this.status,
      //errorMessage: errorMessage ?? this.errorMessage,
      /*firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photo: photo ?? this.photo,
      isPersonalInfoValid: isPersonalInfoValid ?? this.isPersonalInfoValid,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isEmailPasswordValid: isEmailPasswordValid ?? this.isEmailPasswordValid,
      emailExists: emailExists ?? this.emailExists,
      emailCheckInProgress: emailCheckInProgress ?? this.emailCheckInProgress,
      cnp: cnp ?? this.cnp,
      colegio: colegio ?? this.colegio,
      isCnpValid: isCnpValid ?? this.isCnpValid,
      isColegiaturaValid: isColegiaturaValid ?? this.isColegiaturaValid,
      cnpVerificationInProgress: cnpVerificationInProgress ?? this.cnpVerificationInProgress,
      specialty: specialty ?? this.specialty,
      subSpecialty: subSpecialty ?? this.subSpecialty,
      isSpecialtyValid: isSpecialtyValid ?? this.isSpecialtyValid,
      department: department ?? this.department,
      province: province ?? this.province,
      district: district ?? this.district,
      isLocationValid: isLocationValid ?? this.isLocationValid,
      isRegistrationComplete: isRegistrationComplete ?? this.isRegistrationComplete,*/
    );
  }*/

  @override
  List<Object?> get props => [
    currentStep,
    status,
    errorMessage,
    firstName,
    lastName,
    photo,
    isPersonalInfoValid,
    email,
    password,
    confirmPassword,
    isEmailPasswordValid,
    emailExists,
    emailCheckInProgress,
    cnp,
    colegio,
    isCnpValid,
    isColegiaturaValid,
    cnpVerificationInProgress,
    specialty,
    subSpecialty,
    isSpecialtyValid,
    department,
    province,
    district,
    isLocationValid,
    isRegistrationComplete,
  ];
}