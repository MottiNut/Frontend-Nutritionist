import '../enums/gender.dart';

class Patient {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final Gender gender;
  final String dni;
  final String? email;
  final String? phone;
  final String? profileImageUrl;

  // Datos físicos
  final double weight;
  final double height;
  final double? abdominalPerimeter;

  // Datos médicos básicos
  final DiabetesType diabetesType;
  final List<String> allergies;
  final List<String> medications;
  final ActivityLevel activityLevel;

  // Datos de tratamiento
  final PatientStatus status;
  final bool hasNutritionalPlan;
  final DateTime? lastVisitDate;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.gender,
    required this.dni,
    this.email,
    this.phone,
    this.profileImageUrl,
    required this.weight,
    required this.height,
    this.abdominalPerimeter,
    this.diabetesType = DiabetesType.ninguna,
    this.allergies = const [],
    this.medications = const [],
    this.activityLevel = ActivityLevel.sedentario,
    this.status = PatientStatus.nuevo,
    this.hasNutritionalPlan = false,
    this.lastVisitDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getters útiles
  String get fullName => '$firstName $lastName';

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  double get bmi => weight / ((height / 100) * (height / 100));

  String get bmiCategory {
    if (bmi < 18.5) return 'Bajo peso';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  // Factory para crear desde JSON del API
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      birthDate: DateTime.parse(json['birth_date']),
      gender: Gender.fromApiValue(json['gender']),
      dni: json['dni'],
      email: json['email'],
      phone: json['phone'],
      profileImageUrl: json['profile_image_url'],
      weight: json['weight']?.toDouble() ?? 0.0,
      height: json['height']?.toDouble() ?? 0.0,
      abdominalPerimeter: json['abdominal_perimeter']?.toDouble(),
      diabetesType: DiabetesType.fromApiValue(json['diabetes_type'] ?? 'none'),
      allergies: List<String>.from(json['allergies'] ?? []),
      medications: List<String>.from(json['medications'] ?? []),
      activityLevel: ActivityLevel.fromApiValue(json['activity_level'] ?? 'sedentary'),
      status: PatientStatus.fromApiValue(json['status'] ?? 'new'),
      hasNutritionalPlan: json['has_nutritional_plan'] ?? false,
      lastVisitDate: json['last_visit_date'] != null
          ? DateTime.parse(json['last_visit_date'])
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convertir a JSON para enviar al API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate.toIso8601String(),
      'gender': gender.apiValue,
      'dni': dni,
      'email': email,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'weight': weight,
      'height': height,
      'abdominal_perimeter': abdominalPerimeter,
      'diabetes_type': diabetesType.apiValue,
      'allergies': allergies,
      'medications': medications,
      'activity_level': activityLevel.apiValue,
      'status': status.apiValue,
      'has_nutritional_plan': hasNutritionalPlan,
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método para actualizar datos
  Patient copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    double? weight,
    double? height,
    List<String>? allergies,
    List<String>? medications,
    ActivityLevel? activityLevel,
    PatientStatus? status,
    String? notes,
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
      abdominalPerimeter: abdominalPerimeter,
      diabetesType: diabetesType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      activityLevel: activityLevel ?? this.activityLevel,
      status: status ?? this.status,
      hasNutritionalPlan: hasNutritionalPlan,
      lastVisitDate: lastVisitDate,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class NutritionPlan {
  final String id;
  final String patientId;
  final String title;
  final String description;
  final PlanStatus status;
  final List<MealType> includedMealTypes;
  final Map<String, List<Meal>> weeklyMeals; // día -> comidas
  final DateTime startDate;
  final DateTime endDate;
  final double targetCalories;
  final String? specialInstructions;
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
    this.specialInstructions,
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
      specialInstructions: json['special_instructions'],
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

  FoodItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
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
    );
  }
}