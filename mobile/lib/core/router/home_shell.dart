import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent bottom-navigation shell wrapping the five primary branches:
/// Quests · Skills · Bosses · Social · Profile.
///
/// Uses [StatefulNavigationShell] so each tab keeps its own navigation stack
/// and scroll position.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_NavItem>[
    _NavItem(Icons.explore_outlined, Icons.explore_rounded, 'Quests'),
    _NavItem(Icons.auto_graph_outlined, Icons.auto_graph_rounded, 'Skills'),
    _NavItem(Icons.local_fire_department_outlined, Icons.local_fire_department_rounded, 'Bosses'),
    _NavItem(Icons.groups_outlined, Icons.groups_rounded, 'Social'),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void _onTap(int index) => navigationShell.goBranch(
        index,
        // Tapping the active tab pops it back to its root.
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.activeIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
