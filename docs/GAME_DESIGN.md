# 🎮 Life Quest — Game Design Bible

> The single source of truth for economy, progression math, and systems.
> All numbers, enums, and reward reasons are aligned with
> [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma). When the code and this
> doc disagree, the schema wins and this doc must be corrected.

**Related docs:** [Wireframes](WIREFRAMES.md) · [Roadmap](ROADMAP.md) · [Deployment](DEPLOYMENT.md)

---

## 1. Design Pillars

Life Quest is built on three load-bearing pillars. Every mechanic below must serve at
least one, and must never violate the "addictive but healthy" guardrail.

### Pillar A — Addictive but Healthy

We want retention that comes from **genuine life improvement**, not compulsion loops.

| Mechanic | Healthy purpose | Anti-pattern we explicitly reject |
|----------|-----------------|-----------------------------------|
| **Energy system** (`Character.energy` / `maxEnergy`) | Soft daily cap; prevents grind-to-exhaustion and rewards recovery/sleep | ❌ No pay-to-refill spam, no punishing energy paywall |
| **Streak freezes** (`ItemType.CONSUMABLE_STREAK_FREEZE`, `Streak.freezeCount`) | Forgives a missed day so one slip doesn't erase months | ❌ No "streak anxiety" dark patterns / no loss-only framing |
| **No FOMO timers on core loop** | Daily quests roll on the user's own schedule (`periodKey`, user tz) | ❌ No countdown pressure to open the app *right now* |
| **Downtime is fine** | HP/energy regenerate; streak freezes bank | ❌ No decay that punishes intentional rest days |
| **Transparent odds** | No loot boxes with hidden RNG on paid currency | ❌ No gambling mechanics; cosmetics are directly purchasable |

### Pillar B — Meaningful Progress

Progress must feel *earned and legible*. Exponential XP curves, visible skill levels,
boss HP bars, and streak milestones give constant "one more step" clarity without ever
feeling grindy at low levels.

### Pillar C — Real-Life Transfer

The game is a **wrapper around real behavior change**. Skills map to real domains
(fitness, finance, study). Bosses are real goals. Shop rewards are user-defined real-life
treats (`ShopReward.title` e.g. "1h gaming"). The win condition is a better life, not a
higher number.

---

## 2. Level System (Character Progression)

### 2.1 The Formula

Character level uses a smooth exponential curve. **`xpForLevel(n)` is the XP required to
advance _from_ level `n` _to_ level `n+1`:**

```
xpForLevel(n) = floor(BASE * n^EXP)      with BASE = 100, EXP = 1.5
```

`n^1.5 = n * sqrt(n)`, so the cost grows super-linearly but never explodes the way a pure
geometric `BASE * r^n` curve does. This keeps early levels fast (dopamine-friendly
onboarding) and late levels aspirational without becoming a second job.

> **Clean geometric alternative** (documented, not used): `xpForLevel(n) = floor(100 * 1.12^(n-1))`.
> Rejected because `1.12^n` overtakes the polynomial curve after ~L45 and makes level 60+
> feel unreachable for a life app. We keep the polynomial `n^1.5`.

`Character.xp` stores XP **within the current level**; `Character.totalXp` (BigInt) stores
lifetime XP. On completion the engine adds reward XP to `xp`; while
`xp >= xpForLevel(level)` it subtracts and increments `level` (handles multi-level-ups).

### 2.2 XP Table, Levels 1–30

`cumToReach(L)` = total lifetime XP needed to *be* level `L` = Σ `xpForLevel(1..L-1)`.

| Lvl | XP for this level | Cumulative XP to reach | Lvl | XP for this level | Cumulative XP to reach |
|----:|------------------:|-----------------------:|----:|------------------:|-----------------------:|
| 1  | 100    | 0      | 16 | 6,400  | 37,802  |
| 2  | 282    | 100    | 17 | 7,009  | 44,202  |
| 3  | 519    | 382    | 18 | 7,636  | 51,211  |
| 4  | 800    | 901    | 19 | 8,281  | 58,847  |
| 5  | 1,118  | 1,701  | 20 | 8,944  | 67,128  |
| 6  | 1,469  | 2,819  | 21 | 9,623  | 76,072  |
| 7  | 1,852  | 4,288  | 22 | 10,318 | 85,695  |
| 8  | 2,262  | 6,140  | 23 | 11,030 | 96,013  |
| 9  | 2,700  | 8,402  | 24 | 11,757 | 107,043 |
| 10 | 3,162  | 11,102 | 25 | 12,500 | 118,800 |
| 11 | 3,648  | 14,264 | 26 | 13,257 | 131,300 |
| 12 | 4,156  | 17,912 | 27 | 14,029 | 144,557 |
| 13 | 4,687  | 22,068 | 28 | 14,816 | 158,586 |
| 14 | 5,238  | 26,755 | 29 | 15,616 | 173,402 |
| 15 | 5,809  | 31,993 | 30 | 16,431 | 189,018 |

**Reality check:** A committed user completing ~4 MEDIUM quests/day earns ~80 XP/day →
level ~7 in the first week, level ~15 in ~2 months. That pacing keeps the first month
rich with level-ups (retention) while endgame (L25+) is a months-long badge of honor.

### 2.3 Level-Up Effects

On each level gained the gamification engine applies:

| Effect | Formula / Rule | Schema field |
|--------|----------------|--------------|
| **Max HP growth** | `maxHp = 100 + (level-1) * 10` | `Character.maxHp` |
| **Max Energy growth** | `maxEnergy = 100 + floor((level-1)/2) * 5` | `Character.maxEnergy` |
| **Full heal + refill** | `hp = maxHp`, `energy = maxEnergy` on level-up | `Character.hp`, `energy` |
| **Title unlocks** | Milestone titles at L5/10/20/30 (see below) | `Character.activeTitle`, `ItemType.TITLE` |
| **Cosmetic drops** | Frame/avatar unlock at L10/20/30 | `ItemType.COSMETIC_*` in `InventoryItem` |
| **Feature unlocks** | Gated below | — |

**Feature unlock gates** (reduce first-run overwhelm, teach one system at a time):

| Level | Unlocks |
|------:|---------|
| 1 | Daily quests, skills, HP/energy |
| 3 | Bosses (big goals) |
| 5 | Shop + inventory, first title ("Initiate") |
| 8 | Achievements gallery fully open, Battle Pass |
| 10 | Guilds, title "Adept", first cosmetic frame |
| 15 | PvP challenges |
| 20 | AI Coach long-term prediction, title "Champion" |
| 30 | Prestige cosmetics, title "Legend" |

**Milestone titles:** L5 *Initiate* · L10 *Adept* · L20 *Champion* · L30 *Legend*
(delivered as `InventoryItem` of `ItemType.TITLE`; equipping sets `Character.activeTitle`).

---

## 3. Difficulty → Reward Multipliers

`Quest.xpReward` / `goldReward` / `energyCost` store **base** values (schema defaults
20 / 10 / 10). At completion the engine scales them by the quest's `Difficulty`. The
scaled amounts are frozen into `QuestCompletion.xpAwarded` / `goldAwarded` (audit trail).

| Difficulty | XP × | Gold × | Energy cost × | Example (base 20/10/10) → XP / Gold / Energy |
|------------|:----:|:------:|:-------------:|:---------------------------------------------|
| `TRIVIAL`  | 0.5  | 0.5    | 0.5           | 10 / 5 / 5   |
| `EASY`     | 0.75 | 0.75   | 0.75          | 15 / 8 / 8   |
| `MEDIUM`   | 1.0  | 1.0    | 1.0           | 20 / 10 / 10 |
| `HARD`     | 1.75 | 1.5    | 1.5           | 35 / 15 / 15 |
| `EPIC`     | 3.0  | 2.5    | 2.0           | 60 / 25 / 20 |

Design intent: **XP scales faster than gold** so hard work advances your *character*
more than your *wallet* (keeps the economy from inflating on difficulty alone). Energy
cost scales sub-linearly so EPIC quests are attractive, not prohibitive.

> Cadence bonus (applied after difficulty): `WEEKLY` ×1.5, `MONTHLY` ×2.5 on XP+gold,
> reflecting the larger commitment. `DAILY` / `ONE_OFF` ×1.0.

---

## 4. Skill XP System

8 seed skills (`Skill.key`): `programming · fitness · reading · english · business ·
finance · leadership · discipline`. Each has its own level, XP, and history.

### 4.1 How quests grant skill XP

A quest may point at one skill via `Quest.skillKey`. On completion:

```
skillXpGranted = round(xpAwarded * 0.5)   // half the character XP flows to the skill
```

The engine writes a `SkillXpEvent { skillId, amount, source: questId }` and rolls up
`Skill.xp` / `Skill.totalXp`, leveling the skill when the per-skill threshold is met.
`source = "manual"` is reserved for admin/coach-granted adjustments.

### 4.2 Per-skill leveling curve

Skills use the **same shape, half the cost** of the character curve (they should climb
faster — a skill is narrower than the whole self):

```
skillXpForLevel(n) = floor(50 * n^1.5)     // BASE = 50, EXP = 1.5
```

| Skill Lvl | XP for level | | Skill Lvl | XP for level |
|----------:|-------------:|-|----------:|-------------:|
| 1 | 50   | | 6  | 734   |
| 2 | 141  | | 8  | 1,131 |
| 3 | 259  | | 10 | 1,581 |
| 4 | 400  | | 15 | 2,904 |
| 5 | 559  | | 20 | 4,472 |

### 4.3 Heatmap concept

`SkillXpEvent.createdAt` powers a GitHub-style contribution heatmap per skill and an
aggregate "consistency" heatmap on the Stats screen. Each cell = one calendar day;
intensity = Σ `amount` that day, bucketed into 5 shades of the skill's `Skill.color`.
Indexed by `@@index([skillId, createdAt])` for fast range queries. This visualizes
**real-life transfer** — you can literally see the months you invested in fitness vs
finance.

---

## 5. Gold Economy

Gold (`Character.gold`) is the **soft currency**. It is *earned by doing life* and *spent
on real-life rewards you define for yourself* — a deliberately closed, self-honest loop.
Every movement is double-entry via `GoldLedgerEntry { delta, balance, reason, refId }`.

### 5.1 Sources & Sinks

| Sources (`delta > 0`) | `LedgerReason` | Sinks (`delta < 0`) | `LedgerReason` |
|-----------------------|----------------|---------------------|----------------|
| Quest completion | `QUEST_REWARD` | Buying a self-defined `ShopReward` | `SHOP_PURCHASE` |
| Boss defeat | `BOSS_REWARD` | Buying cosmetics/consumables (in-app store) | `SHOP_PURCHASE` |
| Achievement unlock | `ACHIEVEMENT_REWARD` | — | — |
| Streak milestone | `STREAK_MILESTONE` | — | — |
| Battle Pass tier | `BATTLE_PASS` | — | — |
| PvP win | `PVP_REWARD` | — | — |
| Support/refund | `ADMIN_ADJUSTMENT` | Support clawback | `ADMIN_ADJUSTMENT` |

### 5.2 Ledger invariant & inflation control

- **Invariant:** after every entry, `balance == previous.balance + delta`, and
  `Character.gold == latest ledger balance`. The write is transactional with the reward.
- **Idempotency:** rewards key off `QuestCompletion` uniqueness (`@@unique([questId, periodKey])`),
  so a double-tap can never double-pay.
- **Inflation control:** because the *only meaningful sink is user-defined real rewards*,
  gold can't runaway-inflate against a fixed shop. To keep it psychologically weighty we:
  1. Keep gold rewards flat-ish across difficulty (§3) — you can't farm gold by cranking difficulty.
  2. Recommend Shop reward pricing in the same order of magnitude as ~1 week of quests
     (the UI suggests a `goldCost` when a user creates a `ShopReward`).
  3. Cosmetic/consumable store prices are tuned to ~3–14 days of play (see §11 pricing).

### 5.3 Example ledger

| createdAt | delta | balance | reason | refId |
|-----------|------:|--------:|--------|-------|
| 09:00 | +10 | 10  | `QUEST_REWARD` | cmpl_a1 |
| 09:05 | +15 | 25  | `QUEST_REWARD` | cmpl_a2 |
| 12:00 | +50 | 75  | `STREAK_MILESTONE` (day 7) | strk_7 |
| 20:00 | −60 | 15  | `SHOP_PURCHASE` ("1h gaming") | shop_x |
| 23:00 | +250 | 265 | `BOSS_REWARD` | boss_z |

---

## 6. Boss Math (Big Goals as HP Bars)

A `Boss` is a real long-term goal. Linked `Quest`s deal `Quest.damage` to `currentHp` on
each completion. When `currentHp <= 0`: `status → DEFEATED`, `defeatedAt` set, rewards paid.

### 6.1 Sizing HP vs quest damage

Core identity we design around:

```
expectedTimeToDefeat (days) ≈ maxHp / (Σ linkedQuests.damage per day)
```

Default quest `damage = 10`. Recommended `damage` by difficulty (mirrors effort):
TRIVIAL 5 · EASY 8 · MEDIUM 12 · HARD 20 · EPIC 35.

**Recommended boss HP per goal size** (assuming 1–3 linked daily quests):

| Goal size | Example | Suggested `maxHp` | Typical linked quests | Est. time |
|-----------|---------|------------------:|-----------------------|-----------|
| Sprint | "Finish course module" | 300 | 1× MEDIUM daily (12/day) | ~3–4 wks |
| Medium | "Run a 10K" | 750 | 2× daily (~30/day) | ~4 wks |
| Large | "Ship side project" | 2,500 | 2–3× mixed (~60/day) | ~6 wks |
| Epic | "Get promoted / lose 15kg" | 6,000+ | 3× incl. HARD/EPIC (~90/day) | ~2–3 mos |

The Boss-create sheet suggests `maxHp` from the chosen size and the deadline: it
back-solves `maxHp = deadlineDays × plannedDailyDamage` so the bar is *beatable on
schedule*. `currentHp` initializes to `maxHp`.

### 6.2 Reward scaling

```
rewardXp   = round(maxHp * 1.0)     // schema default 500 ↔ a 500-HP boss
rewardGold = round(maxHp * 0.5)     // schema default 250
```

Optional `rewardItemId` grants a cosmetic/title on defeat (great for Epic bosses). Boss
rewards are the **largest single XP injections** in the game — defeating an Epic boss can
jump a mid-game character an entire level, which is the intended catharsis.

### 6.3 Deadlines

`Boss.deadline` is motivational, not punitive (Pillar A). If missed, the boss stays
`ACTIVE` (no XP/gold penalty) but the UI nudges: *"Reschedule or downscale?"*. Users may
set `status → ABANDONED` guilt-free. Overdue bosses feed the AI Coach's "over-scoping"
detection (§10).

---

## 7. Achievements

`Achievement` rows are static, seeded catalog entries keyed by a stable slug (e.g.
`first_blood`). `CharacterAchievement.progress` (0..1) tracks tiered progress;
`unlockedAt` marks completion. `criteria` is a machine-readable JSON rule evaluated by the
achievement engine on relevant domain events.

### 7.1 Tier rarities

Rarity = the 4 `Rarity` enum values, mapped to escalating reward + prestige:

| `Rarity` | Meaning | Typical `rewardXp` / `rewardGold` | Color |
|----------|---------|-----------------------------------|-------|
| `BRONZE` | First steps / common | 50 / 25 | `#CD7F32` |
| `SILVER` | Consistent effort | 150 / 75 | `#C0C0C0` |
| `GOLD` | Major milestone | 500 / 250 | `#FFD700` |
| `LEGENDARY` | Elite / long-haul / secret | 2,000 / 1,000 | `#B14CFF` |

### 7.2 How we reach "hundreds": tiered families

Instead of hand-authoring 400 achievements, we define **tiered families**. Each family is
one behavioral axis instantiated at multiple thresholds, auto-escalating in rarity. One
`criteria` shape `{ "type": "counter", "metric": "...", "threshold": N }` powers all tiers.

Example family — **"Questmaster"** (`Complete N quests`): thresholds `10 / 50 / 100 / 500 /
1000` → rarities `BRONZE / SILVER / SILVER / GOLD / LEGENDARY`. That's 5 achievements from
one definition. ~30 families × ~5 tiers ≈ **150+ tiered** achievements, plus ~40 bespoke
"moment" achievements (secret/meta) = **~200 shipped**, scaling to hundreds as families are
added — no engine changes required.

### 7.3 Example catalog (40+)

Reward columns show XP/Gold. `criteria.type`: `counter` (cumulative), `streak`, `event`
(one-shot), `threshold` (reach a value).

**Quests (category `quests`)**

| Slug | Name | Rarity | Criteria | XP/Gold |
|------|------|--------|----------|--------:|
| `first_blood` | First Blood | BRONZE | complete 1st quest | 50/25 |
| `questmaster_10` | Apprentice | BRONZE | 10 quests | 50/25 |
| `questmaster_50` | Journeyman | SILVER | 50 quests | 150/75 |
| `questmaster_100` | Questmaster | SILVER | 100 quests | 150/75 |
| `questmaster_500` | Grandmaster | GOLD | 500 quests | 500/250 |
| `questmaster_1000` | Mythic | LEGENDARY | 1,000 quests | 2000/1000 |
| `perfect_day` | Perfect Day | BRONZE | all daily quests in one day | 50/25 |
| `perfect_week` | Flawless Week | GOLD | 7 perfect days in a row | 500/250 |
| `early_bird` | Early Bird | BRONZE | complete a quest before 7am | 50/25 |
| `night_owl` | Night Owl | BRONZE | complete a quest after 11pm (secret) | 50/25 |
| `epic_slayer` | Epic Slayer | SILVER | complete 25 EPIC-difficulty quests | 150/75 |

**Skills (category `skills`)**

| Slug | Name | Rarity | Criteria | XP/Gold |
|------|------|--------|----------|--------:|
| `skill_up_5` | Getting Good | BRONZE | any skill → level 5 | 50/25 |
| `skill_up_10` | Specialist | SILVER | any skill → level 10 | 150/75 |
| `skill_up_20` | Virtuoso | GOLD | any skill → level 20 | 500/250 |
| `renaissance` | Renaissance Soul | GOLD | all 8 skills → level 5 | 500/250 |
| `polymath` | Polymath | LEGENDARY | all 8 skills → level 15 | 2000/1000 |
| `iron_body` | Iron Body | SILVER | fitness skill → level 10 | 150/75 |
| `bookworm` | Bookworm | SILVER | reading skill → level 10 | 150/75 |
| `code_ninja` | Code Ninja | SILVER | programming skill → level 10 | 150/75 |

**Streaks (category `streaks`)**

| Slug | Name | Rarity | Criteria | XP/Gold |
|------|------|--------|----------|--------:|
| `streak_3` | Warming Up | BRONZE | 3-day streak | 50/25 |
| `streak_7` | On Fire | BRONZE | 7-day streak | 50/25 |
| `streak_30` | Unstoppable | SILVER | 30-day streak | 150/75 |
| `streak_100` | Centurion | GOLD | 100-day streak | 500/250 |
| `streak_365` | Year of Power | LEGENDARY | 365-day streak | 2000/1000 |
| `comeback` | Comeback Kid | BRONZE | rebuild a 7-streak after a break (secret) | 50/25 |

**Social (category `social`)**

| Slug | Name | Rarity | Criteria | XP/Gold |
|------|------|--------|----------|--------:|
| `guild_join` | Fellowship | BRONZE | join a guild | 50/25 |
| `guild_founder` | Founder | SILVER | create a guild | 150/75 |
| `mission_hero` | Mission Hero | SILVER | contribute to 10 guild missions | 150/75 |
| `pvp_first_win` | First Victory | BRONZE | win a PvP challenge | 50/25 |
| `pvp_10_wins` | Duelist | SILVER | 10 PvP wins | 150/75 |
| `pvp_50_wins` | Gladiator | GOLD | 50 PvP wins | 500/250 |
| `chatterbox` | Chatterbox | BRONZE | send 100 guild messages | 50/25 |

**Economy (category `economy`)**

| Slug | Name | Rarity | Criteria | XP/Gold |
|------|------|--------|----------|--------:|
| `first_gold` | Payday | BRONZE | earn first 100 gold | 50/25 |
| `saver_1k` | Saver | SILVER | hold 1,000 gold at once | 150/75 |
| `high_roller` | High Roller | GOLD | earn 50,000 lifetime gold | 500/250 |
| `treat_yourself` | Treat Yourself | BRONZE | redeem your first Shop reward | 50/25 |
| `boss_slayer_1` | Giant Slayer | BRONZE | defeat 1st boss | 50/25 |
| `boss_slayer_10` | Titan Slayer | SILVER | defeat 10 bosses | 150/75 |
| `boss_slayer_epic` | Worldbreaker | LEGENDARY | defeat an Epic (6000+ HP) boss | 2000/1000 |

**Meta (category `meta`)**

| Slug | Name | Rarity | Criteria | XP/Gold |
|------|------|--------|----------|--------:|
| `level_10` | Double Digits | BRONZE | reach character level 10 | 50/25 |
| `level_20` | Ascendant | SILVER | reach character level 20 | 150/75 |
| `level_30` | Legend | GOLD | reach character level 30 | 500/250 |
| `battle_pass_max` | Season Champion | GOLD | max a Battle Pass season | 500/250 |
| `collector` | Collector | SILVER | own 20 cosmetics | 150/75 |
| `completionist` | Completionist | LEGENDARY | unlock 100 achievements | 2000/1000 |
| `og` | Day One | LEGENDARY | account created in launch month (secret) | 2000/1000 |

> That's 45 concrete achievements across all 6 categories; the tiered families (§7.2) fan
> these out to hundreds.

---

## 8. Streaks

`Streak.current` increments once per day the user completes ≥1 quest (keyed to
`lastActiveDay` in the user's timezone, `YYYY-MM-DD`). `Streak.longest` tracks the record.

### 8.1 Milestone rewards

Paid via `LedgerReason.STREAK_MILESTONE` (gold) + XP; big milestones also drop a
`CONSUMABLE_STREAK_FREEZE` so consistency literally buys forgiveness.

| Milestone (days) | Gold | XP | Bonus | Achievement |
|-----------------:|-----:|---:|-------|-------------|
| 3   | 15   | 30   | — | `streak_3` |
| 7   | 50   | 100  | +1 streak freeze | `streak_7` |
| 14  | 120  | 250  | +1 freeze | — |
| 30  | 300  | 600  | +2 freezes, cosmetic frame | `streak_30` |
| 60  | 700  | 1,400 | +2 freezes | — |
| 100 | 1,500 | 3,000 | Gold title "Centurion" | `streak_100` |
| 365 | 6,000 | 12,000 | Legendary title + exclusive avatar | `streak_365` |

### 8.2 Freeze mechanics

- A missed day first consumes one `Streak.freezeCount` (if > 0): the streak **holds**,
  `lastActiveDay` advances, no reward, no penalty.
- With 0 freezes, a missed day resets `current → 0` (longest is preserved).
- Freezes are earned (milestones, Battle Pass) or bought
  (`ItemType.CONSUMABLE_STREAK_FREEZE`, ~40 gold). Cap: **hold 5**, auto-consume oldest
  first. No stacking abuse — you can't buy your way to a fake 365.
- **Healthy framing (Pillar A):** the UI says "Freeze used — rest is part of the journey,"
  never "You almost lost everything!"

---

## 9. Battle Pass

Seasonal, ~8–10 week `Season` with 50 `BattlePassTier`s. Two tracks per tier
(`freeReward`, `premiumReward` JSON `{ type, refKey, amount }`).
`BattlePassProgress` tracks `xp`, `tier`, `isPremium`, and `claimedTiers[]`.

### 9.1 Tier XP curve

```
tierXpRequired(t) = 500 + (t-1) * 50     // linear, tier 1 = 500 … tier 50 = 2950
totalSeasonXp ≈ 86,250 over the season
```

Battle Pass XP is a **separate meter** fed by the same actions as character XP
(quest/boss/streak completions) so it never competes with core progression — you advance
both at once.

### 9.2 Free vs Premium tracks

| | Free track | Premium track (+Free) |
|---|-----------|----------------------|
| Tiers with rewards | ~20 of 50 | all 50 |
| Rewards | gold, streak freezes, 1 seasonal frame | + exclusive avatar/theme/title, energy potions, 2× gold nodes |
| Seasonal XP boost | — | +10% Battle Pass XP |
| Cost | included | one-time seasonal unlock OR bundled with Premium sub (§11) |

Premium is retroactive: buying mid-season instantly claims all earned premium tiers.
**No pay-to-win** — Battle Pass rewards are cosmetics + convenience, never permanent power.

---

## 10. PvP

`PvpChallenge`: 1v1, a chosen `PvpMetric`, a time window (`startAt`→`endAt`), scores, and
`winnerId`. `PvpStatus`: `PENDING → ACTIVE → FINISHED` (or `CANCELLED`).

### 10.1 The 5 metrics

Exactly the `PvpMetric` enum:

| `PvpMetric` | What's counted | Data source |
|-------------|----------------|-------------|
| `XP` | XP earned in window | `QuestCompletion.xpAwarded` sum |
| `QUESTS_COMPLETED` | # completions in window | `QuestCompletion` count |
| `STUDY_MINUTES` | timer minutes on study skills | `CompletionSource.TIMER` + skill tag |
| `WORKOUT_MINUTES` | timer minutes on fitness | `CompletionSource.TIMER` + fitness |
| `STEPS` | steps in window | `CompletionSource.INTEGRATION` (HealthKit/Google Fit) |

### 10.2 Weekly cadence & scoring

- Default challenge window = **1 week** (Mon 00:00 → Sun 23:59, challenger's tz).
- Scores accrue live into `challengerScore` / `opponentScore` as events land.
- On `endAt`, worker finalizes: higher score → `winnerId`; ties → both get participation
  gold, no win recorded. Winner gets `LedgerReason.PVP_REWARD` (scaled to metric, capped).
- Same engine drives **guild leaderboards** (`GuildMember.weeklyXp`, reset weekly) and
  `GuildMission` progress (shared `PvpMetric`).

### 10.3 Anti-cheat

| Vector | Mitigation |
|--------|------------|
| Self-completing fake quests to farm XP | PvP `XP`/`QUESTS_COMPLETED` weighted by difficulty & energy spent; abnormal velocity flagged |
| Timer abuse (start-and-walk-away) | `TIMER` sessions capped/day; require foreground; sanity-cap minutes/session |
| Steps spoofing | `INTEGRATION` only from signed HealthKit/Fit payloads; reject manual entry for PvP |
| Timezone shifting to double-count | Window pinned to challenger tz at `startAt`; `periodKey` idempotency |
| Collusion (trade wins) | Rate-limit challenges/pair/week; ranked matchmaking discounts repeat opponents |

---

## 11. AI Coach

An LLM-assisted layer (unlocked feature, premium-gated deep features — §12) that turns the
user's history into guidance. It **reads aggregates, never raw PII beyond the app**, and
outputs structured suggestions the user approves before anything is created.

### 11.1 What it analyzes

- Quest completion patterns (`QuestCompletion.completedAt`, `periodKey`) — time-of-day,
  weekday dips, abandonment.
- Skill `SkillXpEvent` heatmaps → neglected vs over-indexed domains.
- Boss health trajectories → over-scoping / stalled goals (`Boss.currentHp` velocity).
- Streak stability & freeze usage.
- Energy patterns → burnout risk (chronically low `energy`).

### 11.2 What it outputs

| Output | Description | Lands as |
|--------|-------------|----------|
| **Personalized quests** | Suggested `Quest` drafts targeting weak areas (right difficulty/skillKey) | pre-filled Quest Create sheet |
| **Weak-area detection** | "Your `finance` skill hasn't moved in 3 weeks" | Coach card + suggested quest |
| **Routine suggestions** | Ideal daily schedule from your best completion windows | routine template |
| **Long-term prediction** | "At this pace you'll hit level 20 by Sept and defeat *Marathon* on time" | trajectory chart (L20+ feature) |
| **Burnout guardrail** | Detects over-loading; suggests a rest day, protects streak with a freeze | gentle nudge (Pillar A) |

### 11.3 High-level prompt/data design

- **Input:** a compact, privacy-safe JSON *feature snapshot* (rolling 30/90-day
  aggregates — counts, skill deltas, streak, energy avg, boss velocities). No emails, no
  message bodies.
- **System prompt:** frames the model as a *supportive, non-judgmental coach* bound to
  Pillar A — never guilt, never engagement-maxxing, always suggests healthy load.
- **Output contract:** strict JSON (`suggestedQuests[]`, `insights[]`, `prediction`) so
  the app renders native UI and nothing is auto-applied without user confirmation.
- **Guardrails:** rule-based caps wrap the model (max suggested daily load, mandatory rest
  suggestion if energy trend is low). The model advises; deterministic code enforces limits.

---

## 12. Monetization

`Subscription` (`SubscriptionTier` FREE/PREMIUM, `SubscriptionStatus`,
`BillingProvider` STRIPE/APPLE_IAP/GOOGLE_PLAY). **Premium is a subscription; the game is
never pay-to-win.** We monetize *depth, insight, and cosmetics* — not power or the core
loop.

### 12.1 Feature matrix

| Feature | Free | Premium |
|---------|:----:|:-------:|
| Core loop: quests, skills, XP, gold, streaks, HP/energy | ✅ | ✅ |
| Bosses | ✅ (up to 3 active) | ✅ unlimited |
| Achievements | ✅ | ✅ |
| Guilds & PvP | ✅ | ✅ |
| Battle Pass — free track | ✅ | ✅ |
| Battle Pass — premium track | ❌ | ✅ (bundled) |
| Statistics dashboard | ✅ basic | ✅ advanced (heatmaps, trends, exports) |
| AI Coach | ✅ weekly tip | ✅ full: personalized quests, prediction, routines |
| Cosmetic themes/frames/avatars | ✅ starter set | ✅ full library + seasonal |
| Streak freeze cap | 3 | 5 + 1 free/month |
| Cloud backup & multi-device | ✅ | ✅ |
| Ads | none (we never run ads) | none |

### 12.2 Pricing suggestion

| Product | Price | Notes |
|---------|-------|-------|
| **Premium monthly** | **$6.99/mo** | 7-day free trial (`SubscriptionStatus.TRIALING`) |
| **Premium annual** | **$49.99/yr** (~$4.17/mo, −40%) | best value, anchors the offer |
| **Lifetime** | $129.99 one-time | whales/early adopters |
| Cosmetic bundles (IAP) | $1.99–$9.99 | direct-buy, no loot boxes |
| Gold top-ups | ❌ intentionally not sold | keeps gold = earned effort (Pillar C) |

Billing via `BillingProvider`: Stripe (web), Apple IAP, Google Play. `externalId` stores
the provider sub id; `currentPeriodEnd` / `cancelAtPeriodEnd` drive access + renewal.

> **We do not sell gold or XP.** Selling core currency would break real-life transfer and
> the healthy-engagement promise.

---

## 13. Ethical / Healthy-Engagement Guardrails

A standing checklist every new feature must pass review against:

1. **No gambling.** No loot boxes, no paid RNG. Cosmetics are directly purchasable at a
   shown price.
2. **No dark patterns.** No fake urgency, no guilt copy, no confirm-shaming on cancel, no
   hidden auto-renew surprises. Cancel is one tap.
3. **No pay-to-win.** Money buys cosmetics, insight, and convenience — never permanent
   power, XP, or gold.
4. **Anti-burnout by design.** Energy cap, rest-day suggestions, freeze forgiveness, and
   AI Coach load-limiting are first-class.
5. **Data minimalism.** AI Coach uses aggregates; we never sell data; health integrations
   are opt-in and revocable.
6. **Honest currency.** Gold is earned, not bought; the shop's most meaningful sink is the
   user's own real-life rewards.
7. **Accessibility & inclusivity.** See [Wireframes §Accessibility](WIREFRAMES.md).
8. **Right to leave.** Full data export + account deletion; streaks/achievements are yours.

> The north-star metric is **"days the user genuinely improved their life,"** not session
> count. If a mechanic boosts DAU by making people anxious, we cut it.
