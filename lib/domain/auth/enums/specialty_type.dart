
enum SpecialtyType {
  nutricionista('Nutricionista'),
  dietista('Dietista'),
  nutricionDeportiva('Nutrición Deportiva'),
  nutricionClinica('Nutrición Clínica'),
  nutricionPediatrica('Nutrición Pediátrica'),
  other('Otro');

  const SpecialtyType(this.displayName);
  final String displayName;

  static SpecialtyType fromString(String value) {
    return SpecialtyType.values.firstWhere(
          (type) => type.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => SpecialtyType.other,
    );
  }
}