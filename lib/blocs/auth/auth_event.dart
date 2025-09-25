part of 'auth_bloc.dart';

@immutable
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  AuthLoginRequested({required this.username, required this.password});
}

class AuthSignUpRequested extends AuthEvent {
  final String username;
  final String password;
  final String usersName;
  final String aiPalName;

  AuthSignUpRequested({
    required this.username,
    required this.password,
    required this.usersName,
    required this.aiPalName,
  });
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

