/// Named routes + paths for the entire app. Using an enum keeps navigation
/// type-safe (`context.goNamed(AppRoute.quests.name)`) and centralizes paths.
enum AppRoute {
  // Onboarding / auth
  onboarding('/onboarding', 'onboarding'),
  login('/login', 'login'),
  register('/register', 'register'),
  characterCreation('/create-character', 'character-creation'),

  // Home shell (bottom nav branches)
  quests('/quests', 'quests'),
  skills('/skills', 'skills'),
  bosses('/bosses', 'bosses'),
  social('/social', 'social'),
  profile('/profile', 'profile'),

  // Detail / pushed routes
  bossDetail('boss/:bossId', 'boss-detail'),
  questEdit('/quests/edit', 'quest-edit'),
  achievements('/achievements', 'achievements'),
  inventory('/inventory', 'inventory'),
  shop('/shop', 'shop'),
  streaks('/streaks', 'streaks'),
  guild('/guild', 'guild'),
  pvp('/pvp', 'pvp'),
  stats('/stats', 'stats'),
  aiCoach('/ai-coach', 'ai-coach'),
  battlePass('/battle-pass', 'battle-pass'),
  paywall('/paywall', 'paywall'),
  settings('/settings', 'settings');

  const AppRoute(this.path, this.name);

  /// Path segment used in [GoRoute.path].
  final String path;

  /// Stable name used with `goNamed` / `pushNamed`.
  final String name;
}
