import { AchievementUnlockedEvent } from '../gamification/gamification.constants';
import { AchievementRealtimeBridge } from './achievement-realtime.bridge';

describe('AchievementRealtimeBridge.onMessage', () => {
  function build() {
    const gateway = { emitAchievementUnlocked: jest.fn() };
    const redis = { duplicate: jest.fn() };
    const bridge = new AchievementRealtimeBridge(
      redis as never,
      gateway as never,
    );
    return { bridge, gateway };
  }

  const event: AchievementUnlockedEvent = {
    characterId: 'char_1',
    achievements: [
      {
        id: 'first_boss',
        name: 'Giant Slayer',
        rarity: 'SILVER',
        icon: 'skull',
      },
    ],
  };

  it('emits a toast to the character room for a valid event', () => {
    const { bridge, gateway } = build();
    bridge.onMessage(JSON.stringify(event));
    expect(gateway.emitAchievementUnlocked).toHaveBeenCalledWith(
      'char_1',
      expect.objectContaining({
        achievements: expect.arrayContaining([
          expect.objectContaining({ id: 'first_boss' }),
        ]),
      }),
    );
  });

  it('ignores malformed JSON', () => {
    const { bridge, gateway } = build();
    bridge.onMessage('{not json');
    expect(gateway.emitAchievementUnlocked).not.toHaveBeenCalled();
  });

  it('ignores events with no achievements', () => {
    const { bridge, gateway } = build();
    bridge.onMessage(JSON.stringify({ characterId: 'c', achievements: [] }));
    expect(gateway.emitAchievementUnlocked).not.toHaveBeenCalled();
  });
});
