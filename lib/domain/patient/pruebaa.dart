import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum Gender {
  masculino('Masculino', 'male'),
  femenino('Femenino', 'female'),
  otro('Otro', 'other');

  const Gender(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static Gender fromApiValue(String apiValue) {
    return Gender.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => Gender.masculino,
    );
  }
}
enum ActivityLevel {
  sedentario('Sedentario', 'sedentary', 1.2),
  ligero('Actividad Ligera', 'light', 1.375),
  moderado('Actividad Moderada', 'moderate', 1.55),
  intenso('Actividad Intensa', 'intense', 1.725),
  muyIntenso('Muy Intenso', 'very_intense', 1.9);

  const ActivityLevel(this.displayName, this.apiValue, this.multiplier);
  final String displayName;
  final String apiValue;
  final double multiplier;

  static ActivityLevel fromApiValue(String apiValue) {
    return ActivityLevel.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => ActivityLevel.sedentario,
    );
  }
}
enum PatientActividad {
  activo('activo'),
  inactivo('inactivo'),
  suspendido('suspendido');

  const PatientActividad(this.apiValue);
  final String apiValue;

  static PatientActividad fromString(String value) {
    return PatientActividad.values.firstWhere(
          (status) => status.apiValue == value,
      orElse: () => PatientActividad.activo,
    );
  }
}
enum PatientStatus {
  nuevo('Nuevo', 'new'),
  enTratamiento('En Tratamiento', 'in_treatment'),
  controlado('Controlado', 'controlled'),
  seguimiento('En Seguimiento', 'follow_up'),
  inactivo('Inactivo', 'inactive'),
  altaMedica('Alta Médica', 'discharged');

  const PatientStatus(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static PatientStatus fromApiValue(String apiValue) {
    return PatientStatus.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => PatientStatus.nuevo,
    );
  }
}
enum MedicalCondition {
  ninguna('Sin Condición Médica', 'none'),
  diabetesTipo1('Diabetes Tipo 1', 'diabetes_type1'),
  diabetesTipo2('Diabetes Tipo 2', 'diabetes_type2'),
  hipertension('Hipertensión', 'hypertension'),
  obesidad('Obesidad', 'obesity'),
  sobrepeso('Sobrepeso', 'overweight'),
  dislipidemia('Dislipidemias', 'dyslipidemia'),
  sindrome_metabolico('Síndrome Metabólico', 'metabolic_syndrome');

  const MedicalCondition(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static MedicalCondition fromApiValue(String apiValue) {
    return MedicalCondition.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => MedicalCondition.ninguna,
    );
  }

  bool get isDiabetes => this == diabetesTipo1 || this == diabetesTipo2;
  bool get requiresSpecialDiet => this != ninguna;
}
enum MealType {
  desayuno('Desayuno', 'breakfast'),
  colacionMatinal('Colación Matinal', 'morning_snack'),
  almuerzo('Almuerzo', 'lunch'),
  colacionVespertina('Colación Vespertina', 'afternoon_snack'),
  cena('Cena', 'dinner'),
  colacionNocturna('Colación Nocturna', 'night_snack');

  const MealType(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static MealType fromApiValue(String apiValue) {
    return MealType.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => MealType.desayuno,
    );
  }
}
enum PlanStatus {
  borrador('Borrador', 'draft'),
  activo('Activo', 'active'),
  pausado('Pausado', 'paused'),
  completado('Completado', 'completed'),
  cancelado('Cancelado', 'cancelled');

  const PlanStatus(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static PlanStatus fromApiValue(String apiValue) {
    return PlanStatus.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => PlanStatus.borrador,
    );
  }
}
enum AppointmentStatus {
  programada('Programada', 'scheduled'),
  confirmada('Confirmada', 'confirmed'),
  enCurso('En Curso', 'in_progress'),
  completada('Completada', 'completed'),
  cancelada('Cancelada', 'cancelled'),
  noAsistio('No Asistió', 'no_show'),
  reprogramada('Reprogramada', 'rescheduled');

  const AppointmentStatus(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static AppointmentStatus fromApiValue(String apiValue) {
    return AppointmentStatus.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => AppointmentStatus.programada,
    );
  }
}
enum AppointmentType {
  primeraConsulta('Primera Consulta', 'first_consultation'),
  seguimiento('Seguimiento', 'follow_up'),
  control('Control', 'control'),
  urgencia('Urgencia', 'emergency'),
  evaluacion('Evaluación', 'evaluation');

  const AppointmentType(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static AppointmentType fromApiValue(String apiValue) {
    return AppointmentType.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => AppointmentType.seguimiento,
    );
  }
}
enum AppointmentPriority {
  baja('Baja', 'low'),
  normal('Normal', 'normal'),
  alta('Alta', 'high'),
  urgente('Urgente', 'urgent');

  const AppointmentPriority(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static AppointmentPriority fromApiValue(String apiValue) {
    return AppointmentPriority.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => AppointmentPriority.normal,
    );
  }
}

class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final Gender gender;
  final String? dni;
  final String? email;
  final String? phone;
  final String? profileImageUrl;

  // Datos físicos - hacer opcionales
  final double? weight;
  final double? height;
  final double? abdominalPerimeter;
  final double? bodyFatPercentage;
  final double? muscleMass;

  // Condiciones médicas
  final List<MedicalCondition> medicalConditions;
  final List<String> allergies;
  final List<String> medications;
  final ActivityLevel activityLevel;

  // Objetivos nutricionales
  final String? nutritionalGoal;
  final double? targetWeight;
  final String? dietaryPreferences;

  // Datos de tratamiento
  final PatientStatus status;
  final bool hasActivePlan;
  final DateTime? lastVisitDate;
  final DateTime? nextAppointmentDate;
  final String? notes;
  final String? emergencyContact;
  final String? emergencyPhone;

  final DateTime createdAt;
  final DateTime? updatedAt;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender = Gender.masculino,
    this.dni,
    this.email,
    this.phone,
    this.profileImageUrl,
    this.weight,
    this.height,
    this.abdominalPerimeter,
    this.bodyFatPercentage,
    this.muscleMass,
    this.medicalConditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.activityLevel = ActivityLevel.sedentario,
    this.nutritionalGoal,
    this.targetWeight,
    this.dietaryPreferences,
    this.status = PatientStatus.nuevo,
    this.hasActivePlan = false,
    this.lastVisitDate,
    this.nextAppointmentDate,
    this.notes,
    this.emergencyContact,
    this.emergencyPhone,
    required this.createdAt,
    this.updatedAt,
  });

  // Getters útiles
  String get fullName => '$firstName $lastName';

  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  double get bmi {
    if (weight == null || height == null) return 0.0;
    return weight! / ((height! / 100) * (height! / 100));
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == 0.0) return 'Sin datos';
    if (bmiValue < 18.5) return 'Bajo peso';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  // Calcular TMB (Tasa Metabólica Basal) usando fórmula Harris-Benedict
  double get bmr {
    if (weight == null || height == null || birthDate == null) return 0.0;

    if (gender == Gender.masculino) {
      return 88.362 + (13.397 * weight!) + (4.799 * height!) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight!) + (3.098 * height!) - (4.330 * age);
    }
  }

  // Calorías diarias necesarias
  double get dailyCalories => bmr * activityLevel.multiplier;

  // Verificar si tiene diabetes
  bool get hasDiabetes => medicalConditions.any((condition) => condition.isDiabetes);

  // Verificar si requiere dieta especial
  bool get requiresSpecialDiet => medicalConditions.any((condition) => condition.requiresSpecialDiet);

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'])
          : null,
      gender: json['gender'] != null
          ? Gender.fromApiValue(json['gender'])
          : Gender.masculino,
      dni: json['dni'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profile_image_url'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      abdominalPerimeter: json['abdominal_perimeter']?.toDouble(),
      bodyFatPercentage: json['body_fat_percentage']?.toDouble(),
      muscleMass: json['muscle_mass']?.toDouble(),
      medicalConditions: json['medical_conditions'] != null
          ? (json['medical_conditions'] as List)
          .map((e) => MedicalCondition.fromApiValue(e))
          .toList()
          : [],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : [],
      medications: json['medications'] != null
          ? List<String>.from(json['medications'])
          : [],
      activityLevel: json['activity_level'] != null
          ? ActivityLevel.fromApiValue(json['activity_level'])
          : ActivityLevel.sedentario,
      nutritionalGoal: json['nutritional_goal'],
      targetWeight: json['target_weight']?.toDouble(),
      dietaryPreferences: json['dietary_preferences'],
      status: json['status'] != null
          ? PatientStatus.fromApiValue(json['status'])
          : PatientStatus.nuevo,
      hasActivePlan: json['has_active_plan'] ?? false,
      lastVisitDate: json['last_visit_date'] != null
          ? DateTime.tryParse(json['last_visit_date'])
          : null,
      nextAppointmentDate: json['next_appointment_date'] != null
          ? DateTime.tryParse(json['next_appointment_date'])
          : null,
      notes: json['notes'],
      emergencyContact: json['emergency_contact'],
      emergencyPhone: json['emergency_phone'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender.apiValue,
      'dni': dni,
      'email': email,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'weight': weight,
      'height': height,
      'abdominal_perimeter': abdominalPerimeter,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass': muscleMass,
      'medical_conditions': medicalConditions.map((e) => e.apiValue).toList(),
      'allergies': allergies,
      'medications': medications,
      'activity_level': activityLevel.apiValue,
      'nutritional_goal': nutritionalGoal,
      'target_weight': targetWeight,
      'dietary_preferences': dietaryPreferences,
      'status': status.apiValue,
      'has_active_plan': hasActivePlan,
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'next_appointment_date': nextAppointmentDate?.toIso8601String(),
      'notes': notes,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Patient copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    double? weight,
    double? height,
    double? abdominalPerimeter,
    double? bodyFatPercentage,
    double? muscleMass,
    List<MedicalCondition>? medicalConditions,
    List<String>? allergies,
    List<String>? medications,
    ActivityLevel? activityLevel,
    String? nutritionalGoal,
    double? targetWeight,
    String? dietaryPreferences,
    PatientStatus? status,
    bool? hasActivePlan,
    DateTime? lastVisitDate,
    DateTime? nextAppointmentDate,
    String? notes,
    String? emergencyContact,
    String? emergencyPhone,
  }) {
    return Patient(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate,
      gender: gender,
      dni: dni,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      abdominalPerimeter: abdominalPerimeter ?? this.abdominalPerimeter,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMass: muscleMass ?? this.muscleMass,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      activityLevel: activityLevel ?? this.activityLevel,
      nutritionalGoal: nutritionalGoal ?? this.nutritionalGoal,
      targetWeight: targetWeight ?? this.targetWeight,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      status: status ?? this.status,
      hasActivePlan: hasActivePlan ?? this.hasActivePlan,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      nextAppointmentDate: nextAppointmentDate ?? this.nextAppointmentDate,
      notes: notes ?? this.notes,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
class AppointmentEnhanced {
  final String id;
  final String patientId;
  final String? nutritionistId;
  final AppointmentType type;
  final AppointmentStatus status;
  final AppointmentPriority priority; // NUEVO
  final DateTime scheduledDate;
  final int durationMinutes;
  final String? reason;
  final String? notes;
  final String? prescriptions;
  final double? weight;
  final double? height;
  final String? nextAppointmentNotes;
  final DateTime? nextAppointmentDate;
  final String? patientName;
  final Patient? patient; // NUEVO - para traer datos completos del paciente
  final DateTime createdAt;
  final DateTime? updatedAt;

  AppointmentEnhanced({
    required this.id,
    required this.patientId,
    this.nutritionistId,
    required this.type,
    required this.status,
    this.priority = AppointmentPriority.normal,
    required this.scheduledDate,
    this.durationMinutes = 60,
    this.reason,
    this.notes,
    this.prescriptions,
    this.weight,
    this.height,
    this.nextAppointmentNotes,
    this.nextAppointmentDate,
    this.patientName,
    this.patient,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppointmentEnhanced.fromJson(Map<String, dynamic> json) {
    return AppointmentEnhanced(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      nutritionistId: json['nutritionist_id'],
      type: json['type'] != null
          ? AppointmentType.fromApiValue(json['type'])
          : AppointmentType.seguimiento,
      status: json['status'] != null
          ? AppointmentStatus.fromApiValue(json['status'])
          : AppointmentStatus.programada,
      priority: json['priority'] != null
          ? AppointmentPriority.fromApiValue(json['priority'])
          : AppointmentPriority.normal,
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.tryParse(json['scheduled_date']) ?? DateTime.now()
          : DateTime.now(),
      durationMinutes: json['duration_minutes'] ?? 60,
      reason: json['reason'],
      notes: json['notes'],
      prescriptions: json['prescriptions'],
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      nextAppointmentNotes: json['next_appointment_notes'],
      nextAppointmentDate: json['next_appointment_date'] != null
          ? DateTime.tryParse(json['next_appointment_date'])
          : null,
      patientName: json['patient_name'],
      patient: json['patient'] != null ? Patient.fromJson(json['patient']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'nutritionist_id': nutritionistId,
      'type': type.apiValue,
      'status': status.apiValue,
      'priority': priority.apiValue,
      'scheduled_date': scheduledDate.toIso8601String(),
      'duration_minutes': durationMinutes,
      'reason': reason,
      'notes': notes,
      'prescriptions': prescriptions,
      'weight': weight,
      'height': height,
      'next_appointment_notes': nextAppointmentNotes,
      'next_appointment_date': nextAppointmentDate?.toIso8601String(),
      'patient_name': patientName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Getters útiles
  bool get isUrgent => priority == AppointmentPriority.urgente;
  bool get isToday => DateUtils.isSameDay(scheduledDate, DateTime.now());
  bool get isPast => scheduledDate.isBefore(DateTime.now());
  bool get canReschedule => status == AppointmentStatus.programada || status == AppointmentStatus.confirmada;
}
class NutritionistDashboard {
  final int totalPatients;
  final int activePatients;
  final int appointmentsToday;
  final int urgentAppointments;
  final Map<MedicalCondition, int> patientsByCondition;
  final List<AppointmentEnhanced> todayAppointments;
  final List<Patient> urgentPatients;

  NutritionistDashboard({
    required this.totalPatients,
    required this.activePatients,
    required this.appointmentsToday,
    required this.urgentAppointments,
    required this.patientsByCondition,
    required this.todayAppointments,
    required this.urgentPatients,
  });

  factory NutritionistDashboard.fromJson(Map<String, dynamic> json) {
    return NutritionistDashboard(
      totalPatients: json['total_patients'] ?? 0,
      activePatients: json['active_patients'] ?? 0,
      appointmentsToday: json['appointments_today'] ?? 0,
      urgentAppointments: json['urgent_appointments'] ?? 0,
      patientsByCondition: _parsePatientsByCondition(json['patients_by_condition']),
      todayAppointments: (json['today_appointments'] as List?)
          ?.map((e) => AppointmentEnhanced.fromJson(e))
          .toList() ?? [],
      urgentPatients: (json['urgent_patients'] as List?)
          ?.map((e) => Patient.fromJson(e))
          .toList() ?? [],
    );
  }

  static Map<MedicalCondition, int> _parsePatientsByCondition(Map<String, dynamic>? json) {
    if (json == null) return {};

    final Map<MedicalCondition, int> result = {};
    json.forEach((key, value) {
      final condition = MedicalCondition.fromApiValue(key);
      result[condition] = value as int;
    });
    return result;
  }
}
class NutritionPlan {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final PlanStatus status;
  final List<MealType> includedMealTypes;
  final Map<String, List<Meal>> weeklyMeals;
  final DateTime startDate;
  final DateTime endDate;
  final double targetCalories;
  final double targetProtein;
  final double targetCarbs;
  final double targetFat;
  final String? specialInstructions;
  final List<String> restrictions;
  final String generatedBy; // 'ai' o 'manual'
  final DateTime createdAt;
  final DateTime updatedAt;

  NutritionPlan({
    required this.id,
    required this.patientId,
    required this.title,
    required this.description,
    required this.status,
    required this.includedMealTypes,
    required this.weeklyMeals,
    required this.startDate,
    required this.endDate,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFat,
    this.specialInstructions,
    this.restrictions = const [],
    this.generatedBy = 'ai',
    required this.createdAt,
    required this.updatedAt,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      id: json['id'],
      patientId: json['patient_id'],
      title: json['title'],
      description: json['description'],
      status: PlanStatus.fromApiValue(json['status']),
      includedMealTypes: (json['included_meal_types'] as List)
          .map((e) => MealType.fromApiValue(e))
          .toList(),
      weeklyMeals: _parseWeeklyMeals(json['weekly_meals']),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      targetCalories: json['target_calories']?.toDouble() ?? 0.0,
      targetProtein: json['target_protein']?.toDouble() ?? 0.0,
      targetCarbs: json['target_carbs']?.toDouble() ?? 0.0,
      targetFat: json['target_fat']?.toDouble() ?? 0.0,
      specialInstructions: json['special_instructions'],
      restrictions: List<String>.from(json['restrictions'] ?? []),
      generatedBy: json['generated_by'] ?? 'ai',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static Map<String, List<Meal>> _parseWeeklyMeals(Map<String, dynamic>? json) {
    if (json == null) return {};

    final Map<String, List<Meal>> result = {};
    json.forEach((day, meals) {
      result[day] = (meals as List)
          .map((mealJson) => Meal.fromJson(mealJson))
          .toList();
    });
    return result;
  }

  bool get isActive => status == PlanStatus.activo;
  int get totalDays => endDate.difference(startDate).inDays + 1;
  int get remainingDays => endDate.difference(DateTime.now()).inDays;
}
class Meal {
  final String id;
  final MealType mealType;
  final String name;
  final String description;
  final List<FoodItem> foodItems;
  final String? instructions;
  final String? imageUrl;
  final DateTime? scheduledTime;

  Meal({
    required this.id,
    required this.mealType,
    required this.name,
    required this.description,
    required this.foodItems,
    this.instructions,
    this.imageUrl,
    this.scheduledTime,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'],
      mealType: MealType.fromApiValue(json['meal_type']),
      name: json['name'],
      description: json['description'],
      foodItems: (json['food_items'] as List)
          .map((item) => FoodItem.fromJson(item))
          .toList(),
      instructions: json['instructions'],
      imageUrl: json['image_url'],
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'])
          : null,
    );
  }

  double get totalCalories => foodItems.fold(0, (sum, item) => sum + item.calories);
  double get totalProtein => foodItems.fold(0, (sum, item) => sum + item.protein);
  double get totalCarbs => foodItems.fold(0, (sum, item) => sum + item.carbs);
  double get totalFat => foodItems.fold(0, (sum, item) => sum + item.fat);
}
class FoodItem {
  final String name;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sodium;

  FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.sodium,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'],
      quantity: json['quantity']?.toDouble() ?? 0.0,
      unit: json['unit'],
      calories: json['calories']?.toDouble() ?? 0.0,
      protein: json['protein']?.toDouble() ?? 0.0,
      carbs: json['carbs']?.toDouble() ?? 0.0,
      fat: json['fat']?.toDouble() ?? 0.0,
      fiber: json['fiber']?.toDouble(),
      sodium: json['sodium']?.toDouble(),
    );
  }
}

class ApiConfig {
  static const String _prodBaseUrl = 'https://www.mottinnut.com/api/v1';

  // URLs de Beeceptor para desarrollo - diferentes perfiles
  static const String _devBaseUrl = 'https://mottinut.free.beeceptor.com/api/v1';       // Perfil principal
  static const String _devBaseUrl1 = 'https://mottinutv1.free.beeceptor.com/api/v1';   // Perfil 1
  static const String _devBaseUrl2 = 'https://mottinutv2.free.beeceptor.com/api/v1';   // Perfil 2

  static bool _isProduction = const bool.fromEnvironment('dart.vm.product');

  // Método para obtener la URL base según el endpoint
  static String getBaseUrlForEndpoint(String endpoint) {
    if (_isProduction) return _prodBaseUrl;

    // Distribución de endpoints por perfil de Beeceptor
    switch (endpoint) {
    // Perfil principal (mottinut.free.beeceptor.com)
      case '/patients':
      case '/nutrition-plans':
      case '/appointments':
      case '/nutrition-plans/generate':
      case '/auth':
      case '/appointments/by-date':
      case '/appointments/urgent':
      case '/appointments/{id}/reschedule':
        return _devBaseUrl;

    // Perfil 1 (mottinutv1.free.beeceptor.com)
      case '/patients/by-condition':
      case '/patients/diabetic':
      case '/patients/overweight':
      case '/patients/active':
        return _devBaseUrl1;

    // Perfil 2 (mottinutv2.free.beeceptor.com)
      case '/patients/urgent':
      case '/dashboard':
      case '/sample-plans':
        return _devBaseUrl2;

      default:
        return _devBaseUrl; // Fallback al perfil principal
    }
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  static const Duration timeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(minutes: 3);

  // Endpoints
  static const String patients = '/patients';
  static const String nutritionPlans = '/nutrition-plans';
  static const String appointments = '/appointments';
  static const String generatePlan = '/nutrition-plans/generate';
  static const String auth = '/auth';
  static const String appointmentsByDate = '/appointments/by-date';
  static const String urgentAppointments = '/appointments/urgent';
  static const String rescheduleAppointment = '/appointments/{id}/reschedule';
  static const String patientsByCondition = '/patients/by-condition';
  static const String diabeticPatients = '/patients/diabetic';
  static const String overweightPatients = '/patients/overweight';
  static const String urgentPatients = '/patients/urgent';
  static const String activePatients = '/patients/active';
  static const String dashboard = '/dashboard';
  static const String samplePlans = '/sample-plans';
}

class PatientServiceEnhanced extends BaseService {

  // OBTENER PACIENTES ACTIVOS
  Future<List<Patient>> getActivePatients() async {
    const endpoint = ApiConfig.activePatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER PACIENTES POR CONDICIÓN MÉDICA
  Future<List<Patient>> getPatientsByMedicalCondition(MedicalCondition condition) async {
    const endpoint = ApiConfig.patientsByCondition;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {'condition': condition.apiValue},
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER PACIENTES CON DIABETES
  Future<List<Patient>> getDiabeticPatients() async {
    const endpoint = ApiConfig.diabeticPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER PACIENTES CON SOBREPESO/OBESIDAD
  Future<List<Patient>> getOverweightPatients() async {
    const endpoint = ApiConfig.overweightPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER PACIENTES URGENTES (requieren atención inmediata)
  Future<List<Patient>> getUrgentPatients() async {
    const endpoint = ApiConfig.urgentPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  Future<List<Patient>> getAllPatients() async {
    const endpoint = ApiConfig.patients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER UN PACIENTE POR ID (Perfil principal)
  Future<Patient> getPatientById(String patientId) async {
    const endpoint = ApiConfig.patients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint/$patientId');

    return handleRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: '$endpoint/$patientId',
    );
  }

  // CREAR NUEVO PACIENTE (Perfil principal)
  Future<Patient> createPatient(Patient patient) async {
    const endpoint = ApiConfig.patients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleRequest(
          () => _client.post(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(patient.toJson()),
      ).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // ACTUALIZAR PACIENTE (Perfil principal)
  Future<Patient> updatePatient(String patientId, Patient patient) async {
    const endpoint = ApiConfig.patients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint/$patientId');

    return handleRequest(
          () => _client.put(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(patient.toJson()),
      ).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: '$endpoint/$patientId',
    );
  }

}

class NutritionPlanService extends BaseService {

  Future<List<NutritionPlan>> getPlansByPatient(
      String patientId, {
        PlanStatus? status,
      }) async {
    const endpoint = ApiConfig.nutritionPlans;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {
        'patient_id': patientId,
        if (status != null) 'status': status.apiValue,
      },
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      NutritionPlan.fromJson,
      endpoint: endpoint,
    );
  }

  Future<NutritionPlan> generatePlanWithAI({
    required String patientId,
    required Map<String, dynamic> patientData,
    int durationDays = 7,
    List<String>? specificRequests,
  }) async {
    const endpoint = ApiConfig.generatePlan;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    final requestBody = {
      'patient_id': patientId,
      'patient_data': patientData,
      'duration_days': durationDays,
      'specific_requests': specificRequests ?? [],
      'timestamp': DateTime.now().toIso8601String(),
    };

    return handleRequest(
          () => _client.post(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(requestBody),
      ).timeout(ApiConfig.aiTimeout),
      NutritionPlan.fromJson,
      endpoint: endpoint,
    );
  }

  Future<NutritionPlan> updatePlanStatus(String planId, PlanStatus status) async {
    const endpoint = ApiConfig.nutritionPlans;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint/$planId');

    return handleRequest(
          () => _client.patch(
        uri,
        headers: ApiConfig.headers,
        body: json.encode({
          'status': status.apiValue,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(ApiConfig.timeout),
      NutritionPlan.fromJson,
      endpoint: '$endpoint/$planId',
    );
  }

  // OBTENER PLANES DE MUESTRA (Perfil 2)
  Future<List<NutritionPlan>> getSamplePlans() async {
    const endpoint = ApiConfig.samplePlans;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      NutritionPlan.fromJson,
      endpoint: endpoint,
    );
  }

}

class AppointmentServiceEnhanced extends BaseService {

  // OBTENER CITAS POR DÍA
  Future<List<AppointmentEnhanced>> getAppointmentsByDate(DateTime date) async {
    const endpoint = ApiConfig.appointmentsByDate;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final dateStr = date.toIso8601String().split('T')[0]; // YYYY-MM-DD
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {'date': dateStr},
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      AppointmentEnhanced.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER CITAS DE HOY
  Future<List<AppointmentEnhanced>> getTodayAppointments() async {
    return getAppointmentsByDate(DateTime.now());
  }

  // OBTENER CITAS URGENTES
  Future<List<AppointmentEnhanced>> getUrgentAppointments() async {
    const endpoint = ApiConfig.urgentAppointments;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      AppointmentEnhanced.fromJson,
      endpoint: endpoint,
    );
  }
  // AGENDAR NUEVA CITA
  Future<AppointmentEnhanced> scheduleAppointment({
    required String patientId,
    required DateTime scheduledDate,
    required AppointmentType type,
    AppointmentPriority priority = AppointmentPriority.normal,
    int durationMinutes = 60,
    String? reason,
    String? notes,
  }) async {
    const endpoint = ApiConfig.appointments;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    final appointment = AppointmentEnhanced(
      id: '', // Se generará en el backend
      patientId: patientId,
      type: type,
      status: AppointmentStatus.programada,
      priority: priority,
      scheduledDate: scheduledDate,
      durationMinutes: durationMinutes,
      reason: reason,
      notes: notes,
      createdAt: DateTime.now(),
    );

    return handleRequest(
          () => _client.post(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(appointment.toJson()),
      ).timeout(ApiConfig.timeout),
      AppointmentEnhanced.fromJson,
      endpoint: endpoint,
    );
  }

  // REAGENDAR CITA
  Future<AppointmentEnhanced> rescheduleAppointment(
      String appointmentId,
      DateTime newDateTime,
      ) async {
    final endpoint = ApiConfig.rescheduleAppointment.replaceAll('{id}', appointmentId);
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(ApiConfig.rescheduleAppointment);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleRequest(
          () => _client.patch(
        uri,
        headers: ApiConfig.headers,
        body: json.encode({
          'new_scheduled_date': newDateTime.toIso8601String(),
          'status': AppointmentStatus.reprogramada.apiValue,
          'updated_at': DateTime.now().toIso8601String(),
        }),
      ).timeout(ApiConfig.timeout),
      AppointmentEnhanced.fromJson,
      endpoint: endpoint,
    );
  }

  // OBTENER TODAS LAS CITAS (Perfil principal)
  Future<List<AppointmentEnhanced>> getAllAppointments() async {
    const endpoint = ApiConfig.appointments;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      AppointmentEnhanced.fromJson,
      endpoint: endpoint,
    );
  }
}

class DashboardService extends BaseService {

  Future<NutritionistDashboard> getDashboardData() async {
    const endpoint = ApiConfig.dashboard;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      NutritionistDashboard.fromJson,
      endpoint: endpoint,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  final dynamic originalError;

  ApiException(
      this.message, {
        this.statusCode,
        this.endpoint,
        this.originalError,
      });

  @override
  String toString() {
    return 'ApiException: $message'
        '${statusCode != null ? ' (HTTP $statusCode)' : ''}'
        '${endpoint != null ? ' at $endpoint' : ''}';
  }

  bool get isNetworkError => statusCode == null;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
}


// 9. UTILIDADES PARA FECHAS
class DateUtils {
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  static String formatDateForApi(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  static String getWeekday(DateTime date) {
    const weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    return weekdays[date.weekday - 1];
  }
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
class ValidationUtils {
  static const String _emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String _phonePattern = r'^\+?[\d\s\-\(\)]{8,15}$';
  static const String _dniPattern = r'^\d{8}$';

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) return null;

    if (!RegExp(_emailPattern).hasMatch(email.trim())) {
      return 'Formato de email inválido';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;

    if (!RegExp(_phonePattern).hasMatch(phone.trim())) {
      return 'Formato de teléfono inválido';
    }
    return null;
  }

  static String? validateDNI(String? dni) {
    final error = validateRequired(dni, 'DNI');
    if (error != null) return error;

    if (!RegExp(_dniPattern).hasMatch(dni!.trim())) {
      return 'DNI debe tener exactamente 8 dígitos';
    }
    return null;
  }

  static String? validateWeight(double? weight) {
    if (weight == null) return 'Peso es requerido';
    if (weight < 20 || weight > 300) {
      return 'Peso debe estar entre 20 y 300 kg';
    }
    return null;
  }

  static String? validateHeight(double? height) {
    if (height == null) return 'Altura es requerida';
    if (height < 100 || height > 250) {
      return 'Altura debe estar entre 100 y 250 cm';
    }
    return null;
  }

  static String? validateAge(DateTime? birthDate) {
    if (birthDate == null) return 'Fecha de nacimiento es requerida';

    final age = DateTime.now().difference(birthDate).inDays ~/ 365;
    if (age < 0 || age > 120) {
      return 'Edad inválida';
    }
    return null;
  }
}
class FormatUtils {
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatBMI(double bmi) {
    return bmi.toStringAsFixed(1);
  }

  static String formatWeight(double weight) {
    return '${weight.toStringAsFixed(1)} kg';
  }

  static String formatHeight(double height) {
    return '${height.toStringAsFixed(0)} cm';
  }

  static String formatCalories(double calories) {
    return '${calories.toStringAsFixed(0)} kcal';
  }

  static String formatAge(int age) {
    return '$age años';
  }
}
class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    return _prefs?.getString(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    return _prefs?.getBool(key);
  }

  static Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static Future<int?> getInt(String key) async {
    return _prefs?.getInt(key);
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
class AppConstants {
  // Configuración de la app
  static const String appName = 'MottinNut Pro';
  static const String appVersion = '1.0.0';

  // Límites de la aplicación
  static const int maxPatientsPerPage = 20;
  static const int maxUploadSize = 5 * 1024 * 1024; // 5MB
  static const int sessionTimeoutMinutes = 30;

  // Mensajes comunes
  static const String networkErrorMessage = 'Error de conexión. Verifica tu internet.';
  static const String unknownErrorMessage = 'Ha ocurrido un error inesperado.';
  static const String successMessage = 'Operación completada exitosamente.';

  // Claves de almacenamiento
  static const String userTokenKey = 'user_token';
  static const String lastSyncKey = 'last_sync';
  static const String userPreferencesKey = 'user_preferences';
}

abstract class BaseService {
  final http.Client _client = http.Client();

  Future<T> handleRequest<T>(
      Future<http.Response> Function() request,
      T Function(Map<String, dynamic>) fromJson, {
        required String endpoint,
      }) async {
    try {
      final response = await request();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);
        return fromJson(data);
      } else {
        throw ApiException(
          'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;

      throw ApiException(
        'Network error: ${e.toString()}',
        endpoint: endpoint,
        originalError: e,
      );
    }
  }

  Future<List<T>> handleListRequest<T>(
      Future<http.Response> Function() request,
      T Function(Map<String, dynamic>) fromJson, {
        required String endpoint,
      }) async {
    try {
      final response = await request();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic data = json.decode(response.body);

        // Manejar diferentes formatos de respuesta
        List<dynamic> items;
        if (data is List) {
          items = data;
        } else if (data is Map && data.containsKey('data')) {
          items = data['data'] as List;
        } else if (data is Map && data.containsKey('items')) {
          items = data['items'] as List;
        } else {
          throw ApiException('Unexpected response format', endpoint: endpoint);
        }

        return items.map((item) => fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(
          'Request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: endpoint,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;

      throw ApiException(
        'Network error: ${e.toString()}',
        endpoint: endpoint,
        originalError: e,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

enum LogLevel { debug, info, warning, error }
class Logger {
  static LogLevel _minLevel = LogLevel.info;

  static void setLevel(LogLevel level) {
    _minLevel = level;
  }

  static void debug(String message, [dynamic error]) {
    _log(LogLevel.debug, message, error);
  }

  static void info(String message, [dynamic error]) {
    _log(LogLevel.info, message, error);
  }

  static void warning(String message, [dynamic error]) {
    _log(LogLevel.warning, message, error);
  }

  static void error(String message, [dynamic error]) {
    _log(LogLevel.error, message, error);
  }

  static void _log(LogLevel level, String message, dynamic error) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();

    print('[$timestamp] $levelStr: $message');
    if (error != null) {
      print('Error details: $error');
    }
  }
}
