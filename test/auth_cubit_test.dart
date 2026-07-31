import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_maker/features/auth/data/auth_repository.dart';
import 'package:ticket_maker/features/auth/domain/entities/app_user.dart';
import 'package:ticket_maker/features/auth/domain/pending_auth_action.dart';
import 'package:ticket_maker/features/auth/presentation/bloc/auth_cubit.dart';

const _user = AppUser(
  id: 'user-1',
  email: 'ada@example.com',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

/// Auth backend whose every outcome is set per test, including failures the
/// in-repo [FakeAuthRepository] cannot produce (thrown non-[AuthException]s).
class _ScriptedAuthRepository implements AuthRepository {
  AppUser? session;
  Object? loadSessionError;
  Object? signInError;
  Object? signUpError;
  Object? socialError;
  Object? updateProfileError;
  AppUser result = _user;
  int signOutCalls = 0;

  @override
  Future<AppUser?> loadSession() async {
    if (loadSessionError != null) throw loadSessionError!;
    return session;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (signInError != null) throw signInError!;
    return result;
  }

  @override
  Future<AppUser> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    if (signUpError != null) throw signUpError!;
    return result;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    if (socialError != null) throw socialError!;
    return result;
  }

  @override
  Future<AppUser> signInWithApple() async {
    if (socialError != null) throw socialError!;
    return result;
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    if (updateProfileError != null) throw updateProfileError!;
    return user;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    session = null;
  }
}

/// Builds a cubit and lets its constructor-triggered restoreSession settle.
Future<AuthCubit> _settledCubit(_ScriptedAuthRepository repository) async {
  final cubit = AuthCubit(repository: repository);
  await pumpEventQueue();
  return cubit;
}

void main() {
  late _ScriptedAuthRepository repository;

  setUp(() {
    repository = _ScriptedAuthRepository();
  });

  group('restoreSession on construction', () {
    test('authenticates when the backend has a session', () async {
      repository.session = _user;

      final cubit = await _settledCubit(repository);

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.user, _user);
      expect(cubit.state.isAuthenticated, isTrue);
    });

    test('falls to unauthenticated when there is no session', () async {
      final cubit = await _settledCubit(repository);

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.user, isNull);
    });

    test('treats a failing session load as unauthenticated', () async {
      repository.session = _user;
      repository.loadSessionError = Exception('offline');

      final cubit = await _settledCubit(repository);

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.user, isNull);
    });
  });

  group('signIn', () {
    test('authenticates and reports success', () async {
      final cubit = await _settledCubit(repository);

      final ok = await cubit.signIn(
        email: 'ada@example.com',
        password: 'secret',
      );

      expect(ok, isTrue);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.user, _user);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.message, 'Signed in');
      expect(cubit.state.justSignedUp, isFalse);
    });

    test('surfaces the AuthException message and stays unauthenticated',
        () async {
      final cubit = await _settledCubit(repository);
      repository.signInError = AuthException('Incorrect email or password.');

      final ok = await cubit.signIn(email: 'ada@example.com', password: 'wrong');

      expect(ok, isFalse);
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.message, 'Incorrect email or password.');
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.user, isNull);
    });

    test('maps an unexpected error to a generic message', () async {
      final cubit = await _settledCubit(repository);
      repository.signInError = StateError('boom');

      final ok = await cubit.signIn(email: 'ada@example.com', password: 'x');

      expect(ok, isFalse);
      expect(cubit.state.message, 'Could not sign in. Try again.');
      expect(cubit.state.isSubmitting, isFalse);
    });
  });

  group('signUp', () {
    test('flags justSignedUp, which clearJustSignedUp resets', () async {
      final cubit = await _settledCubit(repository);

      final ok = await cubit.signUp(
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        password: 'secret1',
      );

      expect(ok, isTrue);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.justSignedUp, isTrue);
      expect(cubit.state.message, 'Account created');

      cubit.clearJustSignedUp();
      expect(cubit.state.justSignedUp, isFalse);
    });

    test('surfaces the AuthException message', () async {
      final cubit = await _settledCubit(repository);
      repository.signUpError =
          AuthException('An account already exists for that email.');

      final ok = await cubit.signUp(
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        password: 'secret1',
      );

      expect(ok, isFalse);
      expect(cubit.state.message, 'An account already exists for that email.');
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('maps an unexpected error to a generic message', () async {
      final cubit = await _settledCubit(repository);
      repository.signUpError = StateError('boom');

      final ok = await cubit.signUp(
        firstName: 'Ada',
        lastName: 'Lovelace',
        email: 'ada@example.com',
        password: 'secret1',
      );

      expect(ok, isFalse);
      expect(cubit.state.message, 'Could not create account. Try again.');
    });
  });

  group('social sign-in', () {
    test('Google success authenticates without the new-account flag', () async {
      final cubit = await _settledCubit(repository);

      final ok = await cubit.signInWithGoogle();

      expect(ok, isTrue);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.justSignedUp, isFalse);
      expect(cubit.state.message, 'Signed in');
    });

    test('Apple cancellation stays unauthenticated with the reason', () async {
      final cubit = await _settledCubit(repository);
      repository.socialError = AuthException('Apple Sign-In was cancelled.');

      final ok = await cubit.signInWithApple();

      expect(ok, isFalse);
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.message, 'Apple Sign-In was cancelled.');
    });
  });

  group('pending action (guest → auth resume)', () {
    test('is handed back exactly once', () async {
      final cubit = await _settledCubit(repository);

      cubit.setPendingAction(const PendingSaveTicketAction());
      expect(cubit.state.pendingAction, const PendingSaveTicketAction());

      expect(cubit.takePendingAction(), const PendingSaveTicketAction());
      expect(cubit.state.pendingAction, isNull);
      expect(cubit.takePendingAction(), isNull);
    });

    test('setPendingAction(null) clears a stored action', () async {
      final cubit = await _settledCubit(repository);

      cubit.setPendingAction(const PendingSaveTicketAction());
      cubit.setPendingAction(null);

      expect(cubit.state.pendingAction, isNull);
    });
  });

  group('updateProfile', () {
    test('saves personalization for a signed-in user', () async {
      repository.session = _user;
      final cubit = await _settledCubit(repository);

      await cubit.updateProfile(
        preferredCity: 'Lagos',
        interests: const ['music'],
        marketingOptIn: true,
      );

      expect(cubit.state.user!.preferredCity, 'Lagos');
      expect(cubit.state.user!.interests, const ['music']);
      expect(cubit.state.user!.marketingOptIn, isTrue);
      expect(cubit.state.message, 'Profile saved');
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('is a no-op when nobody is signed in', () async {
      final cubit = await _settledCubit(repository);
      final before = cubit.state;

      await cubit.updateProfile(preferredCity: 'Lagos');

      expect(cubit.state, before);
    });

    test('reports a failure without dropping the user', () async {
      repository.session = _user;
      final cubit = await _settledCubit(repository);
      repository.updateProfileError = StateError('boom');

      await cubit.updateProfile(preferredCity: 'Lagos');

      expect(cubit.state.message, 'Could not save profile.');
      expect(cubit.state.user, _user);
      expect(cubit.state.isSubmitting, isFalse);
    });
  });

  group('signOut and messages', () {
    test('signOut clears the session and resets state', () async {
      repository.session = _user;
      final cubit = await _settledCubit(repository);

      await cubit.signOut();

      expect(repository.signOutCalls, 1);
      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.user, isNull);
      expect(cubit.state.message, isNull);
      expect(cubit.state.pendingAction, isNull);
    });

    test('clearMessage drops a message and is inert when there is none',
        () async {
      final cubit = await _settledCubit(repository);
      await cubit.signIn(email: 'ada@example.com', password: 'secret');
      expect(cubit.state.message, isNotNull);

      cubit.clearMessage();
      expect(cubit.state.message, isNull);

      final before = cubit.state;
      cubit.clearMessage();
      expect(cubit.state, before);
    });
  });
}
