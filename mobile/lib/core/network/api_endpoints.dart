/// Endpoint catalog mirroring the NestJS `/api/v1` contract.
///
/// Keeping every path in one place makes the API surface auditable and keeps
/// data sources free of stringly-typed literals.
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  // - Auth -
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String oauthGoogle = '/auth/oauth/google';
  static const String oauthApple = '/auth/oauth/apple';
  static const String me = '/auth/me';

  // - Character -
  static const String characterMe = '/characters/me';
  static const String createCharacter = '/characters';
  static String character(String id) => '/characters/$id';

  // - Quests -
  static const String quests = '/quests';
  static String quest(String id) => '/quests/$id';
  static String completeQuest(String id) => '/quests/$id/complete';

  // - Skills -
  static const String skills = '/skills';
  static String skill(String id) => '/skills/$id';
  static String skillHistory(String id) => '/skills/$id/history';

  // - Bosses -
  static const String bosses = '/bosses';
  static String boss(String id) => '/bosses/$id';
  static String bossQuests(String id) => '/bosses/$id/quests';

  // - Achievements -
  static const String achievements = '/achievements';

  // - Economy -
  static const String inventory = '/inventory';
  static const String shop = '/shop/rewards';
  static String redeemReward(String id) => '/shop/rewards/$id/redeem';
  static const String goldLedger = '/economy/ledger';

  // - Streaks -
  static const String streak = '/streaks/me';

  // - Social -
  static const String guildMe = '/guilds/me';
  static String guild(String id) => '/guilds/$id';
  static String guildMessages(String id) => '/guilds/$id/messages';
  static String guildMissions(String id) => '/guilds/$id/missions';
  static String guildLeaderboard(String id) => '/guilds/$id/leaderboard';
  static const String pvpChallenges = '/pvp/challenges';
  static String pvpChallenge(String id) => '/pvp/challenges/$id';

  // - Insight -
  static const String statsSummary = '/stats/summary';
  static const String statsXpSeries = '/stats/xp-series';
  static const String coachSuggestions = '/coach/suggestions';

  // - Monetization -
  static const String battlePass = '/battle-pass/current';
  static String claimBattlePassTier(int tier) => '/battle-pass/claim/$tier';
  static const String subscription = '/billing/subscription';
  static const String checkout = '/billing/checkout';
}
