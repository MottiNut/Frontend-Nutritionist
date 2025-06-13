import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domainv1/services/auth_service.dart';
import 'login_event.dart';
import 'login_status.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService _authService;
  final AuthRepository _authRepository;

  LoginBloc({
    required AuthService authService,
    required AuthRepository authRepository,
  })  : _authService = authService,
        _authRepository = authRepository,
        super(const LoginState()) {
    on<LoginEmailChanged>(_onLoginEmailChanged);
    on<LoginPasswordChanged>(_onLoginPasswordChanged);
    //on<LoginSubmitted>(_onLoginSubmitted);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    //on<LoginWithFacebookRequested>(_onLoginWithFacebookRequested);
    //on<LogoutRequested>(_onLogoutRequested);
    //on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<PasswordVisibilityToggled>(_onPasswordVisibilityToggled);
    on<LoginStatusReset>(_onLoginStatusReset);
  }

  void _onLoginEmailChanged(
      LoginEmailChanged event,
      Emitter<LoginState> emit,
      ) {
    final isEmailValid = _validateEmail(event.email);
    final isFormValid = isEmailValid && state.isPasswordValid;

    emit(state.copyWith(
      email: event.email,
      isEmailValid: isEmailValid,
      isFormValid: isFormValid,
      errorMessage: null,
    ));
  }

  void _onLoginPasswordChanged(
      LoginPasswordChanged event,
      Emitter<LoginState> emit,
      ) {
    final isPasswordValid = _validatePassword(event.password);
    final isFormValid = state.isEmailValid && isPasswordValid;

    emit(state.copyWith(
      password: event.password,
      isPasswordValid: isPasswordValid,
      isFormValid: isFormValid,
      errorMessage: null,
    ));
  }

  /*Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    if (!state.isFormValid) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Por favor, complete todos los campos correctamente',
      ));
      return;
    }

    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _authService.login(
        email: state.email,
        password: state.password,
      );

      if (result.isSuccess) {
        emit(state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: result.errorMessage ?? 'Error al iniciar sesión',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Error inesperado: ${e.toString()}',
      ));
    }
  }*/

  Future<void> _onLoginWithGoogleRequested(
      LoginWithGoogleRequested event,
      Emitter<LoginState> emit,
      ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _authService.signInWithGoogle();

      if (result.isSuccess) {
        emit(state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: result.errorMessage ?? 'Error al iniciar sesión con Google',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Error al iniciar sesión con Google: ${e.toString()}',
      ));
    }
  }

  /*Future<void> _onLoginWithFacebookRequested(
      LoginWithFacebookRequested event,
      Emitter<LoginState> emit,
      ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _authService.signInWithFacebook();

      if (result.isSuccess) {
        emit(state.copyWith(
          status: LoginStatus.success,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: result.errorMessage ?? 'Error al iniciar sesión con Facebook',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Error al iniciar sesión con Facebook: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event,
      Emitter<LoginState> emit,
      ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading));

      await _authService.signOut();

      emit(state.copyWith(
        status: LoginStatus.loggedOut,
        email: '',
        password: '',
        errorMessage: null,
        isEmailValid: false,
        isPasswordValid: false,
        isFormValid: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Error al cerrar sesión: ${e.toString()}',
      ));
    }
  }

  Future<void> _onForgotPasswordRequested(
      ForgotPasswordRequested event,
      Emitter<LoginState> emit,
      ) async {
    if (!_validateEmail(event.email)) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Por favor, ingrese un email válido',
      ));
      return;
    }

    try {
      emit(state.copyWith(status: LoginStatus.loading));

      final result = await _authService.resetPassword(event.email);

      if (result.isSuccess) {
        emit(state.copyWith(
          status: LoginStatus.initial,
          errorMessage: 'Se ha enviado un correo para restablecer su contraseña',
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: result.errorMessage ?? 'Error al enviar correo de recuperación',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Error al enviar correo de recuperación: ${e.toString()}',
      ));
    }
  }*/

  void _onPasswordVisibilityToggled(
      PasswordVisibilityToggled event,
      Emitter<LoginState> emit,
      ) {
    emit(state.copyWith(
      isPasswordVisible: !state.isPasswordVisible,
    ));
  }

  void _onLoginStatusReset(
      LoginStatusReset event,
      Emitter<LoginState> emit,
      ) {
    emit(state.copyWith(
      status: LoginStatus.initial,
      errorMessage: null,
    ));
  }

  // Métodos de validación
  bool _validateEmail(String email) {
    return email.trim().isNotEmpty &&
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.trim().isNotEmpty && password.length >= 6;
  }
}