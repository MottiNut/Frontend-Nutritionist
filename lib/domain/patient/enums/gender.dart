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
  intenso('Actividad Intensa', 'intense', 1.725);

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

enum PatientStatus {
  nuevo('Nuevo', 'new'),
  activo('Activo', 'active'),
  enTratamiento('En Tratamiento', 'in_treatment'),
  controlado('Controlado', 'controlled'),
  inactivo('Inactivo', 'inactive');

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

enum DiabetesType {
  ninguna('Sin Diabetes', 'none'),
  tipo1('Diabetes Tipo 1', 'type1'),
  tipo2('Diabetes Tipo 2', 'type2');

  const DiabetesType(this.displayName, this.apiValue);
  final String displayName;
  final String apiValue;

  static DiabetesType fromApiValue(String apiValue) {
    return DiabetesType.values.firstWhere(
          (e) => e.apiValue == apiValue,
      orElse: () => DiabetesType.ninguna,
    );
  }
}

enum MealType {
  desayuno('Desayuno', 'breakfast'),
  almuerzo('Almuerzo', 'lunch'),
  cena('Cena', 'dinner'),
  colacion('Colación', 'snack');

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
  completado('Completado', 'completed');

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
