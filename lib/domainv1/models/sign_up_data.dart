import 'dart:io';

class SignUpData {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? phone;
  final File? profilePhoto;
  final String cnpCode;
  final List<File> cnpPhotos;
  final String specialty;
  final String? masterDegree;
  final String? otherSpecialty;
  final String location;
  final String address;
  final bool termsAccepted;

  const SignUpData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.phone,
    this.profilePhoto,
    required this.cnpCode,
    required this.cnpPhotos,
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
    required this.location,
    required this.address,
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phone': phone,
      'cnpCode': cnpCode,
      'specialty': specialty,
      'masterDegree': masterDegree,
      'otherSpecialty': otherSpecialty,
      'location': location,
      'address': address,
      'termsAccepted': termsAccepted,
    };
  }
}