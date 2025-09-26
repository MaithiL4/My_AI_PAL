import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
        emit(AuthAuthenticated(user: user));
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          emit(AuthFailure(message: 'No user found for that email.'));
        } else if (e.code == 'wrong-password') {
          emit(AuthFailure(message: 'Wrong password provided for that user.'));
        } else {
          emit(AuthFailure(message: 'An error occurred during login.'));
        }
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
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
        emit(AuthAuthenticated(user: user));
      } on firebase_auth.FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          emit(AuthFailure(message: 'The email address is already in use by another account.'));
        } else {
          emit(AuthFailure(message: 'An error occurred during sign up.'));
        }
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthFailure(message: e.toString()));
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      await _authService.logout();
      emit(AuthUnauthenticated());
    });

    on<UserUpdated>((event, emit) {
      if (state is AuthAuthenticated) {
        emit(AuthAuthenticated(user: event.user));
      }
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
