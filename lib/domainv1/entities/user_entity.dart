import 'dart:io';

class UserEntity {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final File? profilePhoto;
  final String cnpCode;
  final List<File> cnpPhotos;
  final String specialty;
  final String? masterDegree;
  final String? otherSpecialty;
  final String location;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isEmailVerified;
  final bool isActive;
  final UserStatus status;

  const UserEntity({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.profilePhoto,
    required this.cnpCode,
    required this.cnpPhotos,
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
    required this.location,
    required this.address,
    this.createdAt,
    this.updatedAt,
    this.isEmailVerified = false,
    this.isActive = false,
    this.status = UserStatus.pending,
  });

  UserEntity copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    File? profilePhoto,
    String? cnpCode,
    List<File>? cnpPhotos,
    String? specialty,
    String? masterDegree,
    String? otherSpecialty,
    String? location,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEmailVerified,
    bool? isActive,
    UserStatus? status,
  }) {
    return UserEntity(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      cnpCode: cnpCode ?? this.cnpCode,
      cnpPhotos: cnpPhotos ?? this.cnpPhotos,
      specialty: specialty ?? this.specialty,
      masterDegree: masterDegree ?? this.masterDegree,
      otherSpecialty: otherSpecialty ?? this.otherSpecialty,
      location: location ?? this.location,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
    );
  }

  String get fullName => '$firstName $lastName';
}

enum UserStatus {
  pending,
  verified,
  active,
  suspended,
  rejected
}