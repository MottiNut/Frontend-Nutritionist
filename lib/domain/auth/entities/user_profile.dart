import '../enums/specialty_type.dart';
import '../enums/verification_status.dart';
import '../value_objects/cnp_code.dart';
import '../value_objects/email.dart';

class UserProfile {
  final String? id;
  final String firstName;
  final String lastName;
  final Email email;
  final String? photoUrl;
  final CNPCode cnpCode;
  final List<String> cnpPhotoUrls;
  final SpecialtyType specialty;
  final String? masterDegree;
  final String? otherSpecialty;
  final String location;
  final String address;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    required this.cnpCode,
    required this.cnpPhotoUrls,
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
    required this.location,
    required this.address,
    this.verificationStatus = VerificationStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    Email? email,
    String? photoUrl,
    CNPCode? cnpCode,
    List<String>? cnpPhotoUrls,
    SpecialtyType? specialty,
    String? masterDegree,
    String? otherSpecialty,
    String? location,
    String? address,
    VerificationStatus? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      cnpCode: cnpCode ?? this.cnpCode,
      cnpPhotoUrls: cnpPhotoUrls ?? this.cnpPhotoUrls,
      specialty: specialty ?? this.specialty,
      masterDegree: masterDegree ?? this.masterDegree,
      otherSpecialty: otherSpecialty ?? this.otherSpecialty,
      location: location ?? this.location,
      address: address ?? this.address,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserProfile &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              firstName == other.firstName &&
              lastName == other.lastName &&
              email == other.email;

  @override
  int get hashCode => Object.hash(id, firstName, lastName, email);

  @override
  String toString() => 'UserProfile(id: $id, fullName: $fullName, email: $email)';
}
