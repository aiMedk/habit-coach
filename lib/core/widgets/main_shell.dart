import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/router/app_router.dart';

/// T143: Shell widget that wraps the four main tabs (Dashboard, Challenges,
/// Reviews, Settings) with a persistent [BottomNavigationBar].
///
/// Used as the [builder] of the [StatefulShellRoute] in [appRouterProvider].
/// The [navigationShell] manages independent navigation stacks per branch.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reviews',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    navigationShell.goBranch(
      index,
      // Return to branch root when re-tapping an already-active tab.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Destination root routes for each bottom-nav branch.
extension ShellBranch on AppRoutes {
  static const List<String> tabRoots = [
    AppRoutes.dashboard,
    AppRoutes.challenges,
    AppRoutes.reviews,
    AppRoutes.settings,
  ];
}
