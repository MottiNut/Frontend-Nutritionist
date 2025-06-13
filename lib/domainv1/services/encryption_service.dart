abstract class EncryptionService {
  String hashPassword(String password);
  bool verifyPassword(String password, String hashedPassword);
  String generateSecureToken();
  String generateVerificationCode();
  String encrypt(String data);
  String decrypt(String encryptedData);
}