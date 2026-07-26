import { Job } from 'bullmq';
import { ACHIEVEMENT_UNLOCKED_CHANNEL } from '../../modules/gamification/gamification.constants';
import { GamificationProcessor } from './gamification.processor';

describe('GamificationProcessor', () => {
  function build(unlocked: unknown[]) {
    const achievements = {
      evaluate: jest.fn().mockResolvedValue(unlocked),
    };
    const redis = { publish: jest.fn().mockResolvedValue(1) };
    const processor = new GamificationProcessor(
      achievements as never,
      redis as never,
    );
    return { processor, achievements, redis };
  }

  const job = (data: unknown) => ({ data }) as Job;

  it('publishes an unlock event when achievements are earned', async () => {
    const { processor, redis } = build([
      {
        id: 'first_boss',
        name: 'Giant Slayer',
        rarity: 'SILVER',
        icon: 'skull',
      },
    ]);

    await processor.process(
      job({ type: 'evaluate-achievements', characterId: 'char_1' }),
    );

    expect(redis.publish).toHaveBeenCalledTimes(1);
    const [channel, payload] = redis.publish.mock.calls[0];
    expect(channel).toBe(ACHIEVEMENT_UNLOCKED_CHANNEL);
    expect(JSON.parse(payload)).toMatchObject({
      characterId: 'char_1',
      achievements: [expect.objectContaining({ id: 'first_boss' })],
    });
  });

  it('does not publish when nothing was unlocked', async () => {
    const { processor, redis } = build([]);
    await processor.process(
      job({ type: 'evaluate-achievements', characterId: 'char_1' }),
    );
    expect(redis.publish).not.toHaveBeenCalled();
  });
});
