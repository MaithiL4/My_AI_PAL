import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:my_ai_pal/models/user.dart';
import 'package:my_ai_pal/services/auth_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _userSubscription;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) {
      _userSubscription?.cancel();
      _userSubscription = _authService.currentUser.listen((user) {
        add(_AuthUserChanged(user));
      });
    });

    on<_AuthUserChanged>((event, emit) {
      if (event.user != null) {
        emit(AuthAuthenticated(user: event.user!));
      } else {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authService.login(event.email, event.password);
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthFailure(message: 'Login failed. Please check your credentials.'));
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthFailure(message: 'An error occurred during login.'));
        emit(AuthUnauthenticated());
      }
    });

    on<AuthSignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await _authService.signUp(
          email: event.email,
          password: event.password,
          usersName: event.usersName,
          aiPalName: event.aiPalName,
        );
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthFailure(message: 'Sign up failed. Please try again.'));
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthFailure(message: 'An error occurred during sign up.'));
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _authService.logout();
      emit(AuthUnauthenticated());
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}