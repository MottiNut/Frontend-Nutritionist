import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import '../../domainv1/services/encryption_service.dart';


class EncryptionServiceImpl implements EncryptionService {
  @override
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }

  @override
  String generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  @override
  String generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  @override
  String encrypt(String data) {
    // Implementar encriptación según tus necesidades
    return base64.encode(utf8.encode(data));
  }

  @override
  String decrypt(String encryptedData) {
    // Implementar desencriptación según tus necesidades
    return utf8.decode(base64.decode(encryptedData));
  }
}