# ⚔️ Life Quest — Mobile (Flutter)

Premium, cross-platform client for **Life Quest**. Built with **feature-first Clean Architecture**,
Riverpod, go_router, Dio, and Freezed. Dark-first design system with an AAA feel
(Apple / Duolingo / Notion).

## 🏗 Architecture

```
lib/
├── main.dart                 # ProviderScope bootstrap
├── app.dart                  # MaterialApp.router (theme + router)
├── core/                     # cross-cutting concerns
│   ├── config/               # env + DI wiring
│   ├── network/              # Dio client, endpoints, exceptions
│   ├── router/               # go_router configuration
│   ├── storage/              # secure storage (tokens) + Hive local store
│   ├── theme/                # design system (colors, type, spacing, theme)
│   ├── utils/                # formatters, Result type
│   └── widgets/              # shared premium widgets
└── features/<feature>/
    ├── data/
    │   ├── models/           # Freezed + json_serializable DTOs
    │   ├── datasources/      # remote (Dio) data sources
    │   └── repositories_impl/# repository implementations
    ├── domain/
    │   ├── entities/         # pure domain entities
    │   ├── repositories/     # abstract repository contracts
    │   └── usecases/         # single-responsibility use cases
    └── presentation/
        ├── providers/        # Riverpod controllers (Notifier/AsyncNotifier)
        ├── screens/          # full screens
        └── widgets/          # feature-scoped widgets
```

Feature modules: `auth`, `character`, `quests`, `skills`, `bosses`, `achievements`,
`economy`, `streaks`, `social`, `stats`, `ai_coach`, `battle_pass`, `profile`.

## 🚀 Run

```bash
flutter pub get

# Generate Freezed / json_serializable / Riverpod code
dart run build_runner build --delete-conflicting-outputs

# Run against a local API
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# Run against staging
flutter run --dart-define=API_BASE_URL=https://staging.lifequest.app/api/v1
```

> The `API_BASE_URL` dart-define is read in `core/config/env.dart`. It defaults to
> `http://localhost:3000/api/v1` when unset.

## 🧪 Codegen

Any change to a `*.dart` file annotated with `@freezed`, `@JsonSerializable`, or
`@riverpod` requires re-running:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

The generated `*.g.dart` / `*.freezed.dart` files are git-ignored and must be built locally / in CI.

## 🎨 Design System

- Accent: `#7C5CFF` (electric violet)
- Dark-first, with a matching light theme
- Rounded 20px cards, soft elevation, glassmorphic surfaces
- Typography via `google_fonts` (Sora display + Inter body)

## 🔌 API

Talks to the NestJS backend at `/api/v1`. Endpoint catalog lives in
`core/network/api_endpoints.dart` and mirrors the Prisma data model.
