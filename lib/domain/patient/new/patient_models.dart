
class PatientProfileDto {
  final int? patientId;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? chronicDisease;
  final String? allergies;
  final String? dietaryPreferences;
  final String? emergencyContact;
  final DateTime? birthDate;
  final int? age;
  final double? height;
  final double? weight;
  final double? bmi;
  final String? bmiCategory;
  final bool? hasMedicalCondition;
  final String? gender;
  final DateTime? createdAt;

  PatientProfileDto({
    this.patientId,
    this.firstName,
    this.lastName,
    this.fullName,
    this.email,
    this.phone,
    this.chronicDisease,
    this.allergies,
    this.dietaryPreferences,
    this.emergencyContact,
    this.birthDate,
    this.age,
    this.height,
    this.weight,
    this.bmi,
    this.bmiCategory,
    this.hasMedicalCondition,
    this.gender,
    this.createdAt,
  });

  factory PatientProfileDto.fromJson(Map<String, dynamic> json) {
    return PatientProfileDto(
      patientId: json['patientId'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      chronicDisease: json['chronicDisease'],
      allergies: json['allergies'],
      dietaryPreferences: json['dietaryPreferences'],
      emergencyContact: json['emergencyContact'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      age: json['age'],
      height: json['height']?.toDouble(),
      weight: json['weight']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      bmiCategory: json['bmiCategory'],
      hasMedicalCondition: json['hasMedicalCondition'],
      gender: json['gender'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'chronicDisease': chronicDisease,
      'allergies': allergies,
      'dietaryPreferences': dietaryPreferences,
      'emergencyContact': emergencyContact,
      'birthDate': birthDate?.toIso8601String().split('T')[0],
      'age': age,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'bmiCategory': bmiCategory,
      'hasMedicalCondition': hasMedicalCondition,
      'gender': gender,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class MedicalHistoryDto {
  final int? historyId;
  final int? patientId;
  final DateTime? consultationDate;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? bodyFatPercentage;
  final double? bloodGlucose;
  final double? waterConsumption;
  final double? caloricIntake;
  final String? bloodPressure;
  final String? lipidProfile;
  final String? eatingHabits;
  final String? supplementation;
  final String? macronutrients;
  final String? foodPreferences;
  final String? foodRelationship;
  final String? nutritionalObjectives;
  final String? patientEvolution;
  final String? professionalNotes;
  final int? heartRate;
  final int? stressLevel;
  final int? sleepQuality;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? waistHipRatio;

  MedicalHistoryDto({
    this.historyId,
    this.patientId,
    this.consultationDate,
    this.waistCircumference,
    this.hipCircumference,
    this.bodyFatPercentage,
    this.bloodGlucose,
    this.waterConsumption,
    this.caloricIntake,
    this.bloodPressure,
    this.lipidProfile,
    this.eatingHabits,
    this.supplementation,
    this.macronutrients,
    this.foodPreferences,
    this.foodRelationship,
    this.nutritionalObjectives,
    this.patientEvolution,
    this.professionalNotes,
    this.heartRate,
    this.stressLevel,
    this.sleepQuality,
    this.createdAt,
    this.updatedAt,
    this.waistHipRatio,
  });

  factory MedicalHistoryDto.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryDto(
      historyId: json['historyId'],
      patientId: json['patientId'],
      consultationDate: json['consultationDate'] != null ? DateTime.parse(json['consultationDate']) : null,
      waistCircumference: json['waistCircumference']?.toDouble(),
      hipCircumference: json['hipCircumference']?.toDouble(),
      bodyFatPercentage: json['bodyFatPercentage']?.toDouble(),
      bloodGlucose: json['bloodGlucose']?.toDouble(),
      waterConsumption: json['waterConsumption']?.toDouble(),
      caloricIntake: json['caloricIntake']?.toDouble(),
      bloodPressure: json['bloodPressure'],
      lipidProfile: json['lipidProfile'],
      eatingHabits: json['eatingHabits'],
      supplementation: json['supplementation'],
      macronutrients: json['macronutrients'],
      foodPreferences: json['foodPreferences'],
      foodRelationship: json['foodRelationship'],
      nutritionalObjectives: json['nutritionalObjectives'],
      patientEvolution: json['patientEvolution'],
      professionalNotes: json['professionalNotes'],
      heartRate: json['heartRate'],
      stressLevel: json['stressLevel'],
      sleepQuality: json['sleepQuality'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      waistHipRatio: json['waistHipRatio']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'historyId': historyId,
      'patientId': patientId,
      'consultationDate': consultationDate?.toIso8601String().split('T')[0],
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'bodyFatPercentage': bodyFatPercentage,
      'bloodGlucose': bloodGlucose,
      'waterConsumption': waterConsumption,
      'caloricIntake': caloricIntake,
      'bloodPressure': bloodPressure,
      'lipidProfile': lipidProfile,
      'eatingHabits': eatingHabits,
      'supplementation': supplementation,
      'macronutrients': macronutrients,
      'foodPreferences': foodPreferences,
      'foodRelationship': foodRelationship,
      'nutritionalObjectives': nutritionalObjectives,
      'patientEvolution': patientEvolution,
      'professionalNotes': professionalNotes,
      'heartRate': heartRate,
      'stressLevel': stressLevel,
      'sleepQuality': sleepQuality,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'waistHipRatio': waistHipRatio,
    };
  }
}

class PatientWithHistoryDto {
  final PatientProfileDto? patient;
  final List<MedicalHistoryDto>? medicalHistories;
  final MedicalHistoryDto? latestHistory;
  final int? totalHistories;

  PatientWithHistoryDto({
    this.patient,
    this.medicalHistories,
    this.latestHistory,
    this.totalHistories,
  });

  factory PatientWithHistoryDto.fromJson(Map<String, dynamic> json) {
    return PatientWithHistoryDto(
      patient: json['patient'] != null ? PatientProfileDto.fromJson(json['patient']) : null,
      medicalHistories: json['medicalHistories'] != null
          ? (json['medicalHistories'] as List).map((e) => MedicalHistoryDto.fromJson(e)).toList()
          : null,
      latestHistory: json['latestHistory'] != null ? MedicalHistoryDto.fromJson(json['latestHistory']) : null,
      totalHistories: json['totalHistories'],
    );
  }
}

class ChronicDiseaseFilterDto {
  final String? code;
  final String? description;

  ChronicDiseaseFilterDto({this.code, this.description});

  factory ChronicDiseaseFilterDto.fromJson(Map<String, dynamic> json) {
    return ChronicDiseaseFilterDto(
      code: json['code'],
      description: json['description'],
    );
  }
}

class SortFieldDto {
  final String? code;
  final String? description;

  SortFieldDto({this.code, this.description});

  factory SortFieldDto.fromJson(Map<String, dynamic> json) {
    return SortFieldDto(
      code: json['code'],
      description: json['description'],
    );
  }
}

class SortOrderDto {
  final String? code;
  final String? description;

  SortOrderDto({this.code, this.description});

  factory SortOrderDto.fromJson(Map<String, dynamic> json) {
    return SortOrderDto(
      code: json['code'],
      description: json['description'],
    );
  }
}

class PatientSortOptionsDto {
  final List<SortFieldDto>? sortFields;
  final List<SortOrderDto>? sortOrders;

  PatientSortOptionsDto({this.sortFields, this.sortOrders});

  factory PatientSortOptionsDto.fromJson(Map<String, dynamic> json) {
    return PatientSortOptionsDto(
      sortFields: json['sortFields'] != null
          ? (json['sortFields'] as List).map((e) => SortFieldDto.fromJson(e)).toList()
          : null,
      sortOrders: json['sortOrders'] != null
          ? (json['sortOrders'] as List).map((e) => SortOrderDto.fromJson(e)).toList()
          : null,
    );
  }
}

class PatientHealthSummaryDto {
  final int? patientId;
  final String? fullName;
  final int? age;
  final double? bmi;
  final String? bmiCategory;
  final bool? hasMedicalCondition;
  final String? chronicDisease;
  final String? gender;
  final DateTime? lastConsultationDate;
  final String? bloodPressure;
  final double? bloodGlucose;
  final int? stressLevel;
  final int? sleepQuality;
  final double? waistHipRatio;
  final int? totalConsultations;

  PatientHealthSummaryDto({
    this.patientId,
    this.fullName,
    this.age,
    this.bmi,
    this.bmiCategory,
    this.hasMedicalCondition,
    this.chronicDisease,
    this.gender,
    this.lastConsultationDate,
    this.bloodPressure,
    this.bloodGlucose,
    this.stressLevel,
    this.sleepQuality,
    this.waistHipRatio,
    this.totalConsultations,
  });

  factory PatientHealthSummaryDto.fromJson(Map<String, dynamic> json) {
    return PatientHealthSummaryDto(
      patientId: json['patientId'],
      fullName: json['fullName'],
      age: json['age'],
      bmi: json['bmi']?.toDouble(),
      bmiCategory: json['bmiCategory'],
      hasMedicalCondition: json['hasMedicalCondition'],
      chronicDisease: json['chronicDisease'],
      gender: json['gender'],
      lastConsultationDate: json['lastConsultationDate'] != null
          ? DateTime.parse(json['lastConsultationDate']) : null,
      bloodPressure: json['bloodPressure'],
      bloodGlucose: json['bloodGlucose']?.toDouble(),
      stressLevel: json['stressLevel'],
      sleepQuality: json['sleepQuality'],
      waistHipRatio: json['waistHipRatio']?.toDouble(),
      totalConsultations: json['totalConsultations'],
    );
  }
}

class PatientProgressDto {
  final int? periodDays;
  final int? totalConsultations;
  final double? bodyFatChange;
  final double? waistCircumferenceChange;
  final double? averageSleepQuality;
  final double? averageStressLevel;

  PatientProgressDto({
    this.periodDays,
    this.totalConsultations,
    this.bodyFatChange,
    this.waistCircumferenceChange,
    this.averageSleepQuality,
    this.averageStressLevel,
  });

  factory PatientProgressDto.fromJson(Map<String, dynamic> json) {
    return PatientProgressDto(
      periodDays: json['periodDays'],
      totalConsultations: json['totalConsultations'],
      bodyFatChange: json['bodyFatChange']?.toDouble(),
      waistCircumferenceChange: json['waistCircumferenceChange']?.toDouble(),
      averageSleepQuality: json['averageSleepQuality']?.toDouble(),
      averageStressLevel: json['averageStressLevel']?.toDouble(),
    );
  }
}

class CreateMedicalHistoryRequest {
  final DateTime? consultationDate;
  final double? waistCircumference;
  final double? hipCircumference;
  final double? bodyFatPercentage;
  final double? bloodGlucose;
  final double? waterConsumption;
  final double? caloricIntake;
  final String? bloodPressure;
  final String? lipidProfile;
  final String? eatingHabits;
  final String? supplementation;
  final String? macronutrients;
  final String? foodPreferences;
  final String? foodRelationship;
  final String? nutritionalObjectives;
  final String? patientEvolution;
  final String? professionalNotes;
  final int? heartRate;
  final int? stressLevel;
  final int? sleepQuality;

  CreateMedicalHistoryRequest({
    this.consultationDate,
    this.waistCircumference,
    this.hipCircumference,
    this.bodyFatPercentage,
    this.bloodGlucose,
    this.waterConsumption,
    this.caloricIntake,
    this.bloodPressure,
    this.lipidProfile,
    this.eatingHabits,
    this.supplementation,
    this.macronutrients,
    this.foodPreferences,
    this.foodRelationship,
    this.nutritionalObjectives,
    this.patientEvolution,
    this.professionalNotes,
    this.heartRate,
    this.stressLevel,
    this.sleepQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      'consultationDate': consultationDate?.toIso8601String().split('T')[0],
      'waistCircumference': waistCircumference,
      'hipCircumference': hipCircumference,
      'bodyFatPercentage': bodyFatPercentage,
      'bloodGlucose': bloodGlucose,
      'waterConsumption': waterConsumption,
      'caloricIntake': caloricIntake,
      'bloodPressure': bloodPressure,
      'lipidProfile': lipidProfile,
      'eatingHabits': eatingHabits,
      'supplementation': supplementation,
      'macronutrients': macronutrients,
      'foodPreferences': foodPreferences,
      'foodRelationship': foodRelationship,
      'nutritionalObjectives': nutritionalObjectives,
      'patientEvolution': patientEvolution,
      'professionalNotes': professionalNotes,
      'heartRate': heartRate,
      'stressLevel': stressLevel,
      'sleepQuality': sleepQuality,
    };
  }
}

class UpdateMedicalHistoryRequest extends CreateMedicalHistoryRequest {
  UpdateMedicalHistoryRequest({
    super.consultationDate,
    super.waistCircumference,
    super.hipCircumference,
    super.bodyFatPercentage,
    super.bloodGlucose,
    super.waterConsumption,
    super.caloricIntake,
    super.bloodPressure,
    super.lipidProfile,
    super.eatingHabits,
    super.supplementation,
    super.macronutrients,
    super.foodPreferences,
    super.foodRelationship,
    super.nutritionalObjectives,
    super.patientEvolution,
    super.professionalNotes,
    super.heartRate,
    super.stressLevel,
    super.sleepQuality,
  });
}




