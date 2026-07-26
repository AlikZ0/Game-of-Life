import { NotFoundException } from '@nestjs/common';
import { SkillsService } from './skills.service';

/**
 * Skill read-side: the skill list (with derived level progress), a skill's XP
 * event history, and the per-day XP heatmap. Prisma is mocked.
 */
describe('SkillsService', () => {
  function build(opts: {
    character?: { id: string } | null;
    skills?: Array<Record<string, unknown>>;
    skill?: Record<string, unknown> | null;
    events?: Array<{ amount: number; createdAt: Date }>;
  }) {
    const prisma = {
      character: {
        findUnique: jest
          .fn()
          .mockResolvedValue(
            opts.character === undefined ? { id: 'c1' } : opts.character,
          ),
      },
      skill: {
        findMany: jest.fn().mockResolvedValue(opts.skills ?? []),
        findUnique: jest.fn().mockResolvedValue(opts.skill ?? null),
      },
      skillXpEvent: {
        findMany: jest.fn().mockResolvedValue(opts.events ?? []),
      },
    };
    return { service: new SkillsService(prisma as never), prisma };
  }

  describe('list', () => {
    it('throws NotFound when the user has no character', async () => {
      const { service } = build({ character: null });
      await expect(service.list('u1')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('maps skills with derived xpToNext + progress and serialized totalXp', async () => {
      const { service } = build({
        skills: [
          {
            id: 's1',
            key: 'fitness',
            name: 'Fitness',
            icon: 'dumbbell',
            color: '#f00',
            level: 1,
            xp: 0,
            totalXp: 300n,
          },
        ],
      });
      const [dto] = await service.list('u1');
      expect(dto).toMatchObject({
        id: 's1',
        key: 'fitness',
        level: 1,
        xp: 0,
        xpToNext: 100, // xpForLevel(1) = 100
        progress: 0,
        totalXp: '300',
      });
    });
  });

  describe('history', () => {
    it('404s for an unknown skill', async () => {
      const { service } = build({ skill: null });
      await expect(service.history('u1', 'ghost')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('returns the skill key with its recent events', async () => {
      const { service, prisma } = build({
        skill: { id: 's1', key: 'fitness' },
        events: [{ amount: 20, createdAt: new Date('2026-07-20') }],
      });
      const res = await service.history('u1', 'fitness', 30);
      expect(res.skillKey).toBe('fitness');
      expect(res.events).toHaveLength(1);
      expect(prisma.skillXpEvent.findMany).toHaveBeenCalledWith(
        expect.objectContaining({ where: { skillId: 's1' }, take: 30 }),
      );
    });
  });

  describe('heatmap', () => {
    it('buckets XP per day and sorts ascending', async () => {
      const { service } = build({
        events: [
          { amount: 10, createdAt: new Date('2026-07-20T08:00:00Z') },
          { amount: 15, createdAt: new Date('2026-07-20T20:00:00Z') },
          { amount: 5, createdAt: new Date('2026-07-19T12:00:00Z') },
        ],
      });
      const heatmap = await service.heatmap('u1', 30);
      expect(heatmap).toEqual([
        { date: '2026-07-19', xp: 5 },
        { date: '2026-07-20', xp: 25 },
      ]);
    });

    it('is empty when there are no events', async () => {
      const { service } = build({ events: [] });
      await expect(service.heatmap('u1')).resolves.toEqual([]);
    });
  });
});
