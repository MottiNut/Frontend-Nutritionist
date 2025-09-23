import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'new/rutadirectaaa/api_endpoints.dart';
import 'new/rutadirectaaa/nutritionist_notification_service.dart';

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

  /// 🔤 Getter para inicial del género
  String get initial {
    switch (this) {
      case Gender.masculino:
        return 'M';
      case Gender.femenino:
        return 'F';
      case Gender.otro:
        return 'Otro';
    }
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
  descontrolado('Descontrolado', 'uncontrolled'),
  seguimiento('En Seguimiento', 'follow_up'),
  activo('Activo', 'active'),
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
enum HypertensionRisk {
  optimo('Óptimo', 'optimal'),
  normal('Normal', 'normal'),
  normalAlto('Normal Alto', 'normal_high'),
  hipertensionGrado1('Hipertensión Grado 1', 'grade1'),
  hipertensionGrado2('Hipertensión Grado 2', 'grade2'),
  hipertensionGrado3('Hipertensión Grado 3', 'grade3'),
  hipertensionSistolicaAislada('Hipertensión Sistólica Aislada', 'isolated_systolic');

  const HypertensionRisk(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static HypertensionRisk fromApiValue(String apiValue) {
    return HypertensionRisk.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => HypertensionRisk.normal,
    );
  }

  // Método para obtener el texto corto para badges
  String get shortText {
    switch (this) {
      case HypertensionRisk.optimo:
        return 'ÓPT';
      case HypertensionRisk.normal:
        return 'NOR';
      case HypertensionRisk.normalAlto:
        return 'N.ALT';
      case HypertensionRisk.hipertensionGrado1:
        return 'G1';
      case HypertensionRisk.hipertensionGrado2:
        return 'G2';
      case HypertensionRisk.hipertensionGrado3:
        return 'G3';
      case HypertensionRisk.hipertensionSistolicaAislada:
        return 'HSA';
    }
  }

  // Método para obtener el color asociado
  Color get color {
    switch (this) {
      case HypertensionRisk.optimo:
        return Colors.green[600]!;
      case HypertensionRisk.normal:
        return Colors.green[500]!;
      case HypertensionRisk.normalAlto:
        return Colors.yellow[600]!;
      case HypertensionRisk.hipertensionGrado1:
        return Colors.orange[600]!;
      case HypertensionRisk.hipertensionGrado2:
        return Colors.red[600]!;
      case HypertensionRisk.hipertensionGrado3:
        return Colors.red[800]!;
      case HypertensionRisk.hipertensionSistolicaAislada:
        return Colors.purple[600]!;
    }
  }

  // Método estático para calcular riesgo basado en presión arterial
  static HypertensionRisk calculateFromBP(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) {
      return HypertensionRisk.optimo;
    } else if (systolic < 130 && diastolic < 85) {
      return HypertensionRisk.normal;
    } else if (systolic < 140 && diastolic < 90) {
      return HypertensionRisk.normalAlto;
    } else if (systolic < 160 && diastolic < 100) {
      return HypertensionRisk.hipertensionGrado1;
    } else if (systolic < 180 && diastolic < 110) {
      return HypertensionRisk.hipertensionGrado2;
    } else if (systolic >= 180 || diastolic >= 110) {
      return HypertensionRisk.hipertensionGrado3;
    } else if (systolic >= 140 && diastolic < 90) {
      return HypertensionRisk.hipertensionSistolicaAislada;
    }
    return HypertensionRisk.normal;
  }
}
enum HypertensionTreatment {
  sinTratamiento('Sin Tratamiento', 'no_treatment'),
  cambiosEstiloVida('Cambios en Estilo de Vida', 'lifestyle_changes'),
  monoterapia('Monoterapia', 'monotherapy'),
  terapiaCombinada('Terapia Combinada', 'combination_therapy'),
  terapiaTriple('Terapia Triple', 'triple_therapy'),
  tratamientoResistente('Tratamiento Resistente', 'resistant_treatment');

  const HypertensionTreatment(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static HypertensionTreatment fromApiValue(String apiValue) {
    return HypertensionTreatment.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => HypertensionTreatment.sinTratamiento,
    );
  }
}
enum BloodPressureCategory {
  optima('Óptima', 'optimal'),
  normal('Normal', 'normal'),
  normalAlta('Normal Alta', 'normal_high'),
  hipertensionLigera('Hipertensión Ligera', 'mild_hypertension'),
  hipertensionModerada('Hipertensión Moderada', 'moderate_hypertension'),
  hipertensionSevera('Hipertensión Severa', 'severe_hypertension'),
  crisisHipertensiva('Crisis Hipertensiva', 'hypertensive_crisis');

  const BloodPressureCategory(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static BloodPressureCategory fromApiValue(String apiValue) {
    return BloodPressureCategory.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => BloodPressureCategory.normal,
    );
  }
}
enum MedicalCondition {
  ninguna('Sin Condición Médica', 'none'),
  diabetesTipo1('Diabetes Tipo 1', 'diabetes_type1'),
  diabetesTipo2('Diabetes Tipo 2', 'diabetes_type2'),
  hipertension('Hipertensión', 'hypertension'),
  obesidad('Obesidad', 'obesity'),
  sobrepeso('Sobrepeso', 'overweight');

  const MedicalCondition(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static MedicalCondition fromApiValue(String apiValue) {
    return MedicalCondition.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => MedicalCondition.ninguna,
    );
  }

  // Getters para identificar tipos de enfermedades
  bool get isDiabetes => this == diabetesTipo1 || this == diabetesTipo2;
  bool get isWeightRelated => this == obesidad || this == sobrepeso;
  bool get isHypertension => this == hipertension;
  bool get requiresSpecialDiet => this != ninguna;
  bool get requiresUrgentCare => this == diabetesTipo1 || this == hipertension;
  bool get requiresFrequentMonitoring => isDiabetes || isHypertension;
}
// Enum de peso/obesidad
enum WeightCategory {
  normal('Peso Normal', 'normal'),
  sobrepeso('Sobrepeso', 'overweight'),
  obesidadGrado1('Obesidad Grado I', 'obesity_grade1'),
  obesidadGrado2('Obesidad Grado II', 'obesity_grade2'),
  obesidadGrado3('Obesidad Grado III', 'obesity_grade3');

  const WeightCategory(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static WeightCategory fromBMI(double bmi) {
    if (bmi < 25) return normal;
    if (bmi < 30) return sobrepeso;
    if (bmi < 35) return obesidadGrado1;
    if (bmi < 40) return obesidadGrado2;
    return obesidadGrado3;
  }

  static WeightCategory fromApiValue(String apiValue) {
    return WeightCategory.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => WeightCategory.normal,
    );
  }

  bool get requiresNutritionalIntervention => this != normal;
  bool get isObesity => index >= 2; // obesidadGrado1 en adelante
}
// Enum para niveles de diabetes
enum DiabetesLevel {
  none('Sin Diabetes', 'none'),
  prediabetes('Prediabetes', 'prediabetes'),
  controlada('Controlada', 'controlled'),
  descontrolada('Descontrolada', 'uncontrolled'),
  critica('Crítica', 'critical');

  const DiabetesLevel(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static DiabetesLevel fromApiValue(String apiValue) {
    return DiabetesLevel.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => DiabetesLevel.none,
    );
  }

  bool get requiresUrgentCare => this == critica;
  bool get requiresFrequentMonitoring => this != none && this != prediabetes;
}
// 5. ENUM PARA NIVEL DE RIESGO
enum RiskLevel {
  ninguno('ninguno', 'Sin riesgo'),
  bajo('bajo', 'Riesgo bajo'),
  moderado('moderado', 'Riesgo moderado'),
  alto('alto', 'Riesgo alto');

  const RiskLevel(this.apiValue, this.displayName);
  final String apiValue;
  final String displayName;

  static RiskLevel fromApiValue(String value) {
    return RiskLevel.values.firstWhere(
          (level) => level.apiValue == value,
      orElse: () => RiskLevel.ninguno,
    );
  }
}
//para comorbilidades
enum Comorbidity {
  asma('Asma'),
  artritis('Artritis'),
  dislipidemia('Dislipidemia'),
  enfermedadRenal('Enfermedad renal crónica'),
  enfermedadHepatica('Enfermedad hepática'),
  trastornosTiroides('Trastornos de tiroides'),
  ansiedadDepresion('Ansiedad o depresión'),
  apneaDelSueno('Apnea del sueño'),
  piePlano('Pie plano'),
  escoliosis('Escoliosis'),
  artrosis('Artrosis'),
  reflujoGastroesofagico('Reflujo gastroesofágico'),
  ninguna('Ninguna');

  final String displayName;
  const Comorbidity(this.displayName);
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
  final String? maritalStatus;
  final String? address;
  final String? profileImageUrl;

  // Datos físicos básicos
  final double? weight;
  final double? height;
  final double? abdominalPerimeter;
  final double? bodyFatPercentage;
  final double? muscleMass;
  final WeightCategory? weightCategory;

  // DATOS ESPECÍFICOS PARA HIPERTENSIÓN
  final int? systolicBP;
  final int? diastolicBP;
  final String? bloodPressure;
  final HypertensionRisk? hypertensionRisk;
  final HypertensionTreatment? hypertensionTreatment;
  final BloodPressureCategory? bpCategory;
  final bool? isBPControlled;
  final DateTime? lastBPMeasurement;
  final List<String>? bpMedications;

  // DATOS ESPECÍFICOS PARA DIABETES
  final double? glucoseLevel; // mg/dL
  final double? hba1c; // Hemoglobina glicosilada
  final DiabetesLevel? diabetesLevel;
  final bool? isDiabetesControlled;
  final DateTime? lastGlucoseTest;
  final List<String>? diabetesMedications;
  final String? insulinType;
  final bool? requiresInsulin;

  // DATOS ESPECÍFICOS PARA OBESIDAD/SOBREPESO
  final double? targetWeight;
  final double? weightLossGoal; // kg a perder
  final DateTime? weightLossStartDate;
  final List<double>? weightHistory; // Historial de pesos
  final DateTime? lastWeightMeasurement;
  final String? dietaryRestrictions;

  // Condiciones médicas (ahora enfocado en las 3 principales)
  final List<MedicalCondition> medicalConditions;
  final List<String> allergies;
  final List<String> medications;
  final ActivityLevel activityLevel;

  // Objetivos y tratamiento
  final String? nutritionalGoal;
  final String? dietaryPreferences;
  final PatientStatus status;
  final bool hasActivePlan;
  final DateTime? lastVisitDate;
  final DateTime? nextAppointmentDate;
  final String? notes;
  final String? emergencyContact;
  final String? emergencyPhone;

  // Control general
  final bool? isNewPatient;
  final bool? hasNutritionalPlan;
  final DateTime? nextAppointment;
  final DateTime? lastVisit;
  final TimeOfDay? lastVisitTime;
  final DateTime createdAt;
  final DateTime? updatedAt;

  //new data
  final PatientFiliation? filiation;
  final MedicalHistory? medicalHistory;
  final NutritionalProfile? nutritionalProfile;
  final RiskFactors? riskFactors;


  Patient({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.birthDate,
    this.gender = Gender.masculino,
    this.dni,
    this.email,
    this.phone,
    this.maritalStatus,
    this.address,
    this.profileImageUrl,
    // Datos físicos
    this.weight,
    this.height,
    this.abdominalPerimeter,
    this.bodyFatPercentage,
    this.muscleMass,
    this.weightCategory,
    // Hipertensión
    this.systolicBP,
    this.diastolicBP,
    this.bloodPressure,
    this.hypertensionRisk,
    this.hypertensionTreatment,
    this.bpCategory,
    this.isBPControlled,
    this.lastBPMeasurement,
    this.bpMedications,
    // Diabetes
    this.glucoseLevel,
    this.hba1c,
    this.diabetesLevel,
    this.isDiabetesControlled,
    this.lastGlucoseTest,
    this.diabetesMedications,
    this.insulinType,
    this.requiresInsulin,
    // Obesidad/Sobrepeso
    this.targetWeight,
    this.weightLossGoal,
    this.weightLossStartDate,
    this.weightHistory,
    this.lastWeightMeasurement,
    this.dietaryRestrictions,
    // Condiciones y tratamiento
    this.medicalConditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.activityLevel = ActivityLevel.sedentario,
    this.nutritionalGoal,
    this.dietaryPreferences,
    this.status = PatientStatus.nuevo,
    this.hasActivePlan = false,
    this.lastVisitDate,
    this.nextAppointmentDate,
    this.notes,
    this.emergencyContact,
    this.emergencyPhone,
    // Control
    this.isNewPatient,
    this.hasNutritionalPlan,
    this.nextAppointment,
    this.lastVisit,
    this.lastVisitTime,
    required this.createdAt,
    this.updatedAt,

    this.filiation,
    this.medicalHistory,
    this.nutritionalProfile,
    this.riskFactors,

  });

  // ==================== GETTERS BÁSICOS ====================
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

  WeightCategory get calculatedWeightCategory {
    return weightCategory ?? WeightCategory.fromBMI(bmi);
  }

  // ==================== GETTERS ESPECÍFICOS POR ENFERMEDAD ====================

  // DIABETES
  bool get hasDiabetes => medicalConditions.any((condition) => condition.isDiabetes);
  bool get hasDiabetesType1 => medicalConditions.contains(MedicalCondition.diabetesTipo1);
  bool get hasDiabetesType2 => medicalConditions.contains(MedicalCondition.diabetesTipo2);

  String get diabetesStatus {
    if (!hasDiabetes) return 'Sin diabetes';
    if (diabetesLevel != null) return diabetesLevel!.displayName;
    return isDiabetesControlled == true ? 'Controlada' : 'Requiere evaluación';
  }

  bool get requiresDiabeticDiet => hasDiabetes;
  bool get requiresGlucoseMonitoring => hasDiabetes && diabetesLevel != DiabetesLevel.none;

  // HIPERTENSIÓN
  bool get hasHypertension => medicalConditions.contains(MedicalCondition.hipertension);

  HypertensionRisk get calculatedHypertensionRisk {
    if (systolicBP != null && diastolicBP != null) {
      return HypertensionRisk.calculateFromBP(systolicBP!, diastolicBP!);
    }
    return hypertensionRisk ?? HypertensionRisk.normal;
  }

  String get bloodPressureText {
    if (bloodPressure != null && bloodPressure!.isNotEmpty) {
      return bloodPressure!;
    }
    if (systolicBP != null && diastolicBP != null) {
      return '$systolicBP/$diastolicBP';
    }
    return 'Sin datos';
  }

  bool get requiresHypertensionMonitoring => hasHypertension;

  // OBESIDAD/SOBREPESO
  bool get hasWeightIssues => medicalConditions.any((condition) => condition.isWeightRelated);
  bool get hasObesity => medicalConditions.contains(MedicalCondition.obesidad) ||
      calculatedWeightCategory.isObesity;
  bool get hasOverweight => medicalConditions.contains(MedicalCondition.sobrepeso) ||
      calculatedWeightCategory == WeightCategory.sobrepeso;

  double get weightToLose {
    if (targetWeight != null && weight != null) {
      return weight! - targetWeight!;
    }
    return weightLossGoal ?? 0.0;
  }

  bool get requiresWeightManagement => hasWeightIssues || calculatedWeightCategory.requiresNutritionalIntervention;

  // ==================== GETTERS DE URGENCIA Y PRIORIDAD ====================

  bool get requiresUrgentAttention {
    // Crisis hipertensiva
    if (systolicBP != null && diastolicBP != null) {
      if (systolicBP! >= 180 || diastolicBP! >= 110) return true;
    }

    // Diabetes crítica
    if (diabetesLevel == DiabetesLevel.critica) return true;
    if (glucoseLevel != null && (glucoseLevel! > 400 || glucoseLevel! < 70)) return true;

    // Obesidad mórbida
    if (bmi > 40) return true;

    return false;
  }

  AppointmentPriority get recommendedAppointmentPriority {
    if (requiresUrgentAttention) return AppointmentPriority.urgente;

    // Alta prioridad para pacientes descontrolados
    if (isDiabetesControlled == false || isBPControlled == false) {
      return AppointmentPriority.alta;
    }

    // Prioridad normal para seguimiento regular
    if (hasDiabetes || hasHypertension || hasWeightIssues) {
      return AppointmentPriority.normal;
    }

    return AppointmentPriority.baja;
  }

  int get recommendedFollowUpDays {
    if (requiresUrgentAttention) return 7; // 1 semana
    if (isDiabetesControlled == false || isBPControlled == false) return 14; // 2 semanas
    if (hasDiabetes || hasHypertension) return 30; // 1 mes
    if (hasWeightIssues) return 21; // 3 semanas
    return 60; // 2 meses para mantenimiento
  }

  // Validaciones de completitud de datos
  bool get hasCompleteNutritionalAssessment =>
      filiation != null &&
          medicalHistory != null &&
          nutritionalProfile != null &&
          riskFactors != null;

  bool get requiresNutritionalAssessment =>
      filiation == null ||
          medicalHistory == null ||
          nutritionalProfile == null ||
          riskFactors == null;

  // Nivel de riesgo general
  RiskLevel get overallRiskLevel {
    if (riskFactors != null) {
      return riskFactors!.calculatedRiskLevel;
    }
    return RiskLevel.ninguno;
  }


  // ✅ MÉTODO HELPER para parsear TimeOfDay desde String
  static TimeOfDay? _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parsing time: $timeString');
    }
    return null;
  }

  // ✅ MÉTODO HELPER para convertir TimeOfDay a String
  static String? _timeOfDayToString(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ==================== MÉTODOS DE CONVERSIÓN ====================

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
      maritalStatus: json['marital_status'],
      address: json['address'],
      profileImageUrl: json['profile_image_url'],

      // Datos físicos
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      abdominalPerimeter: json['abdominal_perimeter']?.toDouble(),
      bodyFatPercentage: json['body_fat_percentage']?.toDouble(),
      muscleMass: json['muscle_mass']?.toDouble(),
      weightCategory: json['weight_category'] != null
          ? WeightCategory.fromApiValue(json['weight_category'])
          : null,

      // Hipertensión
      systolicBP: json['systolic_bp']?.toInt(),
      diastolicBP: json['diastolic_bp']?.toInt(),
      bloodPressure: json['blood_pressure'],
      hypertensionRisk: json['hypertension_risk'] != null
          ? HypertensionRisk.fromApiValue(json['hypertension_risk'])
          : null,
      hypertensionTreatment: json['hypertension_treatment'] != null
          ? HypertensionTreatment.fromApiValue(json['hypertension_treatment'])
          : null,
      bpCategory: json['bp_category'] != null
          ? BloodPressureCategory.fromApiValue(json['bp_category'])
          : null,
      isBPControlled: json['is_bp_controlled'],
      lastBPMeasurement: json['last_bp_measurement'] != null
          ? DateTime.tryParse(json['last_bp_measurement'])
          : null,
      bpMedications: json['bp_medications'] != null
          ? List<String>.from(json['bp_medications'])
          : null,

      // Diabetes
      glucoseLevel: json['glucose_level']?.toDouble(),
      hba1c: json['hba1c']?.toDouble(),
      diabetesLevel: json['diabetes_level'] != null
          ? DiabetesLevel.fromApiValue(json['diabetes_level'])
          : null,
      isDiabetesControlled: json['is_diabetes_controlled'],
      lastGlucoseTest: json['last_glucose_test'] != null
          ? DateTime.tryParse(json['last_glucose_test'])
          : null,
      diabetesMedications: json['diabetes_medications'] != null
          ? List<String>.from(json['diabetes_medications'])
          : null,
      insulinType: json['insulin_type'],
      requiresInsulin: json['requires_insulin'],

      // Obesidad/Sobrepeso
      targetWeight: json['target_weight']?.toDouble(),
      weightLossGoal: json['weight_loss_goal']?.toDouble(),
      weightLossStartDate: json['weight_loss_start_date'] != null
          ? DateTime.tryParse(json['weight_loss_start_date'])
          : null,
      weightHistory: json['weight_history'] != null
          ? List<double>.from(json['weight_history'].map((x) => x.toDouble()))
          : null,
      lastWeightMeasurement: json['last_weight_measurement'] != null
          ? DateTime.tryParse(json['last_weight_measurement'])
          : null,
      dietaryRestrictions: json['dietary_restrictions'],

      // Condiciones médicas
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

      // Objetivos y tratamiento
      nutritionalGoal: json['nutritional_goal'],
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

      //data de generar nutri
      filiation: json['filiation'] != null
          ? PatientFiliation.fromJson(json['filiation'])
          : null,
      medicalHistory: json['medical_history'] != null
          ? MedicalHistory.fromJson(json['medical_history'])
          : null,
      nutritionalProfile: json['nutritional_profile'] != null
          ? NutritionalProfile.fromJson(json['nutritional_profile'])
          : null,
      riskFactors: json['risk_factors'] != null
          ? RiskFactors.fromJson(json['risk_factors'])
          : null,

      // Control
      isNewPatient: json['is_new_patient'],
      hasNutritionalPlan: json['has_nutritional_plan'],
      nextAppointment: json['next_appointment'] != null
          ? DateTime.tryParse(json['next_appointment'])
          : null,
      lastVisit: json['last_visit'] != null
          ? DateTime.tryParse(json['last_visit'])
          : null,
      lastVisitTime: json['last_visit_time'] != null
          ? _parseTimeOfDay(json['last_visit_time'])
          : null,
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
      'marital_status': maritalStatus,
      'address': address,
      'profile_image_url': profileImageUrl,

      // Datos físicos
      'weight': weight,
      'height': height,
      'abdominal_perimeter': abdominalPerimeter,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass': muscleMass,
      'weight_category': weightCategory?.apiValue,

      // Hipertensión
      'systolic_bp': systolicBP,
      'diastolic_bp': diastolicBP,
      'blood_pressure': bloodPressure,
      'hypertension_risk': hypertensionRisk?.apiValue,
      'hypertension_treatment': hypertensionTreatment?.apiValue,
      'bp_category': bpCategory?.apiValue,
      'is_bp_controlled': isBPControlled,
      'last_bp_measurement': lastBPMeasurement?.toIso8601String(),
      'bp_medications': bpMedications,

      // Diabetes
      'glucose_level': glucoseLevel,
      'hba1c': hba1c,
      'diabetes_level': diabetesLevel?.apiValue,
      'is_diabetes_controlled': isDiabetesControlled,
      'last_glucose_test': lastGlucoseTest?.toIso8601String(),
      'diabetes_medications': diabetesMedications,
      'insulin_type': insulinType,
      'requires_insulin': requiresInsulin,

      // Obesidad/Sobrepeso
      'target_weight': targetWeight,
      'weight_loss_goal': weightLossGoal,
      'weight_loss_start_date': weightLossStartDate?.toIso8601String(),
      'weight_history': weightHistory,
      'last_weight_measurement': lastWeightMeasurement?.toIso8601String(),
      'dietary_restrictions': dietaryRestrictions,

      // Condiciones médicas
      'medical_conditions': medicalConditions.map((e) => e.apiValue).toList(),
      'allergies': allergies,
      'medications': medications,
      'activity_level': activityLevel.apiValue,

      // Objetivos y tratamiento
      'nutritional_goal': nutritionalGoal,
      'dietary_preferences': dietaryPreferences,
      'status': status.apiValue,
      'has_active_plan': hasActivePlan,
      'last_visit_date': lastVisitDate?.toIso8601String(),
      'next_appointment_date': nextAppointmentDate?.toIso8601String(),
      'notes': notes,
      'emergency_contact': emergencyContact,
      'emergency_phone': emergencyPhone,

      //new
      'filiation': filiation?.toJson(),
      'medical_history': medicalHistory?.toJson(),
      'nutritional_profile': nutritionalProfile?.toJson(),
      'risk_factors': riskFactors?.toJson(),

      // Control
      'is_new_patient': isNewPatient,
      'has_nutritional_plan': hasNutritionalPlan,
      'next_appointment': nextAppointment?.toIso8601String(),
      'last_visit': lastVisit?.toIso8601String(),
      'last_visit_time': _timeOfDayToString(lastVisitTime),
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
    List<MedicalCondition>? medicalConditions,
    PatientStatus? status,
    String? notes,
    // Diabetes
    double? glucoseLevel,
    double? hba1c,
    DiabetesLevel? diabetesLevel,
    bool? isDiabetesControlled,
    // Hipertensión
    int? systolicBP,
    int? diastolicBP,
    bool? isBPControlled,
    // Peso
    double? targetWeight,
    WeightCategory? weightCategory,

    TimeOfDay? lastVisitTime,
   //new data
    PatientFiliation? filiation,
    MedicalHistory? medicalHistory,
    NutritionalProfile? nutritionalProfile,
    RiskFactors? riskFactors,

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
      maritalStatus: maritalStatus,
      address: address,
      profileImageUrl: profileImageUrl,

      // Datos físicos
      weight: weight ?? this.weight,
      height: height ?? this.height,
      abdominalPerimeter: abdominalPerimeter,
      bodyFatPercentage: bodyFatPercentage,
      muscleMass: muscleMass,
      weightCategory: weightCategory ?? this.weightCategory,

      // Hipertensión
      systolicBP: systolicBP ?? this.systolicBP,
      diastolicBP: diastolicBP ?? this.diastolicBP,
      bloodPressure: bloodPressure,
      hypertensionRisk: hypertensionRisk,
      hypertensionTreatment: hypertensionTreatment,
      bpCategory: bpCategory,
      isBPControlled: isBPControlled ?? this.isBPControlled,
      lastBPMeasurement: lastBPMeasurement,
      bpMedications: bpMedications,

      // Diabetes
      glucoseLevel: glucoseLevel ?? this.glucoseLevel,
      hba1c: hba1c ?? this.hba1c,
      diabetesLevel: diabetesLevel ?? this.diabetesLevel,
      isDiabetesControlled: isDiabetesControlled ?? this.isDiabetesControlled,
      lastGlucoseTest: lastGlucoseTest,
      diabetesMedications: diabetesMedications,
      insulinType: insulinType,
      requiresInsulin: requiresInsulin,

      // Obesidad/Sobrepeso
      targetWeight: targetWeight ?? this.targetWeight,
      weightLossGoal: weightLossGoal,
      weightLossStartDate: weightLossStartDate,
      weightHistory: weightHistory,
      lastWeightMeasurement: lastWeightMeasurement,
      dietaryRestrictions: dietaryRestrictions,

      // Condiciones médicas
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies,
      medications: medications,
      activityLevel: activityLevel,

      // Objetivos y tratamiento
      nutritionalGoal: nutritionalGoal,
      dietaryPreferences: dietaryPreferences,
      status: status ?? this.status,
      hasActivePlan: hasActivePlan,
      lastVisitDate: lastVisitDate,
      nextAppointmentDate: nextAppointmentDate,
      notes: notes ?? this.notes,
      emergencyContact: emergencyContact,
      emergencyPhone: emergencyPhone,

      //new
      filiation: filiation ?? this.filiation,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      nutritionalProfile: nutritionalProfile ?? this.nutritionalProfile,
      riskFactors: riskFactors ?? this.riskFactors,

      // Control
      isNewPatient: isNewPatient,
      hasNutritionalPlan: hasNutritionalPlan,
      nextAppointment: nextAppointment,
      lastVisit: lastVisit,
      lastVisitTime: lastVisitTime ?? this.lastVisitTime,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}


// 1. DATOS DE FILIACIÓN
class PatientFiliation {
  final String patientId;
  final String? nucleoFamiliar;
  final String? ocupacionActual;
  final String? gradoInstruccion;
  final String? religion;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PatientFiliation({
    required this.patientId,
    this.nucleoFamiliar,
    this.ocupacionActual,
    this.gradoInstruccion,
    this.religion,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientFiliation.fromJson(Map<String, dynamic> json) {
    return PatientFiliation(
      patientId: json['patient_id'] ?? '',
      nucleoFamiliar: json['nucleo_familiar'],
      ocupacionActual: json['ocupacion_actual'],
      gradoInstruccion: json['grado_instruccion'],
      religion: json['religion'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'nucleo_familiar': nucleoFamiliar,
      'ocupacion_actual': ocupacionActual,
      'grado_instruccion': gradoInstruccion,
      'religion': religion,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// 2. ANTECEDENTES MÉDICOS
class MedicalHistory {
  final String patientId;
  final bool? diagnosticoMedicoAnterior;
  final String? tiempoEnfermedad;
  final String? diagnosticoMedicoReciente;
  final bool? antecendentesFamiliares;
  final List<Comorbidity>? comorbilidades;
  final List<String>? familyDiseases;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicalHistory({
    required this.patientId,
    this.diagnosticoMedicoAnterior,
    this.tiempoEnfermedad,
    this.diagnosticoMedicoReciente,
    this.antecendentesFamiliares,
    this.comorbilidades,
    this.familyDiseases,
    this.createdAt,
    this.updatedAt,
  });

  factory MedicalHistory.fromJson(Map<String, dynamic> json) {
    return MedicalHistory(
      patientId: json['patient_id'] ?? '',
      diagnosticoMedicoAnterior: json['diagnostico_medico_anterior'],
      tiempoEnfermedad: json['tiempo_enfermedad'],
      diagnosticoMedicoReciente: json['diagnostico_medico_reciente'],
      antecendentesFamiliares: json['antecendentes_familiares'],
      comorbilidades: json['comorbilidades'] != null
          ? List<String>.from(json['comorbilidades']).map((e) {
        return Comorbidity.values.firstWhere(
              (c) => c.name == e,
          orElse: () => Comorbidity.ninguna,
        );
      }).toList()
          : null,
      familyDiseases: json['family_diseases'] != null
          ? List<String>.from(json['family_diseases'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'diagnostico_medico_anterior': diagnosticoMedicoAnterior,
      'tiempo_enfermedad': tiempoEnfermedad,
      'diagnostico_medico_reciente': diagnosticoMedicoReciente,
      'antecendentes_familiares': antecendentesFamiliares,
      'comorbilidades': comorbilidades?.map((c) => c.name).toList(),
      'family_diseases': familyDiseases,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// 3. DATOS NUTRICIONALES
class NutritionalProfile {
  final String patientId;
  final String? vecesDiaCome;
  final String? preferencias;
  final String? noLeAgrada;
  final String? intolerancias;
  final String? lugarIngesta;
  final String? habitosNocivos;
  final String? tipoActividad;
  final double? consumoAguaLitros; // En litros para mayor precision
  final String? consumoAguaDetalle; // Detalle adicional si necesario
  final List<String>? alimentosPreferidos;
  final List<String>? alimentosEvitar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NutritionalProfile({
    required this.patientId,
    this.vecesDiaCome,
    this.preferencias,
    this.noLeAgrada,
    this.intolerancias,
    this.lugarIngesta,
    this.habitosNocivos,
    this.tipoActividad,
    this.consumoAguaLitros,
    this.consumoAguaDetalle,
    this.alimentosPreferidos,
    this.alimentosEvitar,
    this.createdAt,
    this.updatedAt,
  });

  // Getter para formato de consumo de agua más legible
  String get consumoAguaTexto {
    if (consumoAguaLitros != null && consumoAguaLitros! > 0) {
      return 'Sí (${consumoAguaLitros}L diarios)';
    }
    if ((consumoAguaDetalle ?? '').isNotEmpty) {
      return 'Sí ($consumoAguaDetalle)';
    }
    return 'No';
  }

  bool get consumeAgua => (consumoAguaLitros != null && consumoAguaLitros! > 0) || (consumoAguaDetalle?.isNotEmpty ?? false);

  factory NutritionalProfile.fromJson(Map<String, dynamic> json) {
    return NutritionalProfile(
      patientId: json['patient_id'] ?? '',
      vecesDiaCome: json['veces_dia_come'],
      preferencias: json['preferencias'],
      noLeAgrada: json['no_le_agrada'],
      intolerancias: json['intolerancias'],
      lugarIngesta: json['lugar_ingesta'],
      habitosNocivos: json['habitos_nocivos'],
      tipoActividad: json['tipo_actividad'],
      consumoAguaLitros: json['consumo_agua_litros']?.toDouble(),
      consumoAguaDetalle: json['consumo_agua_detalle'],
      alimentosPreferidos: json['alimentos_preferidos'] != null
          ? List<String>.from(json['alimentos_preferidos'])
          : null,
      alimentosEvitar: json['alimentos_evitar'] != null
          ? List<String>.from(json['alimentos_evitar'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'veces_dia_come': vecesDiaCome,
      'preferencias': preferencias,
      'no_le_agrada': noLeAgrada,
      'intolerancias': intolerancias,
      'lugar_ingesta': lugarIngesta,
      'habitos_nocivos': habitosNocivos,
      'tipo_actividad': tipoActividad,
      'consumo_agua_litros': consumoAguaLitros,
      'consumo_agua_detalle': consumoAguaDetalle,
      'alimentos_preferidos': alimentosPreferidos,
      'alimentos_evitar': alimentosEvitar,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

// 4. FACTORES DE RIESGO
class RiskFactors {
  final String patientId;
  final Gender gender;
  final MedicalCondition medicalCondition;

  final bool? mayor45Anios;
  final bool? obesidad;
  final bool? hipertension;
  final bool? sedentarismo;

  // Factores exclusivos para mujeres
  final bool? hijosMacrosomicos;
  final bool? diabetesGestacional;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RiskFactors({
    required this.patientId,
    required this.gender,
    required this.medicalCondition,
    this.mayor45Anios,
    this.obesidad,
    this.hipertension,
    this.sedentarismo,
    this.hijosMacrosomicos,
    this.diabetesGestacional,
    this.createdAt,
    this.updatedAt,
  });

  /// Verifica si el análisis debe aplicarse (solo para diabéticos)
  bool get aplicaEvaluacion => medicalCondition.isDiabetes;

  /// Cuenta los factores de riesgo válidos según el género y condición
  int get calculatedFactorsCount {
    if (!aplicaEvaluacion) return 0;

    int count = 0;
    if (mayor45Anios == true) count++;
    if (obesidad == true) count++;
    if (hipertension == true) count++;
    if (sedentarismo == true) count++;

    if (gender == Gender.femenino) {
      if (hijosMacrosomicos == true) count++;
      if (diabetesGestacional == true) count++;
    }

    return count;
  }

  RiskLevel get calculatedRiskLevel {
    final count = calculatedFactorsCount;

    if (count >= 5) return RiskLevel.alto;
    if (count >= 3) return RiskLevel.moderado;
    if (count >= 1) return RiskLevel.bajo;
    return RiskLevel.ninguno;
  }

  factory RiskFactors.fromJson(Map<String, dynamic> json) {
    return RiskFactors(
      patientId: json['patient_id'] ?? '',
      gender: json['gender'] != null
          ? Gender.fromApiValue(json['gender'])
          : Gender.masculino,
      medicalCondition: json['medical_condition'] != null
          ? MedicalCondition.fromApiValue(json['medical_condition'])
          : MedicalCondition.ninguna,
      mayor45Anios: json['mayor_45_anios'],
      obesidad: json['obesidad'],
      hipertension: json['hipertension'],
      sedentarismo: json['sedentarismo'],
      hijosMacrosomicos: json['hijos_macrosomicos'],
      diabetesGestacional: json['diabetes_gestacional'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'gender': gender.apiValue,
      'medical_condition': medicalCondition.apiValue,
      'mayor_45_anios': mayor45Anios,
      'obesidad': obesidad,
      'hipertension': hipertension,
      'sedentarismo': sedentarismo,
      'hijos_macrosomicos': hijosMacrosomicos,
      'diabetes_gestacional': diabetesGestacional,
      'factores_count': calculatedFactorsCount,
      'nivel_riesgo': calculatedRiskLevel.apiValue,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class PatientServiceEnhanced extends BaseService {

  final NutritionistNotificationService? notificationService;
  final String authToken;

  PatientServiceEnhanced({required this.authToken, this.notificationService});

  Future<void> acceptNutritionPlan({
    required int planId,
    required String patientId,
    required String nutritionistId,
    required String patientName,
    String? feedback,
  }) async {
    try {
      // Primero llamar al endpoint para aceptar el plan
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviewPlan(planId)}'),
        headers: ApiConstants.getHeaders(authToken),
        body: json.encode({
          'action': 'accept',
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Enviar notificación al nutricionista
        await notificationService?.sendPatientAction(
          patientId: patientId,
          nutritionistId: nutritionistId,
          planId: planId,
          patientName: patientName,
          actionType: 'ACCEPTED',
          reason: feedback,
        );

        print('✅ Plan aceptado y notificación enviada al nutricionista');
      } else {
        throw ApiException(
          'Error al aceptar el plan: ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: ApiConstants.reviewPlan(planId),
        );
      }
    } catch (e) {
      print('❌ Error en acceptNutritionPlan: $e');
      rethrow;
    }
  }

  // Método para rechazar plan nutricional
  Future<void> rejectNutritionPlan({
    required int planId,
    required String patientId,
    required String nutritionistId,
    required String patientName,
    required String reason,
    String? feedback,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviewPlan(planId)}'),
        headers: ApiConstants.getHeaders(authToken),
        body: json.encode({
          'action': 'reject',
          'reason': reason,
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Enviar notificación al nutricionista
        await notificationService?.sendPatientAction(
          patientId: patientId,
          nutritionistId: nutritionistId,
          planId: planId,
          patientName: patientName,
          actionType: 'REJECTED',
          reason: reason,
        );

        print('✅ Plan rechazado y notificación enviada al nutricionista');
      } else {
        throw ApiException(
          'Error al rechazar el plan: ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: ApiConstants.reviewPlan(planId),
        );
      }
    } catch (e) {
      print('❌ Error en rejectNutritionPlan: $e');
      rethrow;
    }
  }

  // Método para solicitar modificaciones al plan
  Future<void> requestPlanModifications({
    required int planId,
    required String patientId,
    required String nutritionistId,
    required String patientName,
    required String modifications,
    String? feedback,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.reviewPlan(planId)}'),
        headers: ApiConstants.getHeaders(authToken),
        body: json.encode({
          'action': 'modify',
          'modifications': modifications,
          'feedback': feedback,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Enviar notificación al nutricionista
        await notificationService?.sendPatientAction(
          patientId: patientId,
          nutritionistId: nutritionistId,
          planId: planId,
          patientName: patientName,
          actionType: 'MODIFIED',
          reason: modifications,
        );

        print('✅ Modificaciones solicitadas y notificación enviada al nutricionista');
      } else {
        throw ApiException(
          'Error al solicitar modificaciones: ${response.statusCode}',
          statusCode: response.statusCode,
          endpoint: ApiConstants.reviewPlan(planId),
        );
      }
    } catch (e) {
      print('❌ Error en requestPlanModifications: $e');
      rethrow;
    }
  }

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

  // OBTENER PACIENTES CON DIABETES
  Future<List<Patient>> getHipertencionPatients() async {
    const endpoint = ApiConfig.hipertionPatients;
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

  // ========== NUEVOS MÉTODOS ESPECÍFICOS PARA HIPERTENSIÓN ==========

  /// Obtiene todos los pacientes con hipertensión
  Future<List<Patient>> getHypertensionPatients() async {
    return await getPatientsByMedicalCondition(MedicalCondition.hipertension);
  }

  /// Obtiene pacientes con hipertensión filtrados por nivel de riesgo
  Future<List<Patient>> getHypertensionPatientsByRisk(HypertensionRisk risk) async {
    const endpoint = ApiConfig.hypertensionPatientsByRisk;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {'risk_level': risk.apiValue},
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con hipertensión controlada
  Future<List<Patient>> getControlledHypertensionPatients() async {
    const endpoint = ApiConfig.controlledHypertensionPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con hipertensión descontrolada
  Future<List<Patient>> getUncontrolledHypertensionPatients() async {
    const endpoint = ApiConfig.uncontrolledHypertensionPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con hipertensión que requieren atención urgente
  Future<List<Patient>> getUrgentHypertensionPatients() async {
    const endpoint = ApiConfig.urgentHypertensionPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con crisis hipertensiva (presión >= 180/110)
  Future<List<Patient>> getHypertensiveCrisisPatients() async {
    const endpoint = ApiConfig.hypertensiveCrisisPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes por tipo de tratamiento de hipertensión
  Future<List<Patient>> getHypertensionPatientsByTreatment(HypertensionTreatment treatment) async {
    const endpoint = ApiConfig.hypertensionPatientsByTreatment;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {'treatment': treatment.apiValue},
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con nuevas mediciones de presión arterial
  Future<List<Patient>> getNewHypertensionPatients() async {
    const endpoint = ApiConfig.newHypertensionPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con hipertensión que requieren seguimiento
  Future<List<Patient>> getHypertensionFollowUpPatients() async {
    const endpoint = ApiConfig.hypertensionFollowUpPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // ========== MÉTODOS DE ACTUALIZACIÓN DE PRESIÓN ARTERIAL ==========

  /// Actualiza la presión arterial de un paciente
  Future<Patient> updateBloodPressure(String patientId, int systolic, int diastolic, {
    DateTime? measurementDate,
    String? notes,
  }) async {
    const endpoint = ApiConfig.updateBloodPressure;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint/$patientId');

    final body = {
      'systolic_bp': systolic,
      'diastolic_bp': diastolic,
      'blood_pressure': '$systolic/$diastolic',
      'measurement_date': measurementDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'notes': notes,
    };

    return handleRequest(
          () => _client.patch(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(body),
      ).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: '$endpoint/$patientId',
    );
  }

  /// Actualiza el estado de control de hipertensión
  Future<Patient> updateHypertensionControl(String patientId, bool isControlled, {
    HypertensionTreatment? treatment,
    List<String>? medications,
    String? notes,
  }) async {
    const endpoint = ApiConfig.updateHypertensionControl;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint/$patientId');

    final body = <String, dynamic>{
      'is_controlled': isControlled,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (treatment != null) {
      body['hypertension_treatment'] = treatment.apiValue;
    }
    if (medications != null) {
      body['bp_medications'] = medications;
    }
    if (notes != null) {
      body['notes'] = notes;
    }

    return handleRequest(
          () => _client.patch(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(body),
      ).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: '$endpoint/$patientId',
    );
  }

  // ========== MÉTODOS DE ESTADÍSTICAS ==========

  /// Obtiene estadísticas generales de hipertensión
  Future<Map<String, dynamic>> getHypertensionStats() async {
    const endpoint = ApiConfig.hypertensionStats;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint');

    return handleRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
          (json) => json as Map<String, dynamic>,
      endpoint: endpoint,
    );
  }

  /// Obtiene estadísticas por rango de edad
  Future<Map<String, dynamic>> getHypertensionStatsByAgeRange(int minAge, int maxAge) async {
    const endpoint = ApiConfig.hypertensionStatsByAge;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {
        'min_age': minAge.toString(),
        'max_age': maxAge.toString(),
      },
    );

    return handleRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
          (json) => json as Map<String, dynamic>,
      endpoint: endpoint,
    );
  }

  /// Obtiene el historial de presión arterial de un paciente
  Future<List<Map<String, dynamic>>> getBloodPressureHistory(String patientId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    const endpoint = ApiConfig.bloodPressureHistory;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);

    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl$endpoint/$patientId').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
          (json) => json as Map<String, dynamic>,
      endpoint: '$endpoint/$patientId',
    );
  }

  // ========== MÉTODOS DE BÚSQUEDA Y FILTRADO ==========

  /// Busca pacientes con hipertensión por nombre o DNI
  Future<List<Patient>> searchHypertensionPatients(String query) async {
    const endpoint = ApiConfig.searchHypertensionPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: {'q': query},
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  /// Obtiene pacientes con hipertensión filtrados por múltiples criterios
  Future<List<Patient>> getFilteredHypertensionPatients({
    HypertensionRisk? riskLevel,
    HypertensionTreatment? treatment,
    bool? isControlled,
    bool? hasNutritionalPlan,
    int? minAge,
    int? maxAge,
    Gender? gender,
  }) async {
    const endpoint = ApiConfig.filteredHypertensionPatients;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);

    final queryParams = <String, String>{};
    if (riskLevel != null) queryParams['risk_level'] = riskLevel.apiValue;
    if (treatment != null) queryParams['treatment'] = treatment.apiValue;
    if (isControlled != null) queryParams['is_controlled'] = isControlled.toString();
    if (hasNutritionalPlan != null) queryParams['has_nutritional_plan'] = hasNutritionalPlan.toString();
    if (minAge != null) queryParams['min_age'] = minAge.toString();
    if (maxAge != null) queryParams['max_age'] = maxAge.toString();
    if (gender != null) queryParams['gender'] = gender.apiValue;

    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return handleListRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
      Patient.fromJson,
      endpoint: endpoint,
    );
  }

  // ========== MÉTODOS DE REPORTES ==========

  /// Genera reporte de pacientes con hipertensión
  Future<Map<String, dynamic>> generateHypertensionReport({
    DateTime? startDate,
    DateTime? endDate,
    String? reportType, // 'summary', 'detailed', 'statistics'
  }) async {
    const endpoint = ApiConfig.hypertensionReport;
    final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);

    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (reportType != null) queryParams['type'] = reportType;

    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return handleRequest(
          () => _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout),
          (json) => json as Map<String, dynamic>,
      endpoint: endpoint,
    );
  }

  void dispose() {
    _client.close();
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
class AppointmentServiceEnhanced extends BaseService {

  // OBTENER TODAS LAS CITAS Y FILTRAR POR FECHA
  Future<List<AppointmentEnhanced>> getAppointmentsByDate(DateTime date) async {
    try {
      // Primero obtener todas las citas
      final allAppointments = await getAllAppointments();

      // Filtrar por fecha en el cliente
      final targetDate = DateTime(date.year, date.month, date.day);

      return allAppointments.where((appointment) {
        final appointmentDate = DateTime(
          appointment.scheduledDate.year,
          appointment.scheduledDate.month,
          appointment.scheduledDate.day,
        );
        return appointmentDate.isAtSameMomentAs(targetDate);
      }).toList();

    } catch (e) {
      Logger.warning('Error loading appointments for ${date.toIso8601String()}: $e');
      return []; // Retornar lista vacía en lugar de throw para que la UI no se rompa
    }
  }

  // OBTENER CITAS DE HOY
  Future<List<AppointmentEnhanced>> getTodayAppointments() async {
    return getAppointmentsByDate(DateTime.now());
  }

  // OBTENER CITAS SEMANALES - OPTIMIZADO
  Future<List<AppointmentEnhanced>> getWeeklyAppointments([DateTime? referenceDate]) async {
    try {
      final today = referenceDate ?? DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1)); // Lunes
      final endOfWeek = startOfWeek.add(Duration(days: 6)); // Domingo

      // Obtener todas las citas una sola vez
      final allAppointments = await getAllAppointments();

      // Filtrar por rango de semana
      final weeklyAppointments = allAppointments.where((appointment) {
        final appointmentDate = DateTime(
          appointment.scheduledDate.year,
          appointment.scheduledDate.month,
          appointment.scheduledDate.day,
        );

        return appointmentDate.isAfter(startOfWeek.subtract(Duration(days: 1))) &&
            appointmentDate.isBefore(endOfWeek.add(Duration(days: 1)));
      }).toList();

      // Ordenar por fecha y hora
      weeklyAppointments.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

      return weeklyAppointments;

    } catch (e) {
      Logger.warning('Error loading weekly appointments: $e');
      return [];
    }
  }

  // OBTENER CITAS URGENTES - FILTRAR EN EL CLIENTE
  Future<List<AppointmentEnhanced>> getUrgentAppointments() async {
    try {
      final allAppointments = await getAllAppointments();
      return allAppointments.where((appointment) =>
      appointment.priority == AppointmentPriority.urgente
      ).toList();
    } catch (e) {
      Logger.warning('Error loading urgent appointments: $e');
      return [];
    }
  }

  // AGENDAR NUEVA CITA - CORREGIDO PARA MOCKAPI
  Future<AppointmentEnhanced> scheduleAppointment({
    required String patientId,
    required DateTime scheduledDate,
    required AppointmentType type,
    AppointmentPriority priority = AppointmentPriority.normal,
    int durationMinutes = 60,
    String? reason,
    String? notes,
  }) async {
    try {
      const endpoint = ApiConfig.appointments;
      final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
      final uri = Uri.parse('$baseUrl$endpoint');

      final appointment = AppointmentEnhanced(
        id: '', // MockAPI generará el ID
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

      final response = await _client.post(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(appointment.toJson()),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // MockAPI devuelve el objeto creado directamente
        final Map<String, dynamic> data = json.decode(response.body);
        return AppointmentEnhanced.fromJson(data);
      } else {
        throw ApiException('Failed to create appointment: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error creating appointment: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  // REAGENDAR CITA - CORREGIDO PARA MOCKAPI
  Future<AppointmentEnhanced> rescheduleAppointment(
      String appointmentId,
      DateTime newDateTime,
      ) async {
    try {
      const endpoint = ApiConfig.appointments;
      final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
      final uri = Uri.parse('$baseUrl$endpoint/$appointmentId');

      final updateData = {
        'scheduled_date': newDateTime.toIso8601String(),
        'status': AppointmentStatus.reprogramada.apiValue,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.put(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(updateData),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // MockAPI devuelve el objeto actualizado directamente
        final Map<String, dynamic> data = json.decode(response.body);
        return AppointmentEnhanced.fromJson(data);
      } else {
        throw ApiException('Failed to reschedule appointment: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error rescheduling appointment $appointmentId: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e at /appointments/$appointmentId');
    }
  }

  // OBTENER TODAS LAS CITAS - CORREGIDO PARA MOCKAPI
  Future<List<AppointmentEnhanced>> getAllAppointments() async {
    try {
      const endpoint = ApiConfig.appointments;
      final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
      final uri = Uri.parse('$baseUrl$endpoint');

      Logger.info('Fetching all appointments from: $uri');

      final response = await _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // ✅ CORRECTO - MockAPI devuelve una lista/array
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => AppointmentEnhanced.fromJson(json)).toList();
      } else {
        throw ApiException('Request failed with status ${response.statusCode} at $endpoint');
      }
    } catch (e) {
      Logger.error('Error loading appointments: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e ');
    }
  }

  // OBTENER UNA CITA POR ID - CORREGIDO PARA MOCKAPI
  Future<AppointmentEnhanced> getAppointmentById(String id) async {
    try {
      const endpoint = ApiConfig.appointments;
      final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
      final uri = Uri.parse('$baseUrl$endpoint/$id');

      final response = await _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // Para un ID específico, MockAPI devuelve un objeto individual
        final Map<String, dynamic> data = json.decode(response.body);
        return AppointmentEnhanced.fromJson(data);
      } else {
        throw ApiException('Appointment not found with ID: $id');
      }
    } catch (e) {
      Logger.error('Error loading appointment $id: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e at /appointments/$id');
    }
  }

  // CANCELAR CITA - CORREGIDO PARA MOCKAPI
  Future<AppointmentEnhanced> cancelAppointment(String appointmentId, String reason) async {
    try {
      const endpoint = ApiConfig.appointments;
      final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
      final uri = Uri.parse('$baseUrl$endpoint/$appointmentId');

      final updateData = {
        'status': AppointmentStatus.cancelada.apiValue,
        'notes': reason,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client.put(
        uri,
        headers: ApiConfig.headers,
        body: json.encode(updateData),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        // MockAPI devuelve el objeto actualizado directamente
        final Map<String, dynamic> data = json.decode(response.body);
        return AppointmentEnhanced.fromJson(data);
      } else {
        throw ApiException('Failed to cancel appointment: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error canceling appointment $appointmentId: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e at /appointments/$appointmentId');
    }
  }

  // MÉTODO HELPER PARA DEBUGGING
  Future<void> testConnection() async {
    try {
      const endpoint = ApiConfig.appointments;
      final baseUrl = ApiConfig.getBaseUrlForEndpoint(endpoint);
      final uri = Uri.parse('$baseUrl$endpoint');

      print('Testing connection to: $uri');

      final response = await _client.get(uri, headers: ApiConfig.headers).timeout(ApiConfig.timeout);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response type: ${response.body.runtimeType}');

      // Verificar si es una lista
      final decoded = json.decode(response.body);
      print('Decoded type: ${decoded.runtimeType}');

    } catch (e) {
      print('Connection test failed: $e');
    }
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
  static const String prodBaseUrl = 'https://www.mottinnut.com/api/v1';

  // URLs de MockAPI para desarrollo
  static const String devBaseUrl = 'https://684685267dbda7ee7aaf4e65.mockapi.io';
  static const String devBaseUrl1 = 'https://mottinutv1.free.beeceptor.com';
  static const String devBaseUrl2 = 'https://684685267dbda7ee7aaf4e65.mockapi.io';

  static bool isProduction = const bool.fromEnvironment('dart.vm.product');

  // Método para obtener la URL base según el endpoint
  static String getBaseUrlForEndpoint(String endpoint) {
    if (isProduction) return prodBaseUrl;

    // Distribución de endpoints por perfil
    switch (endpoint) {
    // Perfil principal - CORREGIDO para MockAPI
      case '/patients':
      case '/nutrition-plans':
      case '/appointments': // Endpoint básico de MockAPI
      case '/nutrition-plans/generate':
      case '/auth':
        return devBaseUrl;

    // Perfil 1
      case '/patients/by-condition':
      case '/patients/diabetic':
      case '/patients/overweight':
      case '/patients/active':
        return devBaseUrl1;

    // Perfil 2
      case '/patients/urgent':
      case '/dashboard':
      case '/sample-plans':
        return devBaseUrl2;

      default:
        return devBaseUrl;
    }
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static String? authToken;

  static void setAuthToken(String? token) {
    authToken = token;
  }

  static const Duration timeout = Duration(seconds: 30);
  static const Duration aiTimeout = Duration(minutes: 3);

  // Endpoints - CORREGIDOS para MockAPI
  static const String patients = '/patients';
  static const String nutritionPlans = '/nutrition-plans';
  static const String appointments = '/appointments';
  static const String generatePlan = '/nutrition-plans/generate';
  static const String auth = '/auth';
  // IMPORTANTE: MockAPI no soporta sub-rutas, usar solo /appointments con filtros
  static const String appointmentsByDate = '/appointments'; // Sin /by-date
  static const String urgentAppointments = '/appointments'; // Sin /urgent
  static const String rescheduleAppointment = '/appointments'; // Sin sub-ruta
  static const String patientsByCondition = '/patients/by-condition';
  static const String diabeticPatients = '/patients/diabetic';
  static const String hipertionPatients = '/patients/hipertention';
  static const String overweightPatients = '/patients/overweight';
  static const String urgentPatients = '/patients/urgent';
  static const String activePatients = '/patients/active';
  static const String dashboard = '/dashboard';
  static const String samplePlans = '/sample-plans';

  // ========== ENDPOINTS PARA HIPERTENSIÓN ==========

  // Endpoints básicos de hipertensión
  static const String hypertensionPatientsByRisk = '/api/v1/patients/hypertension/by-risk';
  static const String controlledHypertensionPatients = '/api/v1/patients/hypertension/controlled';
  static const String uncontrolledHypertensionPatients = '/api/v1/patients/hypertension/uncontrolled';
  static const String urgentHypertensionPatients = '/api/v1/patients/hypertension/urgent';
  static const String hypertensiveCrisisPatients = '/api/v1/patients/hypertension/crisis';
  static const String hypertensionPatientsByTreatment = '/api/v1/patients/hypertension/by-treatment';
  static const String newHypertensionPatients = '/api/v1/patients/hypertension/new';
  static const String hypertensionFollowUpPatients = '/api/v1/patients/hypertension/follow-up';

  // Endpoints de actualización
  static const String updateBloodPressure = '/api/v1/patients/blood-pressure';
  static const String updateHypertensionControl = '/api/v1/patients/hypertension/control';

  // Endpoints de estadísticas
  static const String hypertensionStats = '/api/v1/analytics/hypertension/stats';
  static const String hypertensionStatsByAge = '/api/v1/analytics/hypertension/stats-by-age';
  static const String bloodPressureHistory = '/api/v1/patients/blood-pressure/history';

  // Endpoints de búsqueda y filtrado
  static const String searchHypertensionPatients = '/api/v1/patients/hypertension/search';
  static const String filteredHypertensionPatients = '/api/v1/patients/hypertension/filtered';

  // Endpoints de reportes
  static const String hypertensionReport = '/api/v1/reports/hypertension';

  // Endpoints de citas
  static const String scheduleHypertensionAppointment = '/api/v1/appointments/hypertension';
  static const String upcomingHypertensionAppointments = '/api/v1/appointments/hypertension/upcoming';

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
