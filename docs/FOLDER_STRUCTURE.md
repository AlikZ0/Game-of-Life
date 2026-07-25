# Life Quest — Folder Structure

> Annotated layout for the `backend/` (NestJS, Clean Architecture + DDD) and
> `mobile/` (Flutter, feature-first Clean Architecture) trees, with rationale for
> each top-level choice. Module names mirror the bounded contexts in
> [ARCHITECTURE.md](ARCHITECTURE.md) and the models in
> [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma).

---

## 1. Monorepo Top Level

```
life-quest/
├── backend/     # NestJS API (this document, §2)
├── mobile/      # Flutter app (this document, §3)
├── infra/       # Docker Compose, Kubernetes, Nginx, observability
├── docs/        # Architecture, DB, ER, API, folder structure (you are here)
└── README.md
```

**Rationale**: a single repo keeps the API contract, the client that consumes it,
and the infra that runs it versioned together — one PR can change schema, endpoint,
and UI atomically.

---

## 2. Backend (`backend/`)

Every **bounded context** is a NestJS module split into the four Clean Architecture
layers (`domain`, `application`, `infrastructure`, `presentation`). Dependencies
point inward (see ARCHITECTURE §2).

```
backend/
├── prisma/
│   ├── schema.prisma            # SINGLE SOURCE OF TRUTH for the data model
│   ├── migrations/              # Versioned SQL migrations (prisma migrate)
│   └── seed.ts                  # Seed achievements catalog, demo season/tiers
│
├── src/
│   ├── main.ts                  # Bootstrap: validation pipe, filters, Swagger, CORS
│   ├── app.module.ts            # Root module — imports every context module
│   │
│   ├── config/                  # Typed configuration (env schema, per-concern config)
│   │   ├── app.config.ts        #   port, base path, CORS
│   │   ├── auth.config.ts       #   JWT secrets/TTLs, OAuth client ids
│   │   ├── database.config.ts   #   DATABASE_URL
│   │   ├── redis.config.ts      #   cache/queue/socket adapter
│   │   ├── billing.config.ts    #   Stripe / IAP keys, webhook secrets
│   │   └── env.validation.ts    #   fail-fast env validation on boot
│   │
│   ├── common/                  # Cross-cutting building blocks (framework glue)
│   │   ├── prisma/               #   PrismaService (lifecycle, tx helper)
│   │   ├── redis/                #   Redis client + cache service
│   │   ├── auth/                 #   JwtAuthGuard, RolesGuard, ResourceOwnerGuard, @CurrentUser
│   │   ├── rbac/                 #   @Roles decorator, role enums
│   │   ├── filters/              #   HttpExceptionFilter -> error envelope
│   │   ├── interceptors/         #   Logging, transform, BigInt->string serializer
│   │   ├── pipes/                #   Global ValidationPipe config
│   │   ├── throttler/            #   Rate-limit config (Redis store)
│   │   ├── idempotency/          #   Idempotency-Key guard (Redis SETNX)
│   │   ├── events/               #   Domain event bus + base DomainEvent
│   │   ├── pagination/           #   Cursor pagination helpers + PageInfo DTO
│   │   └── errors/               #   Base domain error classes + HTTP mapping
│   │
│   ├── queue/                   # BullMQ setup + workers (event-driven side effects)
│   │   ├── queue.module.ts
│   │   └── workers/
│   │       ├── gamification.worker.ts   # XP roll-ups, boss damage, level-ups
│   │       ├── achievements.worker.ts   # evaluate Achievement.criteria
│   │       ├── streaks.worker.ts        # daily streak/freeze logic
│   │       ├── notifications.worker.ts  # FCM push + WS toasts
│   │       ├── leaderboards.worker.ts   # Redis sorted-set updates
│   │       └── billing.worker.ts        # subscription reconciliation
│   │
│   ├── realtime/               # Socket.IO infrastructure
│   │   ├── redis-io.adapter.ts  #   multi-instance fan-out adapter
│   │   └── ws-jwt.guard.ts      #   handshake auth
│   │
│   ├── health/                 # Liveness/readiness (DB, Redis) endpoints
│   │
│   └── modules/                # ── BOUNDED CONTEXTS ──
│       ├── identity/            # User, RefreshToken, NotificationToken, AuditLog
│       │   ├── domain/
│       │   │   ├── entities/            # User, Session entities (plain TS)
│       │   │   ├── value-objects/       # Email, HashedPassword
│       │   │   ├── events/              # UserRegisteredEvent, UserLoggedInEvent
│       │   │   └── ports/               # UserRepository, RefreshTokenRepository (interfaces)
│       │   ├── application/
│       │   │   ├── use-cases/           # Register, Login, OAuthLogin, Refresh, Logout, GetMe
│       │   │   ├── dto/                 # request/response DTOs
│       │   │   └── ports/               # OAuthVerifier, TokenSigner (interfaces)
│       │   ├── infrastructure/
│       │   │   ├── persistence/         # PrismaUserRepository, mappers
│       │   │   └── adapters/            # Google/AppleVerifier, JwtTokenSigner, Argon2Hasher
│       │   └── presentation/
│       │       ├── auth.controller.ts   # /auth/*
│       │       └── notifications.controller.ts # /notifications/*
│       │
│       ├── character/           # Character (progression: level/xp/gold/hp/energy)
│       │   ├── domain/          #   Character entity, LevelCurve VO, XP/Level events
│       │   ├── application/     #   CreateCharacter, GetCharacter, UpdateCharacter, ApplyXp
│       │   ├── infrastructure/  #   PrismaCharacterRepository
│       │   └── presentation/    #   character.controller.ts
│       │
│       ├── skills/              # Skill, SkillXpEvent
│       │   ├── domain/          #   Skill entity, SkillLeveledUpEvent, SkillRepository port
│       │   ├── application/     #   ListSkills, GetSkill, AddSkillXp, GetHistory
│       │   ├── infrastructure/  #   PrismaSkillRepository
│       │   └── presentation/    #   skills.controller.ts
│       │
│       ├── quests/             # Quest, QuestCompletion
│       │   ├── domain/          #   Quest entity, PeriodKey VO, QuestCompletedEvent, QuestRepository
│       │   ├── application/     #   Create/Update/Archive/List quests, CompleteQuest (idempotent)
│       │   ├── infrastructure/  #   PrismaQuestRepository, PrismaQuestCompletionRepository, mappers
│       │   └── presentation/    #   quests.controller.ts
│       │
│       ├── bosses/            # Boss (+ Quest.bossId linkage)
│       │   ├── domain/          #   Boss entity, DamageDealt/BossDefeated events
│       │   ├── application/     #   CRUD, AttackBoss, CompleteBoss
│       │   ├── infrastructure/  #   PrismaBossRepository
│       │   └── presentation/    #   bosses.controller.ts
│       │
│       ├── achievements/     # Achievement, CharacterAchievement
│       │   ├── domain/          #   Criteria evaluator (rule engine), events
│       │   ├── application/     #   ListAchievements, GetProgress, EvaluateOnEvent
│       │   ├── infrastructure/  #   PrismaAchievementRepository
│       │   └── presentation/    #   achievements.controller.ts
│       │
│       ├── economy/          # InventoryItem, ShopReward, GoldLedgerEntry
│       │   ├── domain/          #   GoldLedger (append-only) service, Inventory entity
│       │   ├── application/     #   ListInventory, Equip/Use, Shop CRUD, RedeemReward, CreditGold
│       │   ├── infrastructure/  #   PrismaInventoryRepository, PrismaGoldLedgerRepository
│       │   └── presentation/    #   inventory.controller.ts, shop.controller.ts
│       │
│       ├── streaks/          # Streak
│       │   ├── domain/          #   Streak entity (increment/freeze/reset)
│       │   ├── application/     #   GetStreak, RollStreakOnCompletion
│       │   ├── infrastructure/  #   PrismaStreakRepository
│       │   └── presentation/    #   streaks.controller.ts
│       │
│       ├── social/           # Guild, GuildMember, GuildMission, GuildMessage, PvpChallenge
│       │   ├── domain/          #   Guild/Member entities, PvP duel service, guild role rules
│       │   ├── application/     #   Create/Join/Leave guild, Missions, Messages, Leaderboard, PvP flows
│       │   ├── infrastructure/  #   Prisma*Repository, Redis leaderboard adapter
│       │   └── presentation/
│       │       ├── guilds.controller.ts   # /guilds/*
│       │       ├── pvp.controller.ts      # /pvp/*
│       │       ├── guild.gateway.ts       # /guild WS namespace
│       │       ├── leaderboard.gateway.ts # /leaderboard WS namespace
│       │       └── pvp.gateway.ts         # /pvp WS namespace
│       │
│       ├── monetization/     # Season, BattlePassTier, BattlePassProgress, Subscription
│       │   ├── domain/          #   BattlePass progression, Subscription lifecycle
│       │   ├── application/     #   GetCurrentPass, ClaimTier, Checkout, HandleWebhook, GetStatus
│       │   ├── infrastructure/  #   Prisma repos, StripeAdapter, AppleIapAdapter, GooglePlayAdapter
│       │   └── presentation/    #   battle-pass.controller.ts, subscription.controller.ts
│       │
│       └── insight/          # Read models (no owned tables)
│           ├── application/     #   Dashboard, XpSeries, SkillHeatmap, AiCoach use cases
│           ├── infrastructure/  #   Read projections, AiProviderAdapter (LLM)
│           └── presentation/    #   stats.controller.ts, ai-coach.controller.ts
│
├── test/                       # e2e specs (supertest) + fixtures
│   ├── e2e/
│   └── fixtures/
├── .env.example
├── nest-cli.json
├── tsconfig.json
├── package.json
└── README.md
```

**Rationale for backend top-level choices**

- **`prisma/` is the schema authority** — kept outside `src/` because it is
  storage, not application code; migrations and seeds live beside it.
- **`config/`** centralizes typed, validated env access so no module reads
  `process.env` directly.
- **`common/`** holds framework glue (guards, filters, pipes, event bus) that every
  module reuses — the enforcement points for the cross-cutting concerns in
  ARCHITECTURE §5.
- **`queue/` and `realtime/`** isolate the async (BullMQ) and WS (Socket.IO)
  infrastructure so contexts publish events/emit without owning transport wiring.
- **`modules/<context>/{domain,application,infrastructure,presentation}`** makes the
  dependency rule visible in the tree: `domain` never imports outward; only
  `infrastructure` touches Prisma/adapters; only `presentation` touches HTTP/WS.
- **`insight/`** deliberately has no `domain/` folder — it is a read-only projection
  context with no owned tables.

---

## 3. Mobile (`mobile/`)

Flutter, **feature-first Clean Architecture**. Each feature mirrors a backend
context and is split into `data`, `domain`, `presentation`. Stack: Riverpod
(state), go_router (nav), Dio (HTTP), Freezed (models), Hive (offline cache).

```
mobile/
├── lib/
│   ├── main.dart                # App entry: ProviderScope, bootstrap
│   ├── app.dart                 # MaterialApp.router, theme, router wiring
│   │
│   ├── core/                    # App-wide infrastructure (no feature logic)
│   │   ├── config/              #   env (API_BASE_URL via --dart-define), flavors
│   │   ├── network/             #   Dio client, auth interceptor, refresh-on-401, error mapper
│   │   ├── auth/                #   token store (secure storage), session controller
│   │   ├── router/              #   go_router config, guards (auth redirect), routes
│   │   ├── realtime/            #   Socket.IO client, namespace managers
│   │   ├── storage/             #   Hive boxes, cache adapters (offline)
│   │   ├── error/               #   Failure types, error->message mapping
│   │   ├── di/                  #   Riverpod providers composition root
│   │   └── utils/               #   formatters, extensions, result type
│   │
│   ├── shared/                  # Reusable UI + models across features
│   │   ├── widgets/             #   buttons, XP bars, cards, dialogs, toasts
│   │   ├── theme/               #   colors, typography, dark/light, design tokens
│   │   └── models/              #   shared DTOs (Freezed), enums mirroring backend
│   │
│   └── features/                # ── FEATURE-FIRST (mirrors backend contexts) ──
│       ├── auth/
│       │   ├── data/            #   AuthApi (Dio), AuthRepositoryImpl, DTOs
│       │   ├── domain/          #   entities, AuthRepository interface, use cases
│       │   └── presentation/    #   login/register/OAuth screens, controllers (Riverpod)
│       │
│       ├── character/           #   character sheet, progression header
│       │   ├── data/ domain/ presentation/
│       │
│       ├── skills/              #   skill list, detail, XP history, heatmap
│       │   ├── data/ domain/ presentation/
│       │
│       ├── quests/             #   daily/weekly/monthly tabs, CRUD, complete flow
│       │   ├── data/ domain/ presentation/
│       │
│       ├── bosses/            #   boss list, HP bars, attack/defeat
│       │   ├── data/ domain/ presentation/
│       │
│       ├── achievements/     #   grid, rarity, progress, secrets
│       │   ├── data/ domain/ presentation/
│       │
│       ├── economy/          #   inventory + user-defined shop + redeem
│       │   ├── data/ domain/ presentation/
│       │
│       ├── streaks/          #   streak widget, freeze usage
│       │   ├── data/ domain/ presentation/
│       │
│       ├── social/           #   guild (chat via WS, missions, leaderboard), pvp
│       │   ├── data/ domain/ presentation/
│       │
│       ├── monetization/     #   battle pass, subscription/paywall
│       │   ├── data/ domain/ presentation/
│       │
│       └── insight/          #   stats dashboard, AI coach
│           ├── data/ domain/ presentation/
│
├── assets/                     # images, icons, fonts, animations (Rive/Lottie)
├── test/                       # unit + widget tests (mirrors lib/features)
├── integration_test/           # end-to-end flows
├── pubspec.yaml
└── README.md
```

**Rationale for mobile top-level choices**

- **`core/`** is app-wide plumbing with no feature knowledge — the Dio client's
  auth interceptor handles the access/refresh rotation from API §2 transparently.
- **`shared/`** holds design-system widgets and cross-feature Freezed models
  (enums kept in lockstep with the backend enums in DATABASE §2).
- **`features/<feature>/{data,domain,presentation}`** is the client mirror of the
  backend's Clean Architecture: `domain` (entities + repository interfaces + use
  cases) depends on nothing Flutter-specific; `data` implements repositories over
  Dio/Hive; `presentation` holds screens + Riverpod controllers. Feature folders
  map 1:1 to backend contexts so a feature can be reasoned about end-to-end.
- **`test/` mirrors `lib/`** so every feature has a colocated test path.

---

## 4. Related Documents

- [ARCHITECTURE.md](ARCHITECTURE.md) — layering & bounded contexts these folders realize
- [API.md](API.md) — endpoints the presentation layers expose/consume
- [DATABASE.md](DATABASE.md) — models the domain/data layers map to
