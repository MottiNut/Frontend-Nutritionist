import 'package:equatable/equatable.dart';

enum LoginStatus {
  initial,
  loading,
  success,
  failure,
  loggedOut,
}

class LoginState extends Equatable {
  final LoginStatus status;
  final String email;
  final String password;
  final String? errorMessage;
  final bool isPasswordVisible;
  final bool isEmailValid;
  final bool isPasswordValid;
  final bool isFormValid;

  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.errorMessage,
    this.isPasswordVisible = false,
    this.isEmailValid = false,
    this.isPasswordValid = false,
    this.isFormValid = false,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    String? errorMessage,
    bool? isPasswordVisible,
    bool? isEmailValid,
    bool? isPasswordValid,
    bool? isFormValid,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isEmailValid: isEmailValid ?? this.isEmailValid,
      isPasswordValid: isPasswordValid ?? this.isPasswordValid,
      isFormValid: isFormValid ?? this.isFormValid,
    );
  }

  @override
  List<Object?> get props => [
    status,
    email,
    password,
    errorMessage,
    isPasswordVisible,
    isEmailValid,
    isPasswordValid,
    isFormValid,
  ];
}