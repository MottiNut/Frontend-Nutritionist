import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginEmailChanged extends LoginEvent {
  final String email;

  const LoginEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

class LoginPasswordChanged extends LoginEvent {
  final String password;

  const LoginPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

class LoginWithGoogleRequested extends LoginEvent {
  const LoginWithGoogleRequested();
}

class LoginWithFacebookRequested extends LoginEvent {
  const LoginWithFacebookRequested();
}

class LogoutRequested extends LoginEvent {
  const LogoutRequested();
}

class ForgotPasswordRequested extends LoginEvent {
  final String email;

  const ForgotPasswordRequested(this.email);

  @override
  List<Object> get props => [email];
}

class PasswordVisibilityToggled extends LoginEvent {
  const PasswordVisibilityToggled();
}

class LoginStatusReset extends LoginEvent {
  const LoginStatusReset();
}