# Life Quest — API Reference

> REST + WebSocket contract for the NestJS backend. All shapes are consistent with
> [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma) and
> [DATABASE.md](DATABASE.md).

---

## 1. Conventions

- **Base path**: `/api/v1`
- **Format**: JSON request/response (`Content-Type: application/json`), UTF-8.
- **Auth header**: `Authorization: Bearer <accessToken>` (JWT). Public endpoints
  are marked **Auth: No**.
- **IDs**: `cuid` strings (`Achievement.id` is a stable slug).
- **Timestamps**: ISO-8601 UTC.
- **Swagger/OpenAPI**: served at `/docs`.

### 1.1 Pagination

List endpoints use cursor pagination:

```
GET /api/v1/<resource>?limit=20&cursor=<cuid>
```

Response envelope:

```json
{
  "data": [ /* items */ ],
  "pageInfo": { "nextCursor": "ckq...", "hasMore": true }
}
```

### 1.2 Error envelope

Every error is normalized:

```json
{
  "statusCode": 409,
  "message": "Quest already completed for this period",
  "error": "Conflict",
  "timestamp": "2026-07-25T10:15:30.000Z",
  "path": "/api/v1/quests/ckq.../complete"
}
```

`message` may be a string or an array of validation messages.

### 1.3 Standard status codes

| Code | Meaning |
|------|---------|
| 200 | OK |
| 201 | Created |
| 204 | No Content (e.g. logout, delete) |
| 400 | Validation error |
| 401 | Missing/invalid access token |
| 403 | Authenticated but not allowed (RBAC/ownership) |
| 404 | Not found |
| 409 | Conflict (idempotency, unique constraint) |
| 422 | Domain rule violated (insufficient energy/gold) |
| 429 | Rate limited |
| 500 | Unexpected error |

### 1.4 Idempotency

Mutating requests may send `Idempotency-Key: <uuid>`. Quest completion is
inherently idempotent per `(questId, periodKey)` — a repeat returns the existing
completion with `200` instead of double-awarding.

---

## 2. Auth (`/auth`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | No | Register with email + password |
| POST | `/auth/login` | No | Email/password login |
| POST | `/auth/google` | No | Exchange Google ID token for session |
| POST | `/auth/apple` | No | Exchange Apple identity token for session |
| POST | `/auth/refresh` | No | Rotate refresh token → new token pair |
| POST | `/auth/logout` | Yes | Revoke current refresh token |
| GET | `/auth/me` | Yes | Current user + character summary |

**POST `/auth/register`**

```json
// request
{ "email": "hero@example.com", "password": "S3cur3!pass", "name": "Aria" }
// 201
{
  "user": { "id": "cku1", "email": "hero@example.com", "provider": "EMAIL", "emailVerified": false },
  "tokens": { "accessToken": "eyJ...", "refreshToken": "def50200..." }
}
```

**POST `/auth/login`**

```json
// request
{ "email": "hero@example.com", "password": "S3cur3!pass" }
// 200
{
  "user": { "id": "cku1", "email": "hero@example.com" },
  "tokens": { "accessToken": "eyJ...", "refreshToken": "def50200..." }
}
```

**POST `/auth/google`** / **`/auth/apple`**

```json
// request
{ "idToken": "<provider-id-token>" }
// 200 — provider verified, user upserted by (provider, providerId)
{ "user": { "id": "cku1", "provider": "GOOGLE" }, "tokens": { "accessToken": "eyJ...", "refreshToken": "..." } }
```

**POST `/auth/refresh`**

```json
// request
{ "refreshToken": "def50200..." }
// 200 — old token revoked, new pair issued (rotation)
{ "tokens": { "accessToken": "eyJ...", "refreshToken": "def50201..." } }
```

**GET `/auth/me`** → `200`

```json
{
  "user": { "id": "cku1", "email": "hero@example.com", "provider": "EMAIL", "subscriptionTier": "PREMIUM" },
  "character": { "id": "ckc1", "name": "Aria", "level": 12, "class": "MAGE" }
}
```

---

## 3. Character (`/character`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/character` | Yes | Create the user's character (once) |
| GET | `/character` | Yes | Get current character with progression |
| PATCH | `/character` | Yes | Update name, avatar, class, active title |

**POST `/character`**

```json
// request
{ "name": "Aria", "class": "MAGE", "avatarKey": "mage_01" }
// 201
{
  "id": "ckc1", "name": "Aria", "class": "MAGE",
  "level": 1, "xp": 0, "totalXp": "0", "gold": 0,
  "hp": 100, "maxHp": 100, "energy": 100, "maxEnergy": 100
}
```

> `totalXp` is serialized as a **string** (BigInt).

**GET `/character`** → `200`

```json
{
  "id": "ckc1", "name": "Aria", "class": "MAGE", "avatarKey": "mage_01",
  "level": 12, "xp": 340, "totalXp": "18240", "gold": 1250,
  "hp": 92, "maxHp": 120, "energy": 60, "maxEnergy": 100,
  "activeTitle": "Nightscholar"
}
```

**PATCH `/character`**

```json
// request
{ "name": "Aria the Wise", "activeTitle": "Archmage", "avatarKey": "mage_02" }
// 200 -> updated character
```

---

## 4. Skills (`/skills`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/skills` | Yes | List all character skills |
| GET | `/skills/:id` | Yes | Get one skill |
| POST | `/skills/:id/xp` | Yes | Add XP to a skill (manual/integration) |
| GET | `/skills/:id/history` | Yes | Skill XP event history (paginated) |

**GET `/skills`** → `200`

```json
{
  "data": [
    { "id": "cks1", "key": "programming", "name": "Programming", "icon": "code", "color": "#7C5CFF", "level": 8, "xp": 120, "totalXp": "6400" },
    { "id": "cks2", "key": "fitness", "name": "Fitness", "icon": "dumbbell", "color": "#22C55E", "level": 5, "xp": 40, "totalXp": "2100" }
  ]
}
```

**POST `/skills/:id/xp`**

```json
// request
{ "amount": 50, "source": "manual" }
// 200 -> skill after applying XP (may include levelUp flag)
{ "id": "cks1", "level": 8, "xp": 170, "totalXp": "6450", "leveledUp": false }
```

**GET `/skills/:id/history`** → `200`

```json
{
  "data": [
    { "id": "cse1", "amount": 30, "source": "ckq9", "createdAt": "2026-07-25T08:00:00Z" }
  ],
  "pageInfo": { "nextCursor": null, "hasMore": false }
}
```

---

## 5. Quests (`/quests`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/quests` | Yes | List quests; filter by `cadence`, `status` |
| POST | `/quests` | Yes | Create a quest |
| GET | `/quests/:id` | Yes | Get a quest |
| PATCH | `/quests/:id` | Yes | Update a quest |
| DELETE | `/quests/:id` | Yes | Archive a quest (soft delete) |
| POST | `/quests/:id/complete` | Yes | Complete a quest (idempotent) |

**GET `/quests?cadence=DAILY&status=ACTIVE`** → `200`

```json
{
  "data": [
    { "id": "ckq1", "title": "Morning workout", "cadence": "DAILY", "difficulty": "MEDIUM",
      "status": "ACTIVE", "xpReward": 20, "goldReward": 10, "skillKey": "fitness",
      "energyCost": 10, "bossId": null, "damage": 10, "dueAt": null }
  ],
  "pageInfo": { "nextCursor": null, "hasMore": false }
}
```

**POST `/quests`**

```json
// request
{
  "title": "Study Spanish 30m", "description": "Duolingo + review",
  "cadence": "DAILY", "difficulty": "EASY",
  "xpReward": 20, "goldReward": 10, "skillKey": "english", "energyCost": 10,
  "repeatRule": { "daysOfWeek": [1,2,3,4,5] }, "bossId": "ckb2", "damage": 15
}
// 201 -> created quest
```

**POST `/quests/:id/complete`**

```json
// request (periodKey optional; server derives from cadence + now)
{ "source": "MANUAL", "periodKey": "2026-07-25" }
// 200
{
  "completion": { "id": "ckqc1", "questId": "ckq1", "periodKey": "2026-07-25", "xpAwarded": 20, "goldAwarded": 10, "source": "MANUAL" },
  "character": { "level": 12, "xp": 360, "gold": 1260, "energy": 50 },
  "skill": { "id": "cks2", "leveledUp": false },
  "boss": { "id": "ckb2", "currentHp": 85, "status": "ACTIVE" },
  "leveledUp": false
}
// 409 if already completed for this period (idempotency)
// 422 if energy < energyCost
```

**DELETE `/quests/:id`** → `204` (sets `status=ARCHIVED`, `archivedAt`).

---

## 6. Bosses (`/bosses`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/bosses` | Yes | List bosses; filter by `status` |
| POST | `/bosses` | Yes | Create a boss (big goal) |
| GET | `/bosses/:id` | Yes | Get a boss + linked quests |
| PATCH | `/bosses/:id` | Yes | Update a boss |
| DELETE | `/bosses/:id` | Yes | Abandon a boss (`status=ABANDONED`) |
| POST | `/bosses/:id/attack` | Yes | Apply damage directly |
| POST | `/bosses/:id/complete` | Yes | Force-defeat + grant rewards |

**POST `/bosses`**

```json
// request
{ "name": "Ship v1.0", "description": "Launch the app", "maxHp": 300, "rewardXp": 500, "rewardGold": 250, "deadline": "2026-09-01T00:00:00Z" }
// 201
{ "id": "ckb2", "name": "Ship v1.0", "maxHp": 300, "currentHp": 300, "status": "ACTIVE", "rewardXp": 500, "rewardGold": 250 }
```

**POST `/bosses/:id/attack`**

```json
// request
{ "damage": 40 }
// 200
{ "id": "ckb2", "currentHp": 260, "status": "ACTIVE" }
// when HP hits 0 -> status DEFEATED, rewards granted (ledger + XP), defeatedAt set
```

---

## 7. Achievements (`/achievements`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/achievements` | Yes | Catalog + this character's progress |
| GET | `/achievements/:id` | Yes | Single achievement + progress |

**GET `/achievements`** → `200`

```json
{
  "data": [
    { "id": "first_blood", "name": "First Blood", "description": "Complete your first quest",
      "rarity": "BRONZE", "category": "quests", "rewardXp": 50, "rewardGold": 20,
      "isSecret": false, "progress": 1, "unlockedAt": "2026-07-01T09:00:00Z" },
    { "id": "streak_30", "name": "Unbreakable", "rarity": "GOLD", "category": "streaks",
      "progress": 0.4, "unlockedAt": null }
  ]
}
```

---

## 8. Inventory (`/inventory`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/inventory` | Yes | List owned items; filter by `itemType` |
| POST | `/inventory/:id/equip` | Yes | Equip a cosmetic/title |
| POST | `/inventory/:id/use` | Yes | Consume a consumable (streak freeze, energy potion) |

**GET `/inventory`** → `200`

```json
{
  "data": [
    { "id": "cki1", "itemType": "TITLE", "refKey": "archmage", "name": "Archmage", "quantity": 1, "equipped": true },
    { "id": "cki2", "itemType": "CONSUMABLE_STREAK_FREEZE", "refKey": "freeze", "name": "Streak Freeze", "quantity": 3, "equipped": false }
  ]
}
```

---

## 9. Shop (`/shop`)

User-defined real-life rewards purchased with gold.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/shop` | Yes | List the character's shop rewards |
| POST | `/shop` | Yes | Create a reward |
| PATCH | `/shop/:id` | Yes | Update a reward |
| DELETE | `/shop/:id` | Yes | Deactivate a reward (`isActive=false`) |
| POST | `/shop/:id/redeem` | Yes | Redeem (spend gold, write ledger) |

**POST `/shop`**

```json
// request
{ "title": "1h gaming", "description": "Guilt-free", "icon": "gamepad", "goldCost": 200, "stock": null }
// 201 -> shop reward
```

**POST `/shop/:id/redeem`**

```json
// 200
{
  "reward": { "id": "cksr1", "timesRedeemed": 4 },
  "ledger": { "delta": -200, "balance": 1060, "reason": "SHOP_PURCHASE", "refId": "cksr1" },
  "character": { "gold": 1060 }
}
// 422 if gold < goldCost, or 409 if out of stock
```

---

## 10. Streaks (`/streaks`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/streaks` | Yes | Current streak state |

**GET `/streaks`** → `200`

```json
{ "current": 12, "longest": 34, "freezeCount": 3, "lastActiveDay": "2026-07-25" }
```

---

## 11. Guilds (`/guilds`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/guilds` | Yes | Browse/search public guilds |
| POST | `/guilds` | Yes | Create a guild (creator = LEADER) |
| GET | `/guilds/:id` | Yes | Guild detail + members |
| POST | `/guilds/:id/join` | Yes | Join a guild |
| POST | `/guilds/:id/leave` | Yes | Leave a guild |
| GET | `/guilds/:id/missions` | Yes | List guild missions |
| POST | `/guilds/:id/missions` | Yes | Create a mission (LEADER/OFFICER) |
| GET | `/guilds/:id/messages` | Yes | Chat history (paginated) |
| POST | `/guilds/:id/messages` | Yes | Post a chat message (also via WS) |
| GET | `/guilds/:id/leaderboard` | Yes | Member leaderboard (by weekly XP) |

**POST `/guilds`**

```json
// request
{ "name": "Night Owls", "tag": "OWL", "description": "Late-night grinders", "isPublic": true }
// 201
{ "id": "ckg1", "name": "Night Owls", "tag": "OWL", "level": 1, "xp": "0", "isPublic": true }
// 409 if name or tag already taken
```

**GET `/guilds/:id/leaderboard`** → `200`

```json
{
  "data": [
    { "rank": 1, "characterId": "ckc7", "name": "Kade", "role": "OFFICER", "weeklyXp": 2400 },
    { "rank": 2, "characterId": "ckc1", "name": "Aria", "role": "LEADER", "weeklyXp": 2100 }
  ]
}
```

**POST `/guilds/:id/missions`**

```json
// request
{ "title": "Collective 50k XP", "metric": "XP", "targetValue": 50000, "rewardGold": 500, "expiresAt": "2026-08-01T00:00:00Z" }
// 201 -> mission
```

---

## 12. PvP (`/pvp`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/pvp` | Yes | List my challenges (filter by `status`) |
| POST | `/pvp` | Yes | Create a challenge |
| POST | `/pvp/:id/accept` | Yes | Accept a pending challenge (→ ACTIVE) |
| POST | `/pvp/:id/decline` | Yes | Decline/cancel |
| GET | `/pvp/:id` | Yes | Challenge detail + live scores |
| GET | `/pvp/:id/standings` | Yes | Current standings |

**POST `/pvp`**

```json
// request
{ "opponentId": "ckc9", "metric": "STUDY_MINUTES", "startAt": "2026-07-26T00:00:00Z", "endAt": "2026-08-02T00:00:00Z" }
// 201
{ "id": "ckp1", "challengerId": "ckc1", "opponentId": "ckc9", "metric": "STUDY_MINUTES", "status": "PENDING", "challengerScore": 0, "opponentScore": 0 }
```

**GET `/pvp/:id/standings`** → `200`

```json
{
  "status": "ACTIVE",
  "metric": "STUDY_MINUTES",
  "challenger": { "characterId": "ckc1", "name": "Aria", "score": 320 },
  "opponent": { "characterId": "ckc9", "name": "Rook", "score": 290 },
  "endAt": "2026-08-02T00:00:00Z",
  "winnerId": null
}
```

---

## 13. Stats / Insight (`/stats`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/stats/dashboard` | Yes | Aggregated dashboard KPIs |
| GET | `/stats/xp-series` | Yes | XP over time (query `range`, `bucket`) |
| GET | `/stats/skill-heatmap` | Yes | Per-skill activity heatmap |

**GET `/stats/dashboard`** → `200`

```json
{
  "level": 12, "totalXp": "18240", "gold": 1250,
  "questsCompletedToday": 4, "questsCompletedWeek": 22,
  "streak": { "current": 12, "longest": 34 },
  "activeBosses": 2, "achievementsUnlocked": 37
}
```

**GET `/stats/xp-series?range=30d&bucket=day`** → `200`

```json
{ "range": "30d", "bucket": "day", "points": [ { "t": "2026-07-24", "xp": 120 }, { "t": "2026-07-25", "xp": 90 } ] }
```

**GET `/stats/skill-heatmap?range=90d`** → `200`

```json
{
  "range": "90d",
  "skills": [
    { "key": "programming", "cells": [ { "date": "2026-07-25", "value": 30 } ] }
  ]
}
```

---

## 14. AI Coach (`/ai-coach`)

Rate-limited; premium-gated where noted.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/ai-coach/analyze` | Yes | Analyze progress, return insights |
| POST | `/ai-coach/generate-quests` | Yes | Suggest quests for a goal |
| POST | `/ai-coach/predict` | Yes | Predict level/goal ETA |

**POST `/ai-coach/generate-quests`**

```json
// request
{ "goal": "Get fit in 90 days", "skillKey": "fitness", "count": 5 }
// 200
{
  "suggestions": [
    { "title": "20-min run", "cadence": "DAILY", "difficulty": "MEDIUM", "xpReward": 20, "goldReward": 10, "skillKey": "fitness", "energyCost": 10 }
  ]
}
```

**POST `/ai-coach/predict`** → `200`

```json
{ "targetLevel": 20, "etaDays": 46, "confidence": 0.72, "basis": "trailing 30d XP velocity" }
```

---

## 15. Battle Pass (`/battle-pass`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/battle-pass/current` | Yes | Active season, tiers, my progress |
| POST | `/battle-pass/claim` | Yes | Claim a reward for a reached tier |

**GET `/battle-pass/current`** → `200`

```json
{
  "season": { "id": "cksn1", "name": "Season 3: Ember", "startAt": "2026-07-01T00:00:00Z", "endAt": "2026-09-30T00:00:00Z" },
  "progress": { "xp": 3200, "tier": 8, "isPremium": true, "claimedTiers": [1,2,3,4,5,6,7] },
  "tiers": [
    { "tier": 8, "xpRequired": 3000, "freeReward": { "type": "gold", "amount": 100 }, "premiumReward": { "type": "cosmetic", "refKey": "ember_frame" } }
  ]
}
```

**POST `/battle-pass/claim`**

```json
// request
{ "tier": 8 }
// 200
{ "claimedTiers": [1,2,3,4,5,6,7,8], "granted": { "free": { "type": "gold", "amount": 100 }, "premium": { "type": "cosmetic", "refKey": "ember_frame" } } }
// 409 if tier already claimed or not yet reached; premium rewards require isPremium
```

---

## 16. Subscription (`/subscription`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/subscription/status` | Yes | Current subscription state |
| POST | `/subscription/checkout` | Yes | Start Stripe checkout / IAP validation |
| POST | `/subscription/webhook` | No* | Provider webhook (signature-verified) |

\* `/subscription/webhook` is public but authenticated by **provider signature**
(Stripe signing secret / Apple-Google server notifications), not JWT.

**GET `/subscription/status`** → `200`

```json
{ "tier": "PREMIUM", "status": "ACTIVE", "provider": "STRIPE", "currentPeriodEnd": "2026-08-25T00:00:00Z", "cancelAtPeriodEnd": false }
```

**POST `/subscription/checkout`**

```json
// request (Stripe web)
{ "provider": "STRIPE", "priceId": "price_premium_monthly" }
// 200
{ "checkoutUrl": "https://checkout.stripe.com/c/pay/cs_..." }

// request (mobile IAP)
{ "provider": "APPLE_IAP", "receipt": "<base64-receipt>" }
// 200 -> validated, subscription upserted
{ "tier": "PREMIUM", "status": "ACTIVE", "provider": "APPLE_IAP" }
```

---

## 17. Notifications (`/notifications`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/notifications/token` | Yes | Register/refresh an FCM device token |
| DELETE | `/notifications/token` | Yes | Unregister a device token |

**POST `/notifications/token`**

```json
// request
{ "fcmToken": "fMEP...:APA91b...", "platform": "ios" }
// 201 (idempotent on fcmToken unique)
{ "registered": true }
```

---

## 18. WebSocket (Socket.IO)

Realtime uses Socket.IO over WSS. The JWT access token is passed in the handshake:

```js
const socket = io("wss://api.lifequest.app/pvp", {
  auth: { token: accessToken }
});
```

A `WsJwtGuard` validates the token; unauthorized handshakes are rejected. Fan-out
across API instances uses the **Redis Socket.IO adapter**.

### Namespaces & rooms

| Namespace | Rooms | Purpose |
|-----------|-------|---------|
| `/guild` | `guild:{guildId}` | Guild chat, mission progress |
| `/leaderboard` | `guild:{guildId}`, `global` | Live leaderboard updates |
| `/pvp` | `pvp:{challengeId}` | Live duel scores |
| `/character` | `character:{characterId}` | Personal XP/level-up toasts |

### `/guild`

Client → Server:

| Event | Payload | Notes |
|-------|---------|-------|
| `guild:join` | `{ guildId }` | Subscribe to the guild room (membership checked) |
| `guild:leave` | `{ guildId }` | Unsubscribe |
| `guild:message` | `{ guildId, body }` | Send a chat message (persists `GuildMessage`) |
| `guild:typing` | `{ guildId }` | Typing indicator |

Server → Client:

| Event | Payload |
|-------|---------|
| `guild:message` | `{ id, guildId, characterId, name, body, createdAt }` |
| `guild:typing` | `{ characterId, name }` |
| `guild:mission_progress` | `{ missionId, currentValue, targetValue, completed }` |
| `guild:member_joined` / `guild:member_left` | `{ characterId, name }` |

### `/leaderboard`

Client → Server: `leaderboard:subscribe` `{ scope: "guild"|"global", guildId? }`

Server → Client:

| Event | Payload |
|-------|---------|
| `leaderboard:update` | `{ scope, entries: [ { rank, characterId, name, weeklyXp } ] }` |

### `/pvp`

Client → Server: `pvp:subscribe` `{ challengeId }`

Server → Client:

| Event | Payload |
|-------|---------|
| `pvp:score` | `{ challengeId, challengerScore, opponentScore }` |
| `pvp:status` | `{ challengeId, status, winnerId? }` |

### `/character`

Server → Client (no client emits needed beyond connect):

| Event | Payload |
|-------|---------|
| `character:xp` | `{ delta, xp, totalXp, source }` |
| `character:level_up` | `{ level, unlocked: [ "..." ] }` |
| `character:achievement` | `{ id, name, rarity }` |
| `character:streak` | `{ current, longest }` |

---

## 19. Auth & Security Notes

- Access tokens are short-lived JWTs (~15 min); refresh tokens rotate on use and
  are stored **hashed** (`RefreshToken.tokenHash`), enabling revocation and reuse
  detection.
- RBAC: platform roles (`USER`/`ADMIN`) + guild roles (`LEADER`/`OFFICER`/`MEMBER`);
  every resource is ownership-scoped to the caller's `characterId`.
- All bodies validated (`class-validator`), unknown fields rejected.
- Webhooks verified by provider signature, never JWT.
- CORS allow-list; TLS/HSTS enforced at the edge.

## 20. Rate Limits

| Scope | Limit (default) |
|-------|-----------------|
| Global authenticated | ~100 req/min/user |
| `/auth/login`, `/auth/refresh` | ~10 req/min/IP |
| `/ai-coach/*` | ~10 req/min/user (premium: higher) |
| WS messages (`guild:message`) | ~5 msg/sec/socket |

Exceeding a limit returns `429` with the standard error envelope and a
`Retry-After` header.

---

## 21. Related Documents

- [ARCHITECTURE.md](ARCHITECTURE.md) — system design & cross-cutting concerns
- [DATABASE.md](DATABASE.md) — persistence model
- [ER_DIAGRAM.md](ER_DIAGRAM.md) — entity relationships
