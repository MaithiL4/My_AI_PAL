part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String usersName;
  final String aiPalName;

  AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.usersName,
    required this.aiPalName,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class _AuthUserChanged extends AuthEvent {
  final User? user;

  _AuthUserChanged(this.user);
}