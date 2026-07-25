# Feature Modules

Each feature follows the same **feature-first Clean Architecture** shape:

```
<feature>/
├── data/
│   ├── models/            # Freezed + json_serializable DTOs (*.freezed.dart / *.g.dart via build_runner)
│   ├── datasources/       # remote (Dio) data sources
│   └── repositories_impl/ # concrete repositories mapping DTO → entity
├── domain/
│   ├── entities/          # pure domain models + business helpers
│   ├── repositories/      # abstract repository contracts
│   └── usecases/          # single-responsibility interactions
└── presentation/
    ├── providers/         # Riverpod controllers (Notifier/AsyncNotifier) + DI
    ├── screens/           # full screens routed by go_router
    └── widgets/           # feature-scoped widgets
```

## Status by feature

| Feature       | Depth        | Notes |
|---------------|--------------|-------|
| `auth`        | **Flagship** | Full data→domain→presentation. Google/Apple/Email, token refresh, router gating. |
| `character`   | **Flagship** | Creation flow with live preview + class picker; hero character card. |
| `quests`      | **Flagship** | Dashboard, create/edit sheet, optimistic complete + reward burst sheet. |
| `bosses`      | **Flagship** | Boss gallery + detail with dramatic HP header and linked attacking quests. |
| `skills`      | Full         | Skill list with progress bars + custom activity heatmap. |
| `achievements`| Full         | Rarity-colored gallery grid with progress rings. |
| `economy`     | Full         | Inventory grid + shop with gold redemption. |
| `streaks`     | Full         | Dashboard flame + milestones timeline. |
| `stats`       | Full         | fl_chart XP line chart + completion rate + metric tiles. |
| `battle_pass` | Full         | Free/premium tier track with upsell. |
| `ai_coach`    | Full         | Suggestion feed with typed cards. |
| `social`      | Structure    | Guild (missions/leaderboard/chat tabs) + PvP arena. Chat is a Socket.IO **stub**. |
| `profile`     | Full         | Profile hub, settings, and premium paywall. |
| `onboarding`  | Full         | Three-panel intro carousel. |

## Stubs / TODOs

- **Guild chat** (`social/.../guild_screen.dart` → `_ChatTab`) is a UI stub; wire to
  Socket.IO at `Env.wsBaseUrl` for realtime messages.
- **Paywall CTA** (`profile/.../paywall_screen.dart`) needs Stripe / StoreKit /
  Play Billing via `POST /billing/checkout`.
- **Create boss / create PvP challenge** FABs are placeholders (`onPressed: () {}`).
- Generated `*.freezed.dart` / `*.g.dart` files are produced by
  `dart run build_runner build` and are intentionally absent from source control.
