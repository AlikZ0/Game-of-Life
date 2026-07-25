# ⚔️ Life Quest — Turn Your Real Life Into an RPG

> A premium, cross-platform self-improvement platform where real-world actions become game progress.
> Habits become **Daily Quests**, big goals become **Bosses**, and consistency becomes **XP, Gold, and Streaks**.

Life Quest is designed to be **addictive but healthy** — combining AAA-quality UX (Apple / Duolingo / Notion) with
proven RPG mechanics (XP curves, skill trees, boss fights, guilds, PvP, battle passes) to make real self-improvement
feel like the best game you've ever played.

---

## 📦 Monorepo Structure

```
life-quest/
├── backend/        # NestJS API — Clean Architecture + DDD + Repository Pattern
├── mobile/         # Flutter app — feature-first Clean Architecture
├── infra/          # Docker Compose, Kubernetes, Nginx, observability
├── docs/           # Architecture, DB schema, API docs, ER diagrams, wireframes, roadmap
└── README.md       # You are here
```

## 📚 Documentation Index

| Document | Description |
|----------|-------------|
| [Architecture](docs/ARCHITECTURE.md) | System design, layers, DDD bounded contexts, tech decisions |
| [Database Schema](docs/DATABASE.md) | Full PostgreSQL schema, tables, relations, indexing strategy |
| [ER Diagram](docs/ER_DIAGRAM.md) | Entity-relationship diagrams (Mermaid) |
| [API Reference](docs/API.md) | REST + WebSocket endpoints, auth, error model |
| [Game Design](docs/GAME_DESIGN.md) | XP curves, economy, boss math, achievement tiers, streaks |
| [Wireframes](docs/WIREFRAMES.md) | UX flows and screen-by-screen wireframes |
| [Roadmap](docs/ROADMAP.md) | Full delivery roadmap, MVP plan, future scaling |
| [Deployment](docs/DEPLOYMENT.md) | Docker + Kubernetes production deployment |
| [Folder Structure](docs/FOLDER_STRUCTURE.md) | Detailed backend & mobile folder layout |

## 🛠 Tech Stack

**Backend:** NestJS · TypeScript · PostgreSQL · Prisma · Redis · BullMQ · Socket.IO · JWT · Stripe · Firebase Admin
**Mobile:** Flutter · Riverpod · go_router · Dio · Freezed · Hive
**Infra:** Docker · Docker Compose · Kubernetes · Nginx · GitHub Actions · Prometheus/Grafana

## 🖥️ Run & Test Locally

The fastest way to see Life Quest working is to boot the backend with Docker and
poke the API through Swagger; the Flutter app is optional and connects to that
same local API.

### Prerequisites

| Tool | Needed for | Notes |
|------|-----------|-------|
| **Docker + Docker Compose** | Backend + database + Redis | The only hard requirement to run the API |
| **Node.js 20+** | Tests, DB seed, Prisma Studio (outside Docker) | Optional |
| **Flutter 3.x** | Running the mobile app | Optional |

### 1 · Start the backend (Docker) — recommended

```bash
cd infra
cp ../backend/.env.example ../backend/.env     # default local secrets are fine
docker compose up --build
```

This starts **Postgres + Redis + API (auto-runs migrations) + worker + Nginx**. Once it's up:

| What | URL |
|------|-----|
| 🧭 **Swagger UI** (interactive API — try every endpoint here) | http://localhost:3000/docs |
| ❤️ Health check | http://localhost:3000/api/v1/health |
| 🔀 Via Nginx proxy | http://localhost/api/v1 |

Stop with `Ctrl+C`. `docker compose down` removes containers (data is kept in a
volume; add `-v` to wipe it). Follow logs with `docker compose logs -f api`.

> The default `docker compose up` also merges `docker-compose.override.yml`
> (hot-reload dev mode + exposed DB/Redis ports). For a production-like run
> instead, use `docker compose -f docker-compose.yml up --build`.

### 2 · Try the full game loop (no mobile app needed)

Open **http://localhost:3000/docs**, or run this end-to-end flow with `curl` + `jq`:

```bash
API=http://localhost:3000/api/v1

# 1) Register → returns access + refresh tokens (wrapped in { data, meta })
TOKEN=$(curl -s -X POST $API/auth/register -H 'Content-Type: application/json' \
  -d '{"email":"hero@lifequest.app","password":"Str0ng-Passw0rd!"}' | jq -r .data.accessToken)

AUTH="Authorization: Bearer $TOKEN"

# 2) Create your character
curl -s -X POST $API/characters -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"name":"Aria the Bold","characterClass":"MAGE"}' | jq .data

# 3) Create a daily quest that trains the "programming" skill
QID=$(curl -s -X POST $API/quests -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"title":"Code for 45 minutes","cadence":"DAILY","difficulty":"HARD","skillKey":"programming"}' \
  | jq -r .data.id)

# 4) Complete it → watch XP, gold, level-ups, and streak roll in
curl -s -X POST $API/quests/$QID/complete -H "$AUTH" | jq .data

# 5) See your progression + life-balance stats
curl -s $API/stats/dashboard -H "$AUTH" | jq .data
```

In Swagger: click **Authorize**, paste the `accessToken`, then call any endpoint.

### 3 · (Optional) Seed demo content

Populates the achievement catalog and an active Battle Pass season. Requires
Node on your host (the dev compose exposes Postgres on `localhost:5432`):

```bash
cd backend
npm install
npm run prisma:generate
DATABASE_URL="postgresql://lifequest:lifequest@localhost:5432/lifequest?schema=public" npm run seed
```

### 4 · Run the mobile app (Flutter)

The repo tracks only `lib/` (app code); generate the native platform wrappers on
first run, then start it against the local API:

```bash
cd mobile
flutter create . --project-name life_quest --platforms=android,ios,web  # one-time: adds android/ios/web
flutter pub get
dart run build_runner build --delete-conflicting-outputs                # generates *.freezed.dart / *.g.dart

# Quickest look — in a browser:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# On an Android emulator, the host is 10.0.2.2 (not localhost):
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
```

### 5 · Run backend tests & checks (outside Docker)

```bash
cd backend
npm install
npm run prisma:generate
npm test          # unit tests (leveling, rewards, streak logic)
npm run lint      # eslint
npm run build     # nest build (type-check + compile)
```

### 6 · Handy extras

- **Browse the database:** `cd backend && npm run prisma:studio` → http://localhost:5555
- **Rebuild after code changes:** `docker compose up --build`
- Per-package details: [backend/README.md](backend/README.md) · [mobile/README.md](mobile/README.md)

## 🎮 Feature Map

| Domain | Features |
|--------|----------|
| **Identity** | Google / Apple / Email auth, JWT access+refresh, character creation |
| **Progression** | XP, levels (exponential curve), Gold, Energy, HP, titles, cosmetics |
| **Quests** | Daily / Weekly / Monthly, CRUD, repeat rules, difficulty, rewards |
| **Skills** | 8+ skills with level, XP, progress, history, heatmaps |
| **Bosses** | Big goals as HP bars; tasks deal damage; rewards on defeat |
| **Achievements** | Hundreds, bronze→silver→gold→legendary |
| **Economy** | Inventory + Shop of user-defined real-life rewards |
| **Streaks** | Daily streaks with milestone rewards & freezes |
| **Social** | Guilds (chat, shared missions, leaderboards), PvP challenges |
| **Insight** | Statistics dashboard, AI Coach, smart notifications |
| **Monetization** | Battle Pass (free/premium), Premium subscription (Stripe/IAP) |

## 🧭 Project Status

This repository is a **production-grade foundation**, not a shipped app — a coherent, runnable
monorepo that implements the full core loop end-to-end and scaffolds every remaining system.
CI (backend build + lint + tests, Docker image build, Flutter analyze) is green.

### ✅ Done & working
- **Docs (9):** architecture, DB schema, ER diagrams, API reference, game-design bible, wireframes, roadmap, deployment, folder structure.
- **Backend core loop (real, tested):** email/Google auth with JWT access+rotating refresh · character creation & the atomic progression engine (XP → levels, gold ledger, skill XP, energy) · quests CRUD + idempotent per-period completion · exponential leveling & difficulty/streak reward math (unit-tested) · skills + heatmap · streaks with milestones/freezes · bosses (HP + defeat rewards) · achievements (tiered catalog + unlock engine) · shop/inventory with gold spending · stats dashboard · rule-based AI Coach.
- **Backend scaffolded (endpoints + services, lighter logic):** guilds & PvP, notifications (FCM-gated), Battle Pass, Stripe subscription (defensive/optional), realtime WebSocket gateway, BullMQ worker.
- **Mobile (120 Dart files, 15 feature areas):** premium dark-first design system, clean architecture, flagship auth / character creation / quest dashboard / boss detail screens; other features have real structure + UI.
- **Infra:** multi-stage Docker build, docker-compose, Nginx, Kubernetes base + staging/prod overlays, GitHub Actions CI/CD, initial Prisma migration.

### 🔨 Partial / stubbed (clear TODOs in code)
- Apple Sign-In token verification (Google is fully implemented).
- AI Coach LLM enrichment (rule-based engine works today; LLM path is gated behind Premium).
- Guild chat / live leaderboards / PvP scoring are wired but not fully real-time-driven yet.
- Billing: Stripe webhook handling is defensive; Apple IAP / Google Play Billing are not yet integrated.
- Push notifications log unless Firebase credentials are configured.

### 🎯 Recommended next steps
1. Generate & commit real Prisma migrations per change; add integration tests over the completion flow.
2. Finish the social real-time layer (guild chat + leaderboards over the WebSocket gateway).
3. Wire mobile screens to the live API for the remaining features and add widget/golden tests.
4. Complete monetization (Apple/Google billing + subscription entitlement checks).
5. Add observability (Prometheus/Grafana), then stand up staging via the K8s overlays.

The [Roadmap](docs/ROADMAP.md) breaks all 18 feature areas into phased sprints.

## 📄 License

Proprietary — © Life Quest. All rights reserved.
