import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:mottinutnutriotinist/configuration/providers/fontsize_app_screen.dart';
import 'package:provider/provider.dart';
import 'configuration/providers/app_theme_provider.dart';
import 'configuration/providers/speed_test_config.dart';
import 'configuration/routes/mottinut_nutriotinist_app_screen.dart';
import 'configuration/providers/color_dar_light_app.dart';
import 'application/auth/registration/registration_bloc.dart';
import 'domain/patient/app_state.dart';
import 'domain/patient/pruebaa.dart';
import 'domain/usecases/register_user_usecase.dart';
import 'data/auth/repositories/auth_repository_impl.dart' as repo_impl;
import 'data/auth/datasources/auth_remote_datasource.dart' as datasource;


void main() async {
  // Configurar logging para development
  Logger.setLevel(LogLevel.debug);

  runApp(
      MultiBlocProvider(
        providers: [
          // Providers existentes
          ChangeNotifierProvider(create: (context) => DarkModeProvider()),
          ChangeNotifierProvider(create: (context) => FontSizeProvider()),
          ChangeNotifierProvider(create: (context) => NetworkProvider()),
          ChangeNotifierProvider(create: (context) => AppThemeProvider()),
          ChangeNotifierProvider(create: (context) => AppState()),

          // RegistrationBloc con sus dependencias correctas
          BlocProvider<RegistrationBloc>(
            create: (context) {
              // Crear el cliente HTTP
              final httpClient = http.Client();

              // Crear el data source con el cliente
              final authDataSource = datasource.AuthRemoteDataSourceImpl(
                client: httpClient,
              );

              // Crear el repository con el data source
              final authRepository = repo_impl.AuthRepositoryImpl(
                remoteDataSource: authDataSource,
              );

              // Crear el use case con el repository
              final registerUserUseCase = RegisterUserUseCase(authRepository);

              return RegistrationBloc(
                registerUserUseCase: registerUserUseCase,
                authRepository: authRepository,
              );
            },
          ),
        ],
        child: MottiNutNutriotinistApp(),
      )
  );
}

