/**
 * Shared contract for the gamification job queue, imported by both the API
 * (producer) and the worker (consumer) so neither has to import the other.
 */
export const GAMIFICATION_QUEUE = 'gamification';

export type GamificationJob =
  | { type: 'evaluate-achievements'; characterId: string }
  | { type: 'recompute-leaderboard'; guildId: string };

/**
 * Redis pub/sub channel used to bridge worker-side events back to the API's
 * WebSocket layer. The worker process holds no socket connections, so when it
 * unlocks achievements it publishes here; the API subscribes and emits the
 * toast to the player's character room.
 */
export const ACHIEVEMENT_UNLOCKED_CHANNEL = 'events:achievement-unlocked';

export interface AchievementUnlockedEvent {
  characterId: string;
  achievements: Array<{
    id: string;
    name: string;
    rarity: string;
    icon: string;
  }>;
}
