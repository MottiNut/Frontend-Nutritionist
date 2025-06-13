import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

class PersonalInfoSubmitted extends RegistrationEvent {
  final String firstName;
  final String lastName;
  final File? photo;

  const PersonalInfoSubmitted({
    required this.firstName,
    required this.lastName,
    this.photo,
  });

  @override
  List<Object?> get props => [firstName, lastName, photo];
}

class EmailPasswordSubmitted extends RegistrationEvent {
  final String email;
  final String password;
  final String confirmPassword;

  const EmailPasswordSubmitted({
    required this.email,
    required this.password,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [email, password, confirmPassword];
}

class ColegiaturaSubmitted extends RegistrationEvent {
  final String cnpCode;
  final List<File> cnpPhotos;
  final bool termsAccepted;

  const ColegiaturaSubmitted({
    required this.cnpCode,
    required this.cnpPhotos,
    required this.termsAccepted,
  });

  @override
  List<Object?> get props => [cnpCode, cnpPhotos, termsAccepted];
}

class SpecialtySubmitted extends RegistrationEvent {
  final String specialty;
  final String? masterDegree;
  final String? otherSpecialty;

  const SpecialtySubmitted({
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
  });

  @override
  List<Object?> get props => [specialty, masterDegree, otherSpecialty];
}

class LocationSubmitted extends RegistrationEvent {
  final String location;
  final String address;

  const LocationSubmitted({
    required this.location,
    required this.address,
  });

  @override
  List<Object?> get props => [location, address];
}

class EmailVerificationRequested extends RegistrationEvent {
  final String email;

  const EmailVerificationRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class CNPVerificationRequested extends RegistrationEvent {
  final String cnpCode;

  const CNPVerificationRequested(this.cnpCode);

  @override
  List<Object?> get props => [cnpCode];
}

class FinalRegistrationSubmitted extends RegistrationEvent {
  const FinalRegistrationSubmitted();
}

class RegistrationReset extends RegistrationEvent {
  const RegistrationReset();
}

class StepChanged extends RegistrationEvent {
  final int step;

  const StepChanged(this.step);

  @override
  List<Object?> get props => [step];
}