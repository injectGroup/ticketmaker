import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/legal_document_page.dart';
import '../../features/discover/domain/entities/event.dart';
import '../../features/generate/presentation/pages/generate_page.dart';
import '../../features/seating/presentation/pages/interactive_seating_page.dart';
import '../../features/tickets/presentation/pages/ticket_detail_page.dart';
import '../../features/tickets/presentation/pages/tickets_page.dart';
import '../../presentation/pages/discover_screen.dart';
import '../theme/app_theme.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: DiscoverScreen.routePath,
  routes: [
    GoRoute(
      path: InteractiveSeatingPage.routePath,
      name: InteractiveSeatingPage.routeName,
      builder: (context, state) {
        final event = state.extra;
        if (event is! Event) {
          return const Scaffold(
            body: Center(child: Text('Missing event for seating map')),
          );
        }
        return InteractiveSeatingPage(event: event);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: DiscoverScreen.routePath,
              name: DiscoverScreen.routeName,
              builder: (context, state) => const DiscoverScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: GeneratePage.routePath,
              name: GeneratePage.routeName,
              builder: (context, state) => const GeneratePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: TicketsPage.routePath,
              name: TicketsPage.routeName,
              builder: (context, state) => const TicketsPage(),
              routes: [
                GoRoute(
                  path: ':ticketId',
                  name: TicketDetailPage.routeName,
                  builder: (context, state) => TicketDetailPage(
                    ticketId: state.pathParameters['ticketId']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AccountPage.routePath,
              name: AccountPage.routeName,
              builder: (context, state) {
                final personalize =
                    state.uri.queryParameters['personalize'] == '1';
                return AccountPage(personalize: personalize);
              },
              routes: [
                GoRoute(
                  path: 'terms',
                  name: LegalDocumentPage.termsName,
                  builder: (context, state) => const LegalDocumentPage(
                    title: 'Terms of Service',
                    body: LegalDocumentPage.termsBody,
                  ),
                ),
                GoRoute(
                  path: 'privacy',
                  name: LegalDocumentPage.privacyName,
                  builder: (context, state) => const LegalDocumentPage(
                    title: 'Privacy Policy',
                    body: LegalDocumentPage.privacyBody,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_outlined),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Generate',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Tickets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
