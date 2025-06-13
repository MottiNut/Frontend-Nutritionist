abstract class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
  Future<void> saveBiometricAuth(String email, String password);
  Future<Map<String, String>?> getBiometricAuth();
  Future<void> deleteBiometricAuth();
}