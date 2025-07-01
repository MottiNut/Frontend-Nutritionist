
// Enums para validacion de foto perfil
enum ValidationStatus {
  pending,
  success,
  failed,
}

class ValidationStep {
  final String title;
  final ValidationStatus status;

  ValidationStep(this.title, this.status);
}
