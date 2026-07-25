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

## 🚀 Quick Start (Local Dev)

```bash
# 1. Boot infrastructure + API (Postgres, Redis, NestJS)
cd infra
cp ../backend/.env.example ../backend/.env
docker compose up --build

# API:      http://localhost:3000/api/v1
# Swagger:  http://localhost:3000/docs
# Health:   http://localhost:3000/api/v1/health

# 2. Run the Flutter app (against the local API)
cd ../mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

See [backend/README.md](backend/README.md) and [mobile/README.md](mobile/README.md) for details.

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

## 🧭 Status

This repository is a **production-grade foundation**: complete architecture, database schema, API contract,
a runnable NestJS backend skeleton with real domain modules (auth, character, quests, skills, gamification engine),
a Flutter app scaffold with themed UI + core flows, and full Docker/Kubernetes deployment.
The [Roadmap](docs/ROADMAP.md) defines exactly how each remaining feature lands, sprint by sprint.

## 📄 License

Proprietary — © Life Quest. All rights reserved.
