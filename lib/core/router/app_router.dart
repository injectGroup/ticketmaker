import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/legal_document_page.dart';
import '../../features/generate/presentation/pages/generate_page.dart';
import '../../features/tickets/presentation/pages/ticket_detail_page.dart';
import '../../features/tickets/presentation/pages/tickets_page.dart';
import '../../features/verify/presentation/pages/ticket_verification_screen.dart';
import '../theme/app_theme.dart';

/// App routes: Generate + Tickets shell, plus public `/verify/:id`.
final GoRouter appRouter = GoRouter(
  initialLocation: GeneratePage.routePath,
  routes: [
    GoRoute(
      path: LegalDocumentPage.termsPath,
      name: LegalDocumentPage.termsName,
      builder: (context, state) => const LegalDocumentPage(
        title: 'Terms of Service',
        body: LegalDocumentPage.termsBody,
      ),
    ),
    GoRoute(
      path: LegalDocumentPage.privacyPath,
      name: LegalDocumentPage.privacyName,
      builder: (context, state) => const LegalDocumentPage(
        title: 'Privacy Policy',
        body: LegalDocumentPage.privacyBody,
      ),
    ),
    GoRoute(
      path: '/verify/:id',
      name: TicketVerificationScreen.routeName,
      builder: (context, state) => TicketVerificationScreen(
        ticketId: state.pathParameters['id'] ?? '',
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },
      branches: [
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
      ],
    ),
  ],
);

/// Bottom nav shell: Generate + Tickets only.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.primary, size: 24);
            }
            return IconThemeData(
              color: AppColors.secondaryText.withValues(alpha: 0.9),
              size: 24,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              );
            }
            return TextStyle(
              color: AppColors.secondaryText.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: navigationShell.goBranch,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          destinations: const [
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
          ],
        ),
      ),
    );
  }
}
