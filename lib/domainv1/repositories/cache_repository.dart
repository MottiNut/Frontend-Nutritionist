import '../entities/auth_token_entity.dart';
import '../entities/user_entity.dart';

abstract class CacheRepository {
  Future<void> saveToken(AuthTokenEntity token);
  Future<AuthTokenEntity?> getToken();
  Future<void> clearToken();
  Future<void> saveUser(UserEntity user);
  Future<UserEntity?> getUser();
  Future<void> clearUser();
  Future<void> saveBiometricData(String email, String hashedPassword);
  Future<Map<String, String>?> getBiometricData();
  Future<void> clearBiometricData();
  Future<void> saveRememberMe(bool remember);
  Future<bool> getRememberMe();
  Future<void> clearAll();
}
