import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/services/auth_service.dart';

import 'package:my_ai_pal/services/error_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authService.login(event.username, event.password);
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthFailure(message: 'Invalid username or password.'));
        }
      } catch (e, s) {
        ErrorService.handleError(e, s);
        emit(AuthFailure(message: e.toString()));
      }
    });

    on<AuthSignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authService.signUp(
          username: event.username,
          password: event.password,
          usersName: event.usersName,
          aiPalName: event.aiPalName,
        );
        if (user != null) {
          final loggedInUser = await _authService.login(event.username, event.password);
          if (loggedInUser != null) {
            emit(AuthAuthenticated(user: loggedInUser));
          } else {
            emit(AuthFailure(message: 'Login after sign up failed.'));
          }
        } else {
          emit(AuthFailure(message: 'Username is already taken.'));
        }
      } catch (e, s) {
        ErrorService.handleError(e, s);
        emit(AuthFailure(message: e.toString()));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _authService.logout();
      emit(AuthUnauthenticated());
    });

    on<AuthCheckRequested>((event, emit) async {
      try {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e, s) {
        ErrorService.handleError(e, s);
        emit(AuthUnauthenticated());
      }
    });
  }
}
