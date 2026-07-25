import { PrismaClient, Prisma } from '@prisma/client';
import { ACHIEVEMENT_CATALOG } from '../src/modules/achievements/domain/achievement-catalog';

const prisma = new PrismaClient();

const SEASON_ID = 'season_genesis';
const SEASON_TIERS = 30;

/** Seed / re-seed reference data. Idempotent via upserts, safe to run anytime. */
async function main() {
  // ── Achievements ─────────────────────────────────────────
  for (const def of ACHIEVEMENT_CATALOG) {
    await prisma.achievement.upsert({
      where: { id: def.id },
      update: {
        name: def.name,
        description: def.description,
        rarity: def.rarity,
        icon: def.icon,
        category: def.category,
        rewardXp: def.rewardXp,
        rewardGold: def.rewardGold,
        criteria: def.criteria as unknown as Prisma.InputJsonValue,
        isSecret: def.isSecret ?? false,
      },
      create: {
        id: def.id,
        name: def.name,
        description: def.description,
        rarity: def.rarity,
        icon: def.icon,
        category: def.category,
        rewardXp: def.rewardXp,
        rewardGold: def.rewardGold,
        criteria: def.criteria as unknown as Prisma.InputJsonValue,
        isSecret: def.isSecret ?? false,
      },
    });
  }

  // ── Active season ────────────────────────────────────────
  const now = new Date();
  const endAt = new Date(now.getTime() + 90 * 86400000); // ~3-month season
  await prisma.season.upsert({
    where: { id: SEASON_ID },
    update: { isActive: true, endAt },
    create: {
      id: SEASON_ID,
      name: 'Genesis Season',
      startAt: now,
      endAt,
      isActive: true,
    },
  });

  // ── Battle Pass tiers (growing xpRequired) ───────────────
  for (let tier = 1; tier <= SEASON_TIERS; tier++) {
    // Cumulative XP grows super-linearly so later tiers take longer to reach.
    const xpRequired = Math.floor(500 * Math.pow(tier, 1.4));
    const freeReward: Prisma.InputJsonValue =
      tier % 5 === 0
        ? { type: 'gold', amount: 100 * tier }
        : { type: 'xp', amount: 50 * tier };
    const premiumReward: Prisma.InputJsonValue = { type: 'gold', amount: 200 * tier };

    await prisma.battlePassTier.upsert({
      where: { seasonId_tier: { seasonId: SEASON_ID, tier } },
      update: { xpRequired, freeReward, premiumReward },
      create: { seasonId: SEASON_ID, tier, xpRequired, freeReward, premiumReward },
    });
  }

  const achievementCount = await prisma.achievement.count();
  const tierCount = await prisma.battlePassTier.count({
    where: { seasonId: SEASON_ID },
  });

  // eslint-disable-next-line no-console
  console.log(
    `✅ Seed complete — ${achievementCount} achievements, season "${SEASON_ID}" with ${tierCount} battle-pass tiers.`,
  );
}

main()
  .catch((err) => {
    // eslint-disable-next-line no-console
    console.error('❌ Seed failed:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
