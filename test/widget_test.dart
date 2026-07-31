import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticket_maker/app.dart';
import 'package:ticket_maker/core/router/app_router.dart';
import 'package:ticket_maker/features/auth/data/auth_repository.dart';
import 'package:ticket_maker/features/generate/presentation/bloc/generate_cubit.dart';
import 'package:ticket_maker/features/generate/presentation/pages/generate_page.dart';
import 'package:ticket_maker/features/tickets/data/ticket_image_store.dart';
import 'package:ticket_maker/features/tickets/data/ticket_local_repository.dart';

Widget buildTestApp({
  AuthRepository? authRepository,
  TicketLocalRepository? ticketsRepository,
  TicketImageStore? ticketsImageStore,
}) {
  return TicketMakerApp(
    authRepository: authRepository ?? FakeAuthRepository(),
    ticketsRepository: ticketsRepository,
    ticketsImageStore: ticketsImageStore,
  );
}

Future<AuthRepository> seedSignedInUser() async {
  final repo = FakeAuthRepository();
  await repo.signUp(
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: 'ada@example.com',
    password: 'secret1',
  );
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    // Global GoRouter retains location across tests; reset to Generate.
    appRouter.go(GeneratePage.routePath);
  });

  testWidgets('App opens on Generate home with Generate and Tickets nav', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('My Tickets'), findsOneWidget);
    expect(find.text("Ejike's Birthday Bash"), findsOneWidget);
    expect(find.text('Change color'), findsOneWidget);
    expect(find.text('Change shape'), findsOneWidget);
    expect(find.text('Create Guest Link'), findsNothing);
    expect(find.text('Save Ticket'), findsOneWidget);

    expect(find.text('Generate'), findsWidgets);
    expect(find.text('Tickets'), findsOneWidget);
    expect(find.text('Discover'), findsNothing);
    expect(find.text('Account'), findsNothing);
  });

  testWidgets('Generate page shows ticket title branding', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('My Tickets'), findsOneWidget);
    expect(find.text('GUEST PASS'), findsOneWidget);
    expect(find.text("Ejike's Birthday Bash"), findsOneWidget);
    expect(find.text('VIP Guest Pass'), findsOneWidget);
    expect(find.text('Private gathering'), findsOneWidget);
    expect(find.byIcon(Icons.threed_rotation), findsNothing);
    expect(find.byIcon(Icons.place_outlined), findsOneWidget);
    expect(find.text('Create Guest Link'), findsNothing);
    expect(find.text('Bg color'), findsOneWidget);
    expect(find.text('Save Ticket'), findsOneWidget);
    // Date row defaults to today (GenerateCubit uses DateTime.now()) and is
    // rendered in long form, e.g. `Friday, 31 July 2026`.
    final todayLabel = GenerateCubit.formatFullDateLabel(DateTime.now());
    expect(find.text(todayLabel), findsOneWidget);
    expect(find.text('TICKET ID'), findsOneWidget);
    expect(find.text('ABOUT THIS EVENT'), findsOneWidget);
    expect(find.text('Powered by Quick Ticket'), findsOneWidget);
  });

  testWidgets('Tickets tab starts empty without saved records', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tickets'));
    await tester.pumpAndSettle();

    expect(find.text('No saved tickets yet'), findsOneWidget);
    expect(find.text("Ejike's Birthday Bash"), findsNothing);
  });

  testWidgets('Guest Save Ticket saves without auth gate', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.ensureVisible(find.text('Save Ticket'));
    await tester.tap(find.text('Save Ticket'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sign in to continue'), findsNothing);
    expect(find.text('Sign In'), findsNothing);
  });
}
