import '../enums/specialty_type.dart';
import '../enums/verification_status.dart';
import '../value_objects/cnp_code.dart';
import '../value_objects/email.dart';

class UserProfile {
  final String id;
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
  final String? phone;
  final String? experience;
  final DateTime createdAt;
  final VerificationStatus verificationStatus;
  final DateTime updatedAt;

  // Nuevos campos del endpoint /me
  final String? biography;
  final String? calculatedExperienceLevel;
  final bool isExperienced;
  final DateTime? birthDate;
  final String? role;
  final String? type;
  final int? yearsOfExperience;
  final bool? acceptTerms;
  final String? licenseFrontImageBase64;
  final String? licenseBackImageBase64;
  final bool? emailVerified;
  final bool? phoneVerified;
  final bool? fullyVerified;
  final String? emailVerifiedAt;
  final String? phoneVerifiedAt;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.photoUrl,
    required this.cnpCode,
    this.cnpPhotoUrls = const [],
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
    required this.location,
    required this.address,
    this.phone,
    this.experience,
    required this.createdAt,
    required this.verificationStatus,
    required this.updatedAt,
    // Nuevos parámetros
    this.biography,
    this.calculatedExperienceLevel,
    this.isExperienced = false,
    this.birthDate,
    this.role,
    this.type,
    this.yearsOfExperience,
    this.acceptTerms,
    this.licenseFrontImageBase64,
    this.licenseBackImageBase64,
    this.emailVerified,
    this.phoneVerified,
    this.fullyVerified,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
  });

  String get fullName => '$firstName $lastName';

  // Método para crear desde el endpoint /me
  factory UserProfile.fromMeEndpoint(Map<String, dynamic> data) {
    return UserProfile(
      id: data['userId']?.toString() ?? data['id']?.toString() ?? '0',
      firstName: data['firstName']?.toString() ?? '',
      lastName: data['lastName']?.toString() ?? '',
      email: Email(data['email']?.toString() ?? ''),
      photoUrl: null, // Se construye dinámicamente con AuthService.buildProfileImageUrl
      cnpCode: CNPCode(data['cnpCode']?.toString() ?? '0000'),
      cnpPhotoUrls: const [], // Se construyen dinámicamente
      specialty: _parseSpecialtyFromString(data['specialty']?.toString()),
      masterDegree: data['masterDegree']?.toString(),
      otherSpecialty: data['otherSpecialty']?.toString(),
      location: data['location']?.toString() ?? 'No especificada',
      address: data['address']?.toString() ?? 'No especificada',
      phone: data['phone']?.toString(),
      experience: data['yearsOfExperience']?.toString(),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      verificationStatus: _parseVerificationStatusFromData(data),
      updatedAt: DateTime.now(),
      // Nuevos campos
      biography: data['biography']?.toString(),
      calculatedExperienceLevel: data['calculatedExperienceLevel']?.toString(),
      isExperienced: data['isExperienced'] ?? false,
      birthDate: _parseDateTime(data['birthDate']),
      role: data['role']?.toString(),
      type: data['type']?.toString(),
      yearsOfExperience: data['yearsOfExperience'],
      acceptTerms: data['acceptTerms'],
      licenseFrontImageBase64: data['licenseFrontImageBase64']?.toString(),
      licenseBackImageBase64: data['licenseBackImageBase64']?.toString(),
      emailVerified: data['emailVerified'],
      phoneVerified: data['phoneVerified'],
      fullyVerified: data['fullyVerified'],
      emailVerifiedAt: data['emailVerifiedAt']?.toString(),
      phoneVerifiedAt: data['phoneVerifiedAt']?.toString(),
    );
  }

  // Método helper para parsear specialty
  static SpecialtyType _parseSpecialtyFromString(String? specialty) {
    if (specialty == null) return SpecialtyType.nutricionClinica;

    switch (specialty.toLowerCase()) {
      case 'nutricion_clinica':
      case 'nutricionclinica':
      case 'clinical_nutrition':
        return SpecialtyType.nutricionClinica;
      case 'dietista':
      case 'dietitian':
        return SpecialtyType.dietista;
      case 'nutricionista':
      case 'nutritionist':
        return SpecialtyType.nutricionista;
      case 'nutricion_deportiva':
      case 'nutriciondeportiva':
      case 'sports_nutrition':
        return SpecialtyType.nutricionDeportiva;
      case 'other':
      case 'otra':
      case 'otro':
        return SpecialtyType.other;
      default:
        return SpecialtyType.nutricionClinica;
    }
  }

  // Método helper para parsear verification status
  static VerificationStatus _parseVerificationStatusFromData(Map<String, dynamic> data) {
    final fullyVerified = data['fullyVerified'] ?? false;
    final emailVerified = data['emailVerified'] ?? false;
    final phoneVerified = data['phoneVerified'] ?? false;

    if (fullyVerified) {
      return VerificationStatus.verified;
    } else if (emailVerified || phoneVerified) {
      return VerificationStatus.pending;
    }
    return VerificationStatus.pending;
  }

  // Método helper para parsear DateTime
  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    if (dateTime is DateTime) return dateTime;
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Método para obtener nivel de experiencia formateado
  String get experienceLevelFormatted {
    if (calculatedExperienceLevel != null) {
      switch (calculatedExperienceLevel!.toLowerCase()) {
        case 'junior':
          return 'Nivel Junior';
        case 'mid':
        case 'middle':
          return 'Nivel Intermedio';
        case 'senior':
          return 'Nivel Senior';
        case 'expert':
          return 'Nivel Experto';
        default:
          return 'Profesional';
      }
    }
    return 'Profesional';
  }

  // Método para obtener texto de especialidad formateado
  String get specialtyFormatted {
    switch (specialty) {
      case SpecialtyType.nutricionClinica:
        return 'Nutrición Clínica';
      case SpecialtyType.dietista:
        return 'Dietista';
      case SpecialtyType.nutricionista:
        return 'Nutricionista';
      case SpecialtyType.nutricionDeportiva:
        return 'Nutrición Deportiva';
      case SpecialtyType.other:
        return otherSpecialty ?? 'Otra especialidad';
      default:
        return 'Nutricionista';
    }
  }

  // Método para determinar si está verificado
  bool get isVerified {
    return verificationStatus == VerificationStatus.verified;
  }

  // Método para obtener biografía con fallback
  String get biographyOrDefault {
    return biography ??
        'Añade una breve descripción..';
  }

  // Método copyWith para actualizaciones
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
    String? phone,
    String? experience,
    DateTime? createdAt,
    VerificationStatus? verificationStatus,
    DateTime? updatedAt,
    String? biography,
    String? calculatedExperienceLevel,
    bool? isExperienced,
    DateTime? birthDate,
    String? role,
    String? type,
    int? yearsOfExperience,
    bool? acceptTerms,
    String? licenseFrontImageBase64,
    String? licenseBackImageBase64,
    bool? emailVerified,
    bool? phoneVerified,
    bool? fullyVerified,
    String? emailVerifiedAt,
    String? phoneVerifiedAt,
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
      phone: phone ?? this.phone,
      experience: experience ?? this.experience,
      createdAt: createdAt ?? this.createdAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      biography: biography ?? this.biography,
      calculatedExperienceLevel: calculatedExperienceLevel ?? this.calculatedExperienceLevel,
      isExperienced: isExperienced ?? this.isExperienced,
      birthDate: birthDate ?? this.birthDate,
      role: role ?? this.role,
      type: type ?? this.type,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      licenseFrontImageBase64: licenseFrontImageBase64 ?? this.licenseFrontImageBase64,
      licenseBackImageBase64: licenseBackImageBase64 ?? this.licenseBackImageBase64,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      fullyVerified: fullyVerified ?? this.fullyVerified,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      phoneVerifiedAt: phoneVerifiedAt ?? this.phoneVerifiedAt,
    );
  }

  // Método toJson para serialización
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email.value,
      'photoUrl': photoUrl,
      'cnpCode': cnpCode.value,
      'cnpPhotoUrls': cnpPhotoUrls,
      'specialty': specialty.toString().split('.').last,
      'masterDegree': masterDegree,
      'otherSpecialty': otherSpecialty,
      'location': location,
      'address': address,
      'phone': phone,
      'experience': experience,
      'createdAt': createdAt.toIso8601String(),
      'verificationStatus': verificationStatus.toString().split('.').last,
      'updatedAt': updatedAt.toIso8601String(),
      'biography': biography,
      'calculatedExperienceLevel': calculatedExperienceLevel,
      'isExperienced': isExperienced,
      'birthDate': birthDate?.toIso8601String(),
      'role': role,
      'type': type,
      'yearsOfExperience': yearsOfExperience,
      'acceptTerms': acceptTerms,
      'licenseFrontImageBase64': licenseFrontImageBase64,
      'licenseBackImageBase64': licenseBackImageBase64,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'fullyVerified': fullyVerified,
      'emailVerifiedAt': emailVerifiedAt,
      'phoneVerifiedAt': phoneVerifiedAt,
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, fullName: $fullName, specialty: ${specialtyFormatted}, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}