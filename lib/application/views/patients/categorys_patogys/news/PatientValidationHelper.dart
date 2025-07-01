import 'package:flutter/material.dart';
import '../../../../../domain/patient/new/rutadirectaaa/muestraaa.dart';

/// Helper class para validaciones relacionadas con el historial médico del paciente
class PatientValidationHelper {

  static bool hasCompleteHistory(PatientWithHistory? patientWithHistory) {
    return patientWithHistory != null &&
        patientWithHistory.medicalHistories.isNotEmpty;
  }

  /// Obtiene el historial médico más reciente del paciente
  static MedicalHistory? getLatestHistory(PatientWithHistory? patientWithHistory) {
    if (patientWithHistory == null || patientWithHistory.medicalHistories.isEmpty) {
      return null;
    }
    return patientWithHistory.latestHistory ?? patientWithHistory.medicalHistories.first;
  }

  /// Verifica si el historial médico está completo (al menos un registro)
  static bool isHistoryComplete(PatientWithHistory? patientWithHistory) {
    return patientWithHistory != null &&
        patientWithHistory.medicalHistories.isNotEmpty;
  }

  /// Obtiene la lista de campos faltantes en el historial médico más reciente
  static List<String> getMissingFields(PatientWithHistory? patientWithHistory) {
    final latestHistory = getLatestHistory(patientWithHistory);
    if (latestHistory == null) return [];

    List<String> missing = [];
    if (latestHistory.bloodGlucose == null) missing.add('Glucosa en sangre');
    if (latestHistory.bloodPressure == null) missing.add('Presión arterial');
    if (latestHistory.bodyFatPercentage == null) missing.add('Porcentaje de grasa corporal');
    if (latestHistory.eatingHabits == null || latestHistory.eatingHabits!.isEmpty) {
      missing.add('Hábitos alimentarios');
    }
    if (latestHistory.nutritionalObjectives == null || latestHistory.nutritionalObjectives!.isEmpty) {
      missing.add('Objetivos nutricionales');
    }

    return missing;
  }

  /// Verifica si es un paciente nuevo (sin ID válido)
  static bool isNewPatient(PatientProfile patient) {
    return patient.patientId <= 0;
  }

  /// Calcula el requerimiento energético basado en los datos del paciente
  static int calculateEnergyRequirement(PatientProfile patient) {
    // Usar datos disponibles o valores estimados
    final weight = patient.weight ?? 70.0; // Peso promedio si no está disponible
    final height = patient.height ?? 170.0; // Altura promedio si no está disponible
    final age = patient.age ?? 30; // Edad promedio si no está disponible

    double bmr;
    final gender = patient.gender?.toLowerCase() ?? 'female';

    if (gender == 'male' || gender == 'masculino' || gender == 'm') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    // Factor de actividad moderado por defecto
    final activityFactor = 1.375;

    return (bmr * activityFactor).round();
  }

  /// Prepara la descripción de objetivos nutricionales
  static String prepareGoalDescription(PatientProfile patient, PatientWithHistory? patientWithHistory) {
    final latestHistory = getLatestHistory(patientWithHistory);
    final objectives = latestHistory?.nutritionalObjectives;

    String goal = 'Mejorar el estado nutricional general';

    // Agregar información sobre condición crónica si existe
    if (patient.chronicDisease != null && patient.chronicDisease!.isNotEmpty) {
      final disease = patient.chronicDisease!.toLowerCase();
      if (disease.contains('diabetes')) {
        goal += ' y controlar diabetes mediante manejo nutricional adecuado';
      } else if (disease.contains('hipertensión') || disease.contains('hipertension')) {
        goal += ' y controlar hipertensión mediante dieta baja en sodio';
      } else {
        goal += ' y manejar ${patient.chronicDisease}';
      }
    }

    // Agregar objetivos específicos si existen
    if (objectives != null && objectives.isNotEmpty) {
      goal += '. Objetivos específicos: $objectives';
    }

    return goal;
  }

  /// Prepara los requisitos especiales para el plan nutricional
  static String prepareSpecialRequirements(PatientProfile patient, PatientWithHistory? patientWithHistory) {
    List<String> requirements = [];

    // Información básica del paciente
    requirements.add('Paciente: ${patient.fullName}');

    if (patient.age != null) {
      requirements.add('Edad: ${patient.age} años');
    }

    if (patient.gender != null && patient.gender!.isNotEmpty) {
      requirements.add('Género: ${patient.gender}');
    }

    // Alergias alimentarias
    if (patient.allergies != null && patient.allergies!.isNotEmpty) {
      requirements.add('ALERGIAS IMPORTANTES: ${patient.allergies}');
    }

    // Preferencias dietéticas
    if (patient.dietaryPreferences != null && patient.dietaryPreferences!.isNotEmpty) {
      requirements.add('Preferencias dietéticas: ${patient.dietaryPreferences}');
    }

    // Información del historial médico si está disponible
    final latestHistory = getLatestHistory(patientWithHistory);
    if (latestHistory != null) {
      if (latestHistory.bloodGlucose != null) {
        requirements.add('Glucosa en sangre: ${latestHistory.bloodGlucose} mg/dL');
      }
      if (latestHistory.bloodPressure != null && latestHistory.bloodPressure!.isNotEmpty) {
        requirements.add('Presión arterial: ${latestHistory.bloodPressure}');
      }
      if (latestHistory.eatingHabits != null && latestHistory.eatingHabits!.isNotEmpty) {
        requirements.add('Hábitos alimentarios actuales: ${latestHistory.eatingHabits}');
      }
      if (latestHistory.bodyFatPercentage != null) {
        requirements.add('Porcentaje de grasa corporal: ${latestHistory.bodyFatPercentage}%');
      }
    }

    // Si no hay información específica, agregar requisitos generales
    if (requirements.length <= 3) {
      requirements.add('Plan nutricional equilibrado y variado');
      requirements.add('Considerar horarios de comida regulares');
    }

    return requirements.join('. ');
  }

  /// Obtiene el tipo de diabetes del paciente
  static String getDiabetesType(String? chronicDisease) {
    if (chronicDisease == null) return 'Sin especificar';
    final disease = chronicDisease.toLowerCase();
    if (disease.contains('tipo 1') || disease.contains('type 1')) return 'Diabetes Tipo 1';
    if (disease.contains('tipo 2') || disease.contains('type 2')) return 'Diabetes Tipo 2';
    return 'Diabetes';
  }

  /// Obtiene el color de estado basado en el IMC
  static Color getStatusColor(PatientProfile patient) {
    if (patient.bmi == null) return Colors.grey;
    if (patient.bmi! < 18.5) return Colors.blue;
    if (patient.bmi! < 25) return Colors.green;
    if (patient.bmi! < 30) return Colors.orange;
    return Colors.red;
  }

  /// Obtiene el texto de estado basado en el IMC
  static String getStatusText(PatientProfile patient) {
    if (patient.bmi == null) return 'Sin datos';
    if (patient.bmi! < 18.5) return 'Bajo peso';
    if (patient.bmi! < 25) return 'Controlado';
    if (patient.bmi! < 30) return 'Atención';
    return 'Crítico';
  }
}