/**
 * Shared contract for the gamification job queue, imported by both the API
 * (producer) and the worker (consumer) so neither has to import the other.
 */
export const GAMIFICATION_QUEUE = 'gamification';

export type GamificationJob =
  | { type: 'evaluate-achievements'; characterId: string }
  | { type: 'recompute-leaderboard'; guildId: string };
