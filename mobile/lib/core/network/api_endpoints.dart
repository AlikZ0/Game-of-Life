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
  static const String oauthGoogle = '/auth/google';
  static const String oauthApple = '/auth/apple';
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
  static const String skillsHeatmap = '/skills/heatmap';
  static String skill(String id) => '/skills/$id';
  static String skillHistory(String key) => '/skills/$key/history';

  // - Bosses -
  static const String bosses = '/bosses';
  static String boss(String id) => '/bosses/$id';
  static String bossQuests(String id) => '/bosses/$id/quests';

  // - Achievements -
  static const String achievements = '/achievements';

  // - Economy -
  static const String inventory = '/inventory';
  static const String shop = '/shop';
  static String deleteReward(String id) => '/shop/$id';
  static String redeemReward(String id) => '/shop/$id/redeem';

  // - Streaks -
  static const String streak = '/streaks/me';

  // - Social -
  static const String createGuild = '/guilds';
  static String guild(String id) => '/guilds/$id';
  static String joinGuild(String id) => '/guilds/$id/join';
  static String leaveGuild(String id) => '/guilds/$id/leave';
  static String guildLeaderboard(String id) => '/guilds/$id/leaderboard';
  static String guildMessages(String id) => '/guilds/$id/messages';
  static String guildMissions(String id) => '/guilds/$id/missions';

  // - PvP -
  static const String pvpChallenges = '/pvp';
  static const String createPvp = '/pvp';
  static String acceptPvp(String id) => '/pvp/$id/accept';
  static String pvpStandings(String id) => '/pvp/$id/standings';

  // - Insight -
  static const String statsDashboard = '/stats/dashboard';
  static const String statsXpSeries = '/stats/xp-series';
  static const String statsLifeBalance = '/stats/life-balance';

  // - AI Coach -
  static const String coachAnalyze = '/ai-coach/analyze';
  static const String coachGenerate = '/ai-coach/generate-quests';

  // - Monetization -
  static const String battlePass = '/battle-pass/current';
  static String claimBattlePassTier(int tier) => '/battle-pass/claim/$tier';
  static const String subscription = '/subscription';
  static const String checkout = '/subscription/checkout';

  // - Notifications -
  static const String notificationsToken = '/notifications/token';
}
