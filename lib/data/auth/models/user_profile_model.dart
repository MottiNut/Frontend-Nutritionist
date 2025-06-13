import 'package:mottinutnutriotinist/domain/auth/entities/user_profile.dart';

import '../../../domain/auth/enums/specialty_type.dart';
import '../../../domain/auth/enums/verification_status.dart';
import '../../../domain/auth/value_objects/cnp_code.dart';
import '../../../domain/auth/value_objects/email.dart';

class UserProfileModel extends UserProfile {
  UserProfileModel({
    String? id,
    required String firstName,
    required String lastName,
    required Email email,
    String? photoUrl,
    required CNPCode cnpCode,
    required List<String> cnpPhotoUrls,
    required SpecialtyType specialty,
    String? masterDegree,
    String? otherSpecialty,
    required String location,
    required String address,
    VerificationStatus verificationStatus = VerificationStatus.pending,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) : super(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    photoUrl: photoUrl,
    cnpCode: cnpCode,
    cnpPhotoUrls: cnpPhotoUrls,
    specialty: specialty,
    masterDegree: masterDegree,
    otherSpecialty: otherSpecialty,
    location: location,
    address: address,
    verificationStatus: verificationStatus,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: Email(json['email'] as String),
      photoUrl: json['photo_url'] as String?,
      cnpCode: CNPCode(json['cnp_code'] as String),
      cnpPhotoUrls: List<String>.from(json['cnp_photo_urls'] ?? []),
      specialty: SpecialtyType.fromString(json['specialty'] as String),
      masterDegree: json['master_degree'] as String?,
      otherSpecialty: json['other_specialty'] as String?,
      location: json['location'] as String,
      address: json['address'] as String,
      verificationStatus: _parseVerificationStatus(json['verification_status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email.value,
      'photo_url': photoUrl,
      'cnp_code': cnpCode.value,
      'cnp_photo_urls': cnpPhotoUrls,
      'specialty': specialty.displayName,
      'master_degree': masterDegree,
      'other_specialty': otherSpecialty,
      'location': location,
      'address': address,
      'verification_status': verificationStatus.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static VerificationStatus _parseVerificationStatus(dynamic status) {
    if (status == null) return VerificationStatus.pending;

    switch (status.toString().toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'verifying':
        return VerificationStatus.verifying;
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'expired':
        return VerificationStatus.expired;
      default:
        return VerificationStatus.pending;
    }
  }
}