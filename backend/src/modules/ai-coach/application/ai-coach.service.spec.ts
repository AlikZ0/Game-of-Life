import { AiCoachService } from './ai-coach.service';

describe('AiCoachService.analyze', () => {
  function build(opts: {
    premium: boolean;
    llmEnabled: boolean;
    llmText?: string;
  }) {
    const stats = {
      lifeBalance: jest.fn().mockResolvedValue([
        { key: 'programming', name: 'Programming', neglected: false },
        { key: 'fitness', name: 'Fitness', neglected: true },
      ]),
      dashboard: jest.fn().mockResolvedValue({
        level: 5,
        currentStreak: 3,
        questsCompleted30d: 12,
      }),
      xpSeries: jest.fn().mockResolvedValue([{ date: '2026-07-25', xp: 100 }]),
    };
    const subscriptions = {
      isPremium: jest.fn().mockResolvedValue(opts.premium),
    };
    const llm = {
      enabled: opts.llmEnabled,
      complete: jest.fn().mockResolvedValue(opts.llmText ?? null),
    };
    return {
      service: new AiCoachService(
        stats as never,
        subscriptions as never,
        llm as never,
      ),
      llm,
    };
  }

  it('does not call the LLM for a free user', async () => {
    const { service, llm } = build({ premium: false, llmEnabled: true });
    const res = await service.analyze('u1');
    expect(llm.complete).not.toHaveBeenCalled();
    expect(res.premium).toBe(false);
    expect(res.weakAreas).toContain('Fitness');
  });

  it('does not call the LLM when the provider is unconfigured', async () => {
    const { service, llm } = build({ premium: true, llmEnabled: false });
    await service.analyze('u1');
    expect(llm.complete).not.toHaveBeenCalled();
  });

  it('enriches the summary via the LLM for a Premium user', async () => {
    const { service, llm } = build({
      premium: true,
      llmEnabled: true,
      llmText: 'You are crushing it — keep that 3-day streak alive!',
    });
    const res = await service.analyze('u1');
    expect(llm.complete).toHaveBeenCalledTimes(1);
    expect(res.summary).toBe(
      'You are crushing it — keep that 3-day streak alive!',
    );
  });

  it('falls back to the rule-based summary when the LLM returns nothing', async () => {
    const { service } = build({
      premium: true,
      llmEnabled: true,
      llmText: undefined,
    });
    const res = await service.analyze('u1');
    expect(res.summary).toContain('12 quests');
  });
});
