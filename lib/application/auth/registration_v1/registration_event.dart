import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

class StepChanged extends RegistrationEvent {
  final int step;

  const StepChanged(this.step);

  @override
  List<Object> get props => [step];
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
  List<Object> get props => [email, password, confirmPassword];
}

class EmailExistenceChecked extends RegistrationEvent {
  final String email;

  const EmailExistenceChecked(this.email);

  @override
  List<Object> get props => [email];
}

class CNPVerificationRequested extends RegistrationEvent {
  final String cnp;

  const CNPVerificationRequested(this.cnp);

  @override
  List<Object> get props => [cnp];
}

class ColegiaturaSubmitted extends RegistrationEvent {
  final String cnp;
  final String colegio;

  const ColegiaturaSubmitted({
    required this.cnp,
    required this.colegio,
  });

  @override
  List<Object> get props => [cnp, colegio];
}

class SpecialtySubmitted extends RegistrationEvent {
  final String specialty;
  final String subSpecialty;

  const SpecialtySubmitted({
    required this.specialty,
    required this.subSpecialty,
  });

  @override
  List<Object> get props => [specialty, subSpecialty];
}

class LocationSubmitted extends RegistrationEvent {
  final String department;
  final String province;
  final String district;

  const LocationSubmitted({
    required this.department,
    required this.province,
    required this.district,
  });

  @override
  List<Object> get props => [department, province, district];
}

class FinalRegistrationSubmitted extends RegistrationEvent {
  const FinalRegistrationSubmitted();
}

class RegistrationReset extends RegistrationEvent {
  const RegistrationReset();
}