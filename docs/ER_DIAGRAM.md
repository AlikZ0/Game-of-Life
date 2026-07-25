# Life Quest — Entity-Relationship Diagrams

> Mermaid `erDiagram` views generated from
> [`backend/prisma/schema.prisma`](../backend/prisma/schema.prisma).
> Split into logical groups for readability, plus a high-level overview.
>
> Cardinality notation: `||--o{` = one-to-many (optional many), `||--||` =
> one-to-one, `||--o|` = one-to-optional-one. Only key attributes are shown; see
> [DATABASE.md](DATABASE.md) for the full column list.

---

## 1. High-Level Overview

The `Character` is the hub; `User` is the identity root. Everything a player owns
hangs off `Character`.

```mermaid
erDiagram
  User        ||--o| Character   : "has"
  User        ||--o{ RefreshToken : "sessions"
  User        ||--o{ NotificationToken : "devices"
  User        ||--o| Subscription : "billing"
  User        ||--o{ AuditLog     : "audited"

  Character   ||--o{ Skill        : "trains"
  Character   ||--o{ Quest        : "owns"
  Character   ||--o{ Boss         : "fights"
  Character   ||--o{ CharacterAchievement : "earns"
  Character   ||--o{ InventoryItem : "holds"
  Character   ||--o{ ShopReward   : "defines"
  Character   ||--o{ GoldLedgerEntry : "ledger"
  Character   ||--o| Streak       : "keeps"
  Character   ||--o| GuildMember  : "joins"
  Character   ||--o{ BattlePassProgress : "progresses"

  Guild       ||--o{ GuildMember  : "has"
  Season      ||--o{ BattlePassTier : "defines"
  Achievement ||--o{ CharacterAchievement : "unlocked as"
```

---

## 2. Identity + Character

```mermaid
erDiagram
  User ||--o| Character : "1:1"
  User ||--o{ RefreshToken : "has"
  User ||--o{ NotificationToken : "has"
  User ||--o| Subscription : "has"
  User ||--o{ AuditLog : "generates"

  User {
    string id PK
    string email UK
    string password_hash "nullable (OAuth)"
    enum   provider "EMAIL|GOOGLE|APPLE"
    string provider_id
    bool   email_verified
    bool   is_active
    datetime last_login_at
  }

  RefreshToken {
    string id PK
    string user_id FK
    string token_hash UK
    string user_agent
    string ip
    datetime expires_at
    datetime revoked_at
  }

  NotificationToken {
    string id PK
    string user_id FK
    string fcm_token UK
    string platform "ios|android"
  }

  AuditLog {
    string id PK
    string user_id FK "SetNull"
    string action
    string entity
    string entity_id
    json   metadata
  }

  Character {
    string id PK
    string user_id FK,UK
    string name
    string avatar_key
    enum   class "WARRIOR|MAGE|ROGUE|RANGER|PALADIN"
    int    level
    int    xp "within level"
    bigint total_xp
    int    gold
    int    hp
    int    max_hp
    int    energy
    int    max_energy
    string active_title
  }
```

---

## 3. Quests + Bosses + Skills

```mermaid
erDiagram
  Character ||--o{ Quest : "owns"
  Character ||--o{ Boss : "fights"
  Character ||--o{ Skill : "trains"
  Character ||--o{ QuestCompletion : "records"
  Boss     ||--o{ Quest : "targeted by"
  Quest    ||--o{ QuestCompletion : "completed as"
  Skill    ||--o{ SkillXpEvent : "logs"

  Quest {
    string id PK
    string character_id FK
    string title
    enum   cadence "DAILY|WEEKLY|MONTHLY|ONE_OFF"
    enum   difficulty "TRIVIAL..EPIC"
    enum   status "ACTIVE|COMPLETED|ARCHIVED"
    int    xp_reward
    int    gold_reward
    string skill_key
    int    energy_cost
    json   repeat_rule
    datetime due_at
    string boss_id FK "SetNull"
    int    damage
    datetime archived_at
  }

  QuestCompletion {
    string id PK
    string quest_id FK
    string character_id FK
    datetime completed_at
    string period_key "UK with quest_id"
    int    xp_awarded
    int    gold_awarded
    enum   source "MANUAL|TIMER|INTEGRATION"
  }

  Boss {
    string id PK
    string character_id FK
    string name
    string image_key
    int    max_hp
    int    current_hp
    enum   status "ACTIVE|DEFEATED|ABANDONED"
    int    reward_xp
    int    reward_gold
    string reward_item_id
    datetime deadline
    datetime defeated_at
  }

  Skill {
    string id PK
    string character_id FK
    string key "UK with character_id"
    string name
    string icon
    string color
    int    level
    int    xp
    bigint total_xp
  }

  SkillXpEvent {
    string id PK
    string skill_id FK
    int    amount
    string source "questId|manual"
    datetime created_at
  }
```

> Idempotency: `QuestCompletion` carries a unique `(quest_id, period_key)` — one
> completion per quest per cadence period.

---

## 4. Achievements + Economy + Streaks

```mermaid
erDiagram
  Achievement ||--o{ CharacterAchievement : "unlocked as"
  Character   ||--o{ CharacterAchievement : "earns"
  Character   ||--o{ InventoryItem : "holds"
  Character   ||--o{ ShopReward : "defines"
  Character   ||--o{ GoldLedgerEntry : "ledger"
  Character   ||--o| Streak : "keeps"

  Achievement {
    string id PK "slug"
    string name
    enum   rarity "BRONZE|SILVER|GOLD|LEGENDARY"
    string category
    int    reward_xp
    int    reward_gold
    json   criteria
    bool   is_secret
  }

  CharacterAchievement {
    string id PK
    string character_id FK
    string achievement_id FK
    float  progress "0..1"
    datetime unlocked_at
  }

  InventoryItem {
    string id PK
    string character_id FK
    enum   item_type "COSMETIC_*|TITLE|REWARD_COUPON|CONSUMABLE_*"
    string ref_key
    string name
    int    quantity
    bool   equipped
    json   metadata
  }

  ShopReward {
    string id PK
    string character_id FK
    string title
    int    gold_cost
    int    stock "null=unlimited"
    int    times_redeemed
    bool   is_active
  }

  GoldLedgerEntry {
    string id PK
    string character_id FK
    int    delta "+/-"
    int    balance "running"
    enum   reason "QUEST_REWARD|BOSS_REWARD|..."
    string ref_id
    datetime created_at
  }

  Streak {
    string id PK
    string character_id FK,UK
    int    current
    int    longest
    int    freeze_count
    string last_active_day "YYYY-MM-DD"
  }
```

---

## 5. Social (Guilds + PvP)

```mermaid
erDiagram
  Guild     ||--o{ GuildMember : "has"
  Guild     ||--o{ GuildMission : "runs"
  Guild     ||--o{ GuildMessage : "chat"
  Character ||--o| GuildMember : "membership"

  Guild {
    string id PK
    string name UK
    string tag UK "2-5 chars"
    string emblem_key
    bigint xp
    int    level
    bool   is_public
  }

  GuildMember {
    string id PK
    string guild_id FK
    string character_id FK,UK
    enum   role "LEADER|OFFICER|MEMBER"
    int    weekly_xp
    datetime joined_at
  }

  GuildMission {
    string id PK
    string guild_id FK
    string title
    int    target_value
    int    current_value
    enum   metric "XP|QUESTS_COMPLETED|STUDY_MINUTES|WORKOUT_MINUTES|STEPS"
    int    reward_gold
    datetime expires_at
    datetime completed_at
  }

  GuildMessage {
    string id PK
    string guild_id FK
    string character_id
    string body
    datetime created_at
  }

  PvpChallenge {
    string id PK
    string challenger_id "characterId"
    string opponent_id "characterId"
    enum   metric "XP|QUESTS_COMPLETED|..."
    enum   status "PENDING|ACTIVE|FINISHED|CANCELLED"
    datetime start_at
    datetime end_at
    int    challenger_score
    int    opponent_score
    string winner_id
  }
```

> `PvpChallenge` references characters by id (`challenger_id`, `opponent_id`,
> `winner_id`) without hard FK relations in the schema — duels are resolved at the
> application layer.

---

## 6. Monetization (Battle Pass + Subscription)

```mermaid
erDiagram
  Season   ||--o{ BattlePassTier : "defines"
  Season   ||--o{ BattlePassProgress : "tracked by"
  Character ||--o{ BattlePassProgress : "progresses"
  User     ||--o| Subscription : "has"

  Season {
    string id PK
    string name
    datetime start_at
    datetime end_at
    bool   is_active
  }

  BattlePassTier {
    string id PK
    string season_id FK
    int    tier "UK with season_id"
    int    xp_required
    json   free_reward
    json   premium_reward
  }

  BattlePassProgress {
    string id PK
    string character_id FK
    string season_id FK
    int    xp
    int    tier
    bool   is_premium
    int_array claimed_tiers
  }

  Subscription {
    string id PK
    string user_id FK,UK
    enum   tier "FREE|PREMIUM"
    enum   status "ACTIVE|TRIALING|PAST_DUE|CANCELLED|EXPIRED"
    enum   provider "STRIPE|APPLE_IAP|GOOGLE_PLAY"
    string external_id
    datetime current_period_end
    bool   cancel_at_period_end
  }
```

> `BattlePassProgress` is unique per `(character_id, season_id)`;
> `BattlePassTier` is unique per `(season_id, tier)`.

---

## 7. Related Documents

- [DATABASE.md](DATABASE.md) — table-by-table reference
- [ARCHITECTURE.md](ARCHITECTURE.md) — bounded contexts & system design
