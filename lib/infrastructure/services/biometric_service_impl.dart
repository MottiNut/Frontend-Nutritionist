/*

import '../../domainv1/services/biometric_service.dart';

class BiometricServiceImpl implements BiometricService {
  final LocalAuthentication _localAuth;
  final LocalAuthDataSource _localDataSource;

  BiometricServiceImpl({
    required LocalAuthentication localAuth,
    required LocalAuthDataSource localDataSource,
  })  : _localAuth = localAuth,
        _localDataSource = localDataSource;

  @override
  Future<bool> isAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> saveBiometricAuth(String email, String password) async {
    await _localDataSource.saveBiometricData(email, password);
  }

  @override
  Future<Map<String, String>?> getBiometricAuth() async {
    return await _localDataSource.getBiometricData();
  }

  @override
  Future<void> deleteBiometricAuth() async {
    await _localDataSource.clearBiometricData();
  }
}*/