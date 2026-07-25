import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/battle_pass/presentation/screens/battle_pass_screen.dart';
import '../../features/bosses/presentation/screens/boss_detail_screen.dart';
import '../../features/bosses/presentation/screens/bosses_screen.dart';
import '../../features/character/presentation/screens/character_creation_screen.dart';
import '../../features/economy/presentation/screens/inventory_screen.dart';
import '../../features/economy/presentation/screens/shop_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/paywall_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/quests/presentation/screens/home_dashboard_screen.dart';
import '../../features/skills/presentation/screens/skills_screen.dart';
import '../../features/social/presentation/screens/guild_screen.dart';
import '../../features/social/presentation/screens/pvp_screen.dart';
import '../../features/social/presentation/screens/social_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/streaks/presentation/screens/streaks_screen.dart';
import '../config/di.dart';
import 'app_routes.dart';
import 'home_shell.dart';

/// Root + shell navigator keys. The shell key hosts the bottom-nav branches so
/// pushed detail routes cover the whole screen.
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// The app router. Redirects are derived from [AuthController]:
///  - unauthenticated → onboarding/login
///  - authenticated but no character → character creation
///  - authenticated → home shell
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoute.quests.path,
    refreshListenable: refresh,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final store = ref.read(localStoreProvider);
      final loc = state.matchedLocation;

      // Wait for silent bootstrap before making a decision.
      if (auth.status == AuthStatus.unknown) return null;

      final onboardingSeen = store.onboardingSeen;
      final atOnboarding = loc == AppRoute.onboarding.path;
      final atAuth = loc == AppRoute.login.path || loc == AppRoute.register.path;
      final atCreate = loc == AppRoute.characterCreation.path;

      final isLoggedIn = auth.status == AuthStatus.authenticated ||
          auth.status == AuthStatus.needsCharacter;

      // Not logged in.
      if (!isLoggedIn) {
        if (!onboardingSeen && !atOnboarding) return AppRoute.onboarding.path;
        if (onboardingSeen && !atAuth && !atOnboarding) return AppRoute.login.path;
        return null;
      }

      // Logged in but needs a character.
      if (auth.status == AuthStatus.needsCharacter) {
        return atCreate ? null : AppRoute.characterCreation.path;
      }

      // Fully authenticated — bounce away from auth/onboarding/create.
      if (atAuth || atOnboarding || atCreate) return AppRoute.quests.path;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoute.onboarding.path,
        name: AppRoute.onboarding.name,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            name: AppRoute.register.name,
            builder: (_, __) => const RegisterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoute.characterCreation.path,
        name: AppRoute.characterCreation.name,
        builder: (_, __) => const CharacterCreationScreen(),
      ),

      // ── Home shell with bottom-nav branches ─────────────────────────────────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (_, __, navShell) => HomeShell(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: AppRoute.quests.path,
                name: AppRoute.quests.name,
                builder: (_, __) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.skills.path,
                name: AppRoute.skills.name,
                builder: (_, __) => const SkillsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.bosses.path,
                name: AppRoute.bosses.name,
                builder: (_, __) => const BossesScreen(),
                routes: [
                  GoRoute(
                    path: AppRoute.bossDetail.path, // boss/:bossId
                    name: AppRoute.bossDetail.name,
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) =>
                        BossDetailScreen(bossId: state.pathParameters['bossId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.social.path,
                name: AppRoute.social.name,
                builder: (_, __) => const SocialScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                name: AppRoute.profile.name,
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Root-level pushed routes ────────────────────────────────────────────
      _root(AppRoute.achievements, (_, __) => const InventoryScreen()),
      _root(AppRoute.inventory, (_, __) => const InventoryScreen()),
      _root(AppRoute.shop, (_, __) => const ShopScreen()),
      _root(AppRoute.streaks, (_, __) => const StreaksScreen()),
      _root(AppRoute.guild, (_, __) => const GuildScreen()),
      _root(AppRoute.pvp, (_, __) => const PvpScreen()),
      _root(AppRoute.stats, (_, __) => const StatsScreen()),
      _root(AppRoute.aiCoach, (_, __) => const AiCoachScreen()),
      _root(AppRoute.battlePass, (_, __) => const BattlePassScreen()),
      _root(AppRoute.paywall, (_, __) => const PaywallScreen()),
      _root(AppRoute.settings, (_, __) => const SettingsScreen()),
    ],
  );
});

GoRoute _root(AppRoute route, Widget Function(BuildContext, GoRouterState) builder) =>
    GoRoute(
      path: route.path,
      name: route.name,
      parentNavigatorKey: _rootKey,
      builder: builder,
    );

/// Bridges Riverpod → go_router: notifies the router to re-run `redirect`
/// whenever auth status or onboarding flag changes.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
