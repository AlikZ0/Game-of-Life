import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_quest/l10n/app_localizations.dart';

/// The persistent bottom-navigation shell wrapping the five primary branches:
/// Quests · Skills · Bosses · Social · Profile.
///
/// Uses [StatefulNavigationShell] so each tab keeps its own navigation stack
/// and scroll position.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_NavItem>[
    _NavItem(Icons.explore_outlined, Icons.explore_rounded),
    _NavItem(Icons.auto_graph_outlined, Icons.auto_graph_rounded),
    _NavItem(Icons.local_fire_department_outlined, Icons.local_fire_department_rounded),
    _NavItem(Icons.groups_outlined, Icons.groups_rounded),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded),
  ];

  void _onTap(int index) => navigationShell.goBranch(
        index,
        // Tapping the active tab pops it back to its root.
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[
      l10n.navQuests,
      l10n.navSkills,
      l10n.navBosses,
      l10n.navSocial,
      l10n.navProfile,
    ];
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          for (var i = 0; i < _destinations.length; i++)
            NavigationDestination(
              icon: Icon(_destinations[i].icon),
              selectedIcon: Icon(_destinations[i].activeIcon),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon);
  final IconData icon;
  final IconData activeIcon;
}
