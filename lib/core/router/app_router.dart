import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/generate/presentation/pages/generate_page.dart';
import '../../features/tickets/presentation/pages/tickets_page.dart';
import '../theme/app_theme.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: GeneratePage.routePath,
  routes: [
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
    );
  }
}
