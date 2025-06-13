import 'dart:io';
import '../entities/user_entity.dart';
import '../models/auth_result.dart';
import '../models/sign_up_data.dart';

abstract class AuthRepository {
  Future<AuthResult> signUp(SignUpData data);
  Future<AuthResult> signIn(String email, String password);
  Future<AuthResult> signInWithBiometrics();
  Future<AuthResult> refreshToken(String refreshToken);
  Future<void> signOut();
  Future<bool> sendVerificationCode(String email);
  Future<bool> verifyEmail(String email, String code);
  Future<bool> resetPassword(String email);
  Future<bool> changePassword(String email, String oldPassword, String newPassword);
  Future<bool> checkEmailExists(String email);
  Future<bool> verifyCNPCode(String cnpCode);
  Future<UserEntity?> getCurrentUser();
  Future<bool> updateProfile(UserEntity user);
}
