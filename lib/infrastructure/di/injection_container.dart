/*import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../repositories/auth_repository_impl.dart';
import '../services/auth_service_impl.dart';
import '../services/encryption_service_impl.dart';
import '../services/biometric_service_impl.dart';
import '../datasources/remote_auth_datasource.dart';
import '../datasources/local_auth_datasource.dart';
import '../config/api_config.dart';
import '../../application/auth/registration/registration_bloc.dart';


final GetIt sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Bloc
  /*sl.registerFactory(
        () => RegistrationBloc(
      authService: sl(),
      authRepository: sl(),
    ),
  );

  sl.registerFactory(
        () => LoginBloc(
      authService: sl(),
    ),
  );

  // Use cases / Services
  sl.registerLazySingleton<AuthService>(
        () => AuthServiceImpl(
      authRepository: sl(),
      biometricService: sl(),
    ),
  );

  sl.registerLazySingleton<EncryptionService>(
        () => EncryptionServiceImpl(),
  );

  sl.registerLazySingleton<BiometricService>(
        () => BiometricServiceImpl(
      localAuth: sl(),
      localDataSource: sl(),
    ),
  );
*/
  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      encryptionService: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<RemoteAuthDataSource>(
        () => RemoteAuthDataSourceImpl(
      dio: sl(),
      baseUrl: ApiConfig.fullBaseUrl,
    ),
  );

  sl.registerLazySingleton<LocalAuthDataSource>(
        () => LocalAuthDataSourceImpl(
      prefs: sl(),
      secureStorage: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => LocalAuthentication());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}*/