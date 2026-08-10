import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticket_maker/features/auth/data/auth_repository.dart';
import 'package:ticket_maker/features/auth/domain/entities/app_user.dart';
import 'package:ticket_maker/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:ticket_maker/features/tickets/presentation/widgets/share_auth_gate.dart';

const _user = AppUser(
  id: 'user-1',
  email: 'ada@example.com',
  firstName: 'Ada',
  lastName: 'Lovelace',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('share auth gate offers Sign In / Sign Up and Cancel', (
    tester,
  ) async {
    bool? choice;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  choice = await showShareAuthGate(context);
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('share-auth-gate-sheet')), findsOneWidget);
    expect(
      find.text('Sign In or Create an Account to Share Tickets'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('share-auth-gate-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('share-auth-gate-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const Key('share-auth-gate-cancel')));
    await tester.pumpAndSettle();
    expect(choice, isFalse);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('share-auth-gate-sign-in')));
    await tester.pumpAndSettle();
    expect(choice, isTrue);
  });

  test('guest AuthCubit is not authenticated for share', () async {
    final cubit = AuthCubit(repository: FakeAuthRepository());
    await pumpEventQueue();
    addTearDown(cubit.close);
    expect(cubit.state.isAuthenticated, isFalse);
  });

  test('signed-in AuthCubit is authenticated for share', () async {
    final cubit = AuthCubit(
      repository: FakeAuthRepository(initialUser: _user),
    );
    await pumpEventQueue();
    addTearDown(cubit.close);
    expect(cubit.state.isAuthenticated, isTrue);
  });
}
