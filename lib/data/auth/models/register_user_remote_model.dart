
class RegisterUserRemoteModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? photoUrl;
  final String cnpCode;
  final List<String> cnpPhotoUrls;
  final String specialty;
  final String? masterDegree;
  final String? otherSpecialty;
  final String location;
  final String address;

  RegisterUserRemoteModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.photoUrl,
    required this.cnpCode,
    required this.cnpPhotoUrls,
    required this.specialty,
    this.masterDegree,
    this.otherSpecialty,
    required this.location,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'photo_url': photoUrl,
      'cnp_code': cnpCode,
      'cnp_photo_urls': cnpPhotoUrls,
      'specialty': specialty,
      'master_degree': masterDegree,
      'other_specialty': otherSpecialty,
      'location': location,
      'address': address,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory RegisterUserRemoteModel.fromJson(Map<String, dynamic> json) {
    return RegisterUserRemoteModel(
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      photoUrl: json['photo_url'] as String?,
      cnpCode: json['cnp_code'] as String,
      cnpPhotoUrls: List<String>.from(json['cnp_photo_urls'] ?? []),
      specialty: json['specialty'] as String,
      masterDegree: json['master_degree'] as String?,
      otherSpecialty: json['other_specialty'] as String?,
      location: json['location'] as String,
      address: json['address'] as String,
    );
  }
}
