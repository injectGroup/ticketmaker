import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/pending_auth_action.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({AuthRepository? repository})
    : _repository = repository ?? FirebaseAuthRepository(),
      super(const AuthState()) {
    restoreSession();
  }

  final AuthRepository _repository;

  Future<void> restoreSession() async {
    try {
      final user = await _repository.loadSession();
      if (user == null) {
        emit(
          state.copyWith(status: AuthStatus.unauthenticated, clearUser: true),
        );
      } else {
        emit(state.copyWith(status: AuthStatus.authenticated, user: user));
      }
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, clearUser: true));
    }
  }

  void setPendingAction(PendingAuthAction? action) {
    emit(
      state.copyWith(
        pendingAction: action,
        clearPending: action == null,
      ),
    );
  }

  PendingAuthAction? takePendingAction() {
    final action = state.pendingAction;
    if (action != null) {
      emit(state.copyWith(clearPending: true));
    }
    return action;
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    try {
      final user = await _repository.signIn(email: email, password: password);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          justSignedUp: false,
          message: 'Signed in',
        ),
      );
      return true;
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          message: e.message,
          status: AuthStatus.unauthenticated,
        ),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          message: 'Could not sign in. Try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    try {
      final user = await _repository.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          justSignedUp: true,
          message: 'Account created',
        ),
      );
      return true;
    } on AuthException catch (e) {
      emit(state.copyWith(isSubmitting: false, message: e.message));
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          message: 'Could not create account. Try again.',
        ),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() => _socialSignIn(_repository.signInWithGoogle);

  Future<bool> signInWithApple() => _socialSignIn(_repository.signInWithApple);

  Future<bool> _socialSignIn(Future<AppUser> Function() action) async {
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    try {
      final user = await action();
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isSubmitting: false,
          justSignedUp: false,
          message: 'Signed in',
        ),
      );
      return true;
    } on AuthException catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(
          isSubmitting: false,
          message: e.message,
          status: AuthStatus.unauthenticated,
        ),
      );
      return false;
    } catch (e) {
      debugPrint(e.toString());
      emit(
        state.copyWith(
          isSubmitting: false,
          message: 'Could not sign in. Try again.',
        ),
      );
      return false;
    }
  }

  Future<void> updateProfile({
    String? preferredCity,
    List<String>? interests,
    bool? marketingOptIn,
  }) async {
    final current = state.user;
    if (current == null) return;
    emit(state.copyWith(isSubmitting: true, clearMessage: true));
    try {
      final updated = await _repository.updateProfile(
        current.copyWith(
          preferredCity: preferredCity,
          interests: interests,
          marketingOptIn: marketingOptIn,
        ),
      );
      emit(
        state.copyWith(
          user: updated,
          isSubmitting: false,
          justSignedUp: false,
          message: 'Profile saved',
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(isSubmitting: false, message: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          message: 'Could not save profile.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void clearMessage() {
    if (state.message != null) {
      emit(state.copyWith(clearMessage: true));
    }
  }

  void clearJustSignedUp() {
    if (state.justSignedUp) {
      emit(state.copyWith(justSignedUp: false));
    }
  }
}
