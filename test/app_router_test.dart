import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ticket_maker/core/router/app_router.dart';
import 'package:ticket_maker/features/account/presentation/pages/legal_document_page.dart';
import 'package:ticket_maker/features/generate/presentation/pages/generate_page.dart';
import 'package:ticket_maker/features/tickets/data/ticket_public_verify.dart';
import 'package:ticket_maker/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:ticket_maker/features/tickets/presentation/pages/tickets_page.dart';
import 'package:ticket_maker/features/verify/presentation/pages/ticket_verification_screen.dart';

const _code = '1234-5678-910';

List<GoRoute> _topLevelRoutes() =>
    appRouter.configuration.routes.whereType<GoRoute>().toList();

StatefulShellRoute _shell() =>
    appRouter.configuration.routes.whereType<StatefulShellRoute>().single;

GoRoute _topLevelRouteAt(String path) =>
    _topLevelRoutes().firstWhere((route) => route.path == path);

void main() {
  group('route table', () {
    test('exposes /verify/:id as a public top-level route', () {
      final verify = _topLevelRouteAt(TicketVerificationScreen.routePath);

      expect(verify.path, '/verify/:id');
      expect(verify.name, TicketVerificationScreen.routeName);
    });

    test('keeps verification outside the bottom-nav shell', () {
      final shellPaths = _shell()
          .branches
          .expand((branch) => branch.routes)
          .whereType<GoRoute>()
          .map((route) => route.path);

      expect(shellPaths, isNot(contains(TicketVerificationScreen.routePath)));
    });

    test('exposes the legal documents as top-level routes', () {
      expect(
        _topLevelRouteAt(LegalDocumentPage.termsPath).name,
        LegalDocumentPage.termsName,
      );
      expect(
        _topLevelRouteAt(LegalDocumentPage.privacyPath).name,
        LegalDocumentPage.privacyName,
      );
    });

    test('shells Generate and Tickets as the two nav branches', () {
      final branches = _shell().branches;
      expect(branches, hasLength(2));

      final generate = branches.first.routes.whereType<GoRoute>().single;
      expect(generate.path, GeneratePage.routePath);

      final tickets = branches.last.routes.whereType<GoRoute>().single;
      expect(tickets.path, TicketsPage.routePath);
    });

    test('nests ticket detail under the Tickets branch', () {
      final tickets =
          _shell().branches.last.routes.whereType<GoRoute>().single;
      final detail = tickets.routes.whereType<GoRoute>().single;

      expect(detail.path, ':ticketId');
      expect(detail.name, TicketDetailPage.routeName);
    });
  });

  group('verification screen behind the deep link', () {
    Future<void> pumpVerification(
      WidgetTester tester, {
      required String ticketId,
      required FakeFirebaseFirestore firestore,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: TicketVerificationScreen(
            ticketId: ticketId,
            verifier: TicketPublicVerify(firestore: firestore),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('confirms a valid ticket for the door', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('tickets').doc(_code).set(<String, dynamic>{
        'status': 'valid',
        'eventName': "Ejike's Birthday Bash",
        'guestName': 'Ada Lovelace',
      });

      await pumpVerification(
        tester,
        ticketId: _code,
        firestore: firestore,
      );

      expect(find.text('CONFIRMED - TICKET VALID'), findsOneWidget);
      expect(find.text(_code), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('warns when the same ticket is scanned twice', (tester) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('tickets').doc(_code).set(<String, dynamic>{
        'status': 'checked_in',
        'checkedIn': true,
        'eventName': "Ejike's Birthday Bash",
      });

      await pumpVerification(
        tester,
        ticketId: _code,
        firestore: firestore,
      );

      expect(find.text('WARNING: TICKET ALREADY USED'), findsOneWidget);
    });

    testWidgets('rejects an unknown code', (tester) async {
      await pumpVerification(
        tester,
        ticketId: '9999-8888-777',
        firestore: FakeFirebaseFirestore(),
      );

      expect(
        find.text('INVALID TICKET - TICKET NOT FOUND'),
        findsOneWidget,
      );
    });
  });
}
