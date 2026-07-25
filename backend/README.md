# Life Quest — Backend API

NestJS API for **Life Quest**, a gamified self-improvement app: turn real-life
habits into quests, level up a character and skills, fight "bosses" (big goals),
keep streaks, join guilds, duel friends (PvP), earn a seasonal Battle Pass and
unlock a Premium subscription.

## Architecture

Clean Architecture / DDD, one module per bounded context under
`src/modules/<context>/`, each split into layers:

```
modules/<context>/
├── domain/          # pure business rules & types (no framework deps)
├── application/     # services + DTOs (use-cases)
├── infrastructure/  # Prisma repositories, external adapters
└── presentation/    # controllers / gateways (HTTP + WebSocket)
```

Cross-cutting pieces live in `src/common/` (decorators, filters, interceptors),
`src/config/` (typed config + env validation) and `src/infra/prisma/`
(`PrismaService`). Auth is JWT (global `JwtAuthGuard`; opt out with `@Public()`).
Rewards are always granted through `CharacterService.awardRewards(...)`, which
atomically applies XP/levels, skill XP, gold (append-only ledger) and energy.

### Module map

| Module              | Routes / surface                                  | Responsibility |
| ------------------- | ------------------------------------------------- | -------------- |
| `AuthModule`        | `/auth/*`                                          | Email + OAuth login, JWT issue/refresh |
| `CharacterModule`   | `/character`                                       | Character, progression, `awardRewards` |
| `SkillsModule`      | `/skills`                                          | Skill tree & skill XP |
| `QuestsModule`      | `/quests`                                          | Quests + idempotent completions |
| `BossesModule`      | `/bosses`                                          | Boss goals, damage, rewards |
| `StreaksModule`     | `/streaks`                                         | Daily streak accounting |
| `AchievementsModule`| `/achievements`                                    | Achievement catalog & unlocks |
| `EconomyModule`     | `/shop`, `/inventory`                              | Custom rewards, gold spend, inventory |
| `StatsModule`       | `/stats`                                           | Dashboards, life-balance, XP series |
| `AiCoachModule`     | `/ai-coach`                                        | Rule-based (+ optional LLM) coaching |
| `SocialModule`      | `/guilds`, `/pvp`                                  | Guilds (chat, missions, leaderboard) + 1v1 duels |
| `NotificationsModule`| `/notifications/token`                            | FCM device tokens + push (Firebase optional) |
| `MonetizationModule`| `/battle-pass`, `/subscription`                    | Seasonal Battle Pass + Stripe Premium |
| `RealtimeModule`    | WebSocket `/realtime`                              | Live level-ups, boss defeats, guild chat |
| `HealthModule`      | `/health`                                          | Liveness/readiness probe |

Third-party integrations (Stripe, Firebase, LLM) are **defensive/optional**:
when the relevant env vars are unset the app degrades gracefully (logs / clear
"not configured" responses) so it runs end-to-end locally and in CI.

## Prerequisites

- Node.js 20+
- PostgreSQL 14+
- Redis 6+ (BullMQ queues / worker)

## Getting started

```bash
# 1. Install dependencies
npm install

# 2. Configure environment (see .env.example for every variable)
cp .env.example .env

# 3. Generate the Prisma client
npm run prisma:generate

# 4. Create the database schema
npm run prisma:migrate      # dev migrations
# or, against an existing DB:  npm run prisma:deploy

# 5. Seed reference data (achievements + active season + battle-pass tiers)
npm run seed

# 6. Run the API
npm run start:dev           # watch mode → http://localhost:3000
```

Swagger UI is served under the API prefix (see `main.ts`) once the app is up.

### Background worker

```bash
npm run worker:dev          # BullMQ worker (gamification / notification jobs)
```

## Testing

```bash
npm test                    # unit tests (*.spec.ts)
npm run test:cov            # unit tests + coverage
npm run test:e2e            # e2e tests (test/*.e2e-spec.ts; needs a DB)
```

## Code quality

```bash
npm run lint                # ESLint (@typescript-eslint + prettier)
npm run format              # Prettier write
```

## Environment

All configuration is via environment variables — see **`.env.example`** for the
full annotated list (app, database, Redis, JWT, OAuth, Stripe, Firebase, AI,
throttling). Anything left blank simply disables the corresponding optional
integration.
