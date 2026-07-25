-- CreateEnum
CREATE TYPE "AuthProvider" AS ENUM ('EMAIL', 'GOOGLE', 'APPLE');

-- CreateEnum
CREATE TYPE "CharacterClass" AS ENUM ('WARRIOR', 'MAGE', 'ROGUE', 'RANGER', 'PALADIN');

-- CreateEnum
CREATE TYPE "QuestCadence" AS ENUM ('DAILY', 'WEEKLY', 'MONTHLY', 'ONE_OFF');

-- CreateEnum
CREATE TYPE "Difficulty" AS ENUM ('TRIVIAL', 'EASY', 'MEDIUM', 'HARD', 'EPIC');

-- CreateEnum
CREATE TYPE "QuestStatus" AS ENUM ('ACTIVE', 'COMPLETED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "CompletionSource" AS ENUM ('MANUAL', 'TIMER', 'INTEGRATION');

-- CreateEnum
CREATE TYPE "Rarity" AS ENUM ('BRONZE', 'SILVER', 'GOLD', 'LEGENDARY');

-- CreateEnum
CREATE TYPE "BossStatus" AS ENUM ('ACTIVE', 'DEFEATED', 'ABANDONED');

-- CreateEnum
CREATE TYPE "ItemType" AS ENUM ('COSMETIC_AVATAR', 'COSMETIC_THEME', 'COSMETIC_FRAME', 'TITLE', 'REWARD_COUPON', 'CONSUMABLE_STREAK_FREEZE', 'CONSUMABLE_ENERGY_POTION');

-- CreateEnum
CREATE TYPE "GuildRole" AS ENUM ('LEADER', 'OFFICER', 'MEMBER');

-- CreateEnum
CREATE TYPE "PvpMetric" AS ENUM ('XP', 'QUESTS_COMPLETED', 'STUDY_MINUTES', 'WORKOUT_MINUTES', 'STEPS');

-- CreateEnum
CREATE TYPE "PvpStatus" AS ENUM ('PENDING', 'ACTIVE', 'FINISHED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SubscriptionTier" AS ENUM ('FREE', 'PREMIUM');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('ACTIVE', 'TRIALING', 'PAST_DUE', 'CANCELLED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "BillingProvider" AS ENUM ('STRIPE', 'APPLE_IAP', 'GOOGLE_PLAY');

-- CreateEnum
CREATE TYPE "LedgerReason" AS ENUM ('QUEST_REWARD', 'BOSS_REWARD', 'ACHIEVEMENT_REWARD', 'STREAK_MILESTONE', 'BATTLE_PASS', 'SHOP_PURCHASE', 'ADMIN_ADJUSTMENT', 'PVP_REWARD');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT,
    "provider" "AuthProvider" NOT NULL DEFAULT 'EMAIL',
    "provider_id" TEXT,
    "email_verified" BOOLEAN NOT NULL DEFAULT false,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "last_login_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "token_hash" TEXT NOT NULL,
    "user_agent" TEXT,
    "ip" TEXT,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_tokens" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "fcm_token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "characters" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "avatar_key" TEXT NOT NULL DEFAULT 'default',
    "class" "CharacterClass" NOT NULL DEFAULT 'RANGER',
    "level" INTEGER NOT NULL DEFAULT 1,
    "xp" INTEGER NOT NULL DEFAULT 0,
    "total_xp" BIGINT NOT NULL DEFAULT 0,
    "gold" INTEGER NOT NULL DEFAULT 0,
    "hp" INTEGER NOT NULL DEFAULT 100,
    "max_hp" INTEGER NOT NULL DEFAULT 100,
    "energy" INTEGER NOT NULL DEFAULT 100,
    "max_energy" INTEGER NOT NULL DEFAULT 100,
    "active_title" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "characters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "skills" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "icon" TEXT NOT NULL DEFAULT 'bolt',
    "color" TEXT NOT NULL DEFAULT '#7C5CFF',
    "level" INTEGER NOT NULL DEFAULT 1,
    "xp" INTEGER NOT NULL DEFAULT 0,
    "total_xp" BIGINT NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "skills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "skill_xp_events" (
    "id" TEXT NOT NULL,
    "skill_id" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,
    "source" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "skill_xp_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quests" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "cadence" "QuestCadence" NOT NULL DEFAULT 'DAILY',
    "difficulty" "Difficulty" NOT NULL DEFAULT 'MEDIUM',
    "status" "QuestStatus" NOT NULL DEFAULT 'ACTIVE',
    "xp_reward" INTEGER NOT NULL DEFAULT 20,
    "gold_reward" INTEGER NOT NULL DEFAULT 10,
    "skill_key" TEXT,
    "energy_cost" INTEGER NOT NULL DEFAULT 10,
    "repeat_rule" JSONB,
    "due_at" TIMESTAMP(3),
    "boss_id" TEXT,
    "damage" INTEGER NOT NULL DEFAULT 10,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "archived_at" TIMESTAMP(3),

    CONSTRAINT "quests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quest_completions" (
    "id" TEXT NOT NULL,
    "quest_id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "completed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "period_key" TEXT NOT NULL,
    "xp_awarded" INTEGER NOT NULL,
    "gold_awarded" INTEGER NOT NULL,
    "source" "CompletionSource" NOT NULL DEFAULT 'MANUAL',

    CONSTRAINT "quest_completions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bosses" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "image_key" TEXT NOT NULL DEFAULT 'boss_default',
    "max_hp" INTEGER NOT NULL,
    "current_hp" INTEGER NOT NULL,
    "status" "BossStatus" NOT NULL DEFAULT 'ACTIVE',
    "reward_xp" INTEGER NOT NULL DEFAULT 500,
    "reward_gold" INTEGER NOT NULL DEFAULT 250,
    "reward_item_id" TEXT,
    "deadline" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "defeated_at" TIMESTAMP(3),

    CONSTRAINT "bosses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "achievements" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "rarity" "Rarity" NOT NULL,
    "icon" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "reward_xp" INTEGER NOT NULL DEFAULT 0,
    "reward_gold" INTEGER NOT NULL DEFAULT 0,
    "criteria" JSONB NOT NULL,
    "is_secret" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "character_achievements" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "achievement_id" TEXT NOT NULL,
    "progress" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "unlocked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "character_achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "inventory_items" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "item_type" "ItemType" NOT NULL,
    "ref_key" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL DEFAULT 1,
    "equipped" BOOLEAN NOT NULL DEFAULT false,
    "metadata" JSONB,
    "acquired_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shop_rewards" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "icon" TEXT NOT NULL DEFAULT 'gift',
    "gold_cost" INTEGER NOT NULL,
    "stock" INTEGER,
    "times_redeemed" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shop_rewards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gold_ledger_entries" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "delta" INTEGER NOT NULL,
    "balance" INTEGER NOT NULL,
    "reason" "LedgerReason" NOT NULL,
    "ref_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gold_ledger_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "streaks" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "current" INTEGER NOT NULL DEFAULT 0,
    "longest" INTEGER NOT NULL DEFAULT 0,
    "freeze_count" INTEGER NOT NULL DEFAULT 0,
    "last_active_day" TEXT,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "streaks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guilds" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "tag" TEXT NOT NULL,
    "description" TEXT,
    "emblem_key" TEXT NOT NULL DEFAULT 'emblem_default',
    "xp" BIGINT NOT NULL DEFAULT 0,
    "level" INTEGER NOT NULL DEFAULT 1,
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guilds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guild_members" (
    "id" TEXT NOT NULL,
    "guild_id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "role" "GuildRole" NOT NULL DEFAULT 'MEMBER',
    "weekly_xp" INTEGER NOT NULL DEFAULT 0,
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guild_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guild_missions" (
    "id" TEXT NOT NULL,
    "guild_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "target_value" INTEGER NOT NULL,
    "current_value" INTEGER NOT NULL DEFAULT 0,
    "metric" "PvpMetric" NOT NULL DEFAULT 'XP',
    "reward_gold" INTEGER NOT NULL DEFAULT 0,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guild_missions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "guild_messages" (
    "id" TEXT NOT NULL,
    "guild_id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "guild_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pvp_challenges" (
    "id" TEXT NOT NULL,
    "challenger_id" TEXT NOT NULL,
    "opponent_id" TEXT NOT NULL,
    "metric" "PvpMetric" NOT NULL,
    "status" "PvpStatus" NOT NULL DEFAULT 'PENDING',
    "start_at" TIMESTAMP(3) NOT NULL,
    "end_at" TIMESTAMP(3) NOT NULL,
    "challenger_score" INTEGER NOT NULL DEFAULT 0,
    "opponent_score" INTEGER NOT NULL DEFAULT 0,
    "winner_id" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pvp_challenges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "seasons" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "start_at" TIMESTAMP(3) NOT NULL,
    "end_at" TIMESTAMP(3) NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "seasons_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "battle_pass_tiers" (
    "id" TEXT NOT NULL,
    "season_id" TEXT NOT NULL,
    "tier" INTEGER NOT NULL,
    "xp_required" INTEGER NOT NULL,
    "free_reward" JSONB,
    "premium_reward" JSONB,

    CONSTRAINT "battle_pass_tiers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "battle_pass_progress" (
    "id" TEXT NOT NULL,
    "character_id" TEXT NOT NULL,
    "season_id" TEXT NOT NULL,
    "xp" INTEGER NOT NULL DEFAULT 0,
    "tier" INTEGER NOT NULL DEFAULT 0,
    "is_premium" BOOLEAN NOT NULL DEFAULT false,
    "claimed_tiers" INTEGER[] DEFAULT ARRAY[]::INTEGER[],
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "battle_pass_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "tier" "SubscriptionTier" NOT NULL DEFAULT 'FREE',
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
    "provider" "BillingProvider",
    "external_id" TEXT,
    "current_period_end" TIMESTAMP(3),
    "cancel_at_period_end" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "user_id" TEXT,
    "action" TEXT NOT NULL,
    "entity" TEXT,
    "entity_id" TEXT,
    "metadata" JSONB,
    "ip" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "users_provider_provider_id_key" ON "users"("provider", "provider_id");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "notification_tokens_fcm_token_key" ON "notification_tokens"("fcm_token");

-- CreateIndex
CREATE INDEX "notification_tokens_user_id_idx" ON "notification_tokens"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "characters_user_id_key" ON "characters"("user_id");

-- CreateIndex
CREATE INDEX "skills_character_id_idx" ON "skills"("character_id");

-- CreateIndex
CREATE UNIQUE INDEX "skills_character_id_key_key" ON "skills"("character_id", "key");

-- CreateIndex
CREATE INDEX "skill_xp_events_skill_id_created_at_idx" ON "skill_xp_events"("skill_id", "created_at");

-- CreateIndex
CREATE INDEX "quests_character_id_status_idx" ON "quests"("character_id", "status");

-- CreateIndex
CREATE INDEX "quests_character_id_cadence_idx" ON "quests"("character_id", "cadence");

-- CreateIndex
CREATE INDEX "quest_completions_character_id_completed_at_idx" ON "quest_completions"("character_id", "completed_at");

-- CreateIndex
CREATE UNIQUE INDEX "quest_completions_quest_id_period_key_key" ON "quest_completions"("quest_id", "period_key");

-- CreateIndex
CREATE INDEX "bosses_character_id_status_idx" ON "bosses"("character_id", "status");

-- CreateIndex
CREATE INDEX "character_achievements_character_id_idx" ON "character_achievements"("character_id");

-- CreateIndex
CREATE UNIQUE INDEX "character_achievements_character_id_achievement_id_key" ON "character_achievements"("character_id", "achievement_id");

-- CreateIndex
CREATE INDEX "inventory_items_character_id_item_type_idx" ON "inventory_items"("character_id", "item_type");

-- CreateIndex
CREATE INDEX "shop_rewards_character_id_is_active_idx" ON "shop_rewards"("character_id", "is_active");

-- CreateIndex
CREATE INDEX "gold_ledger_entries_character_id_created_at_idx" ON "gold_ledger_entries"("character_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "streaks_character_id_key" ON "streaks"("character_id");

-- CreateIndex
CREATE UNIQUE INDEX "guilds_name_key" ON "guilds"("name");

-- CreateIndex
CREATE UNIQUE INDEX "guilds_tag_key" ON "guilds"("tag");

-- CreateIndex
CREATE UNIQUE INDEX "guild_members_character_id_key" ON "guild_members"("character_id");

-- CreateIndex
CREATE INDEX "guild_members_guild_id_idx" ON "guild_members"("guild_id");

-- CreateIndex
CREATE INDEX "guild_missions_guild_id_idx" ON "guild_missions"("guild_id");

-- CreateIndex
CREATE INDEX "guild_messages_guild_id_created_at_idx" ON "guild_messages"("guild_id", "created_at");

-- CreateIndex
CREATE INDEX "pvp_challenges_challenger_id_status_idx" ON "pvp_challenges"("challenger_id", "status");

-- CreateIndex
CREATE INDEX "pvp_challenges_opponent_id_status_idx" ON "pvp_challenges"("opponent_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "battle_pass_tiers_season_id_tier_key" ON "battle_pass_tiers"("season_id", "tier");

-- CreateIndex
CREATE UNIQUE INDEX "battle_pass_progress_character_id_season_id_key" ON "battle_pass_progress"("character_id", "season_id");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_user_id_key" ON "subscriptions"("user_id");

-- CreateIndex
CREATE INDEX "audit_logs_user_id_created_at_idx" ON "audit_logs"("user_id", "created_at");

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_tokens" ADD CONSTRAINT "notification_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "characters" ADD CONSTRAINT "characters_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "skills" ADD CONSTRAINT "skills_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "skill_xp_events" ADD CONSTRAINT "skill_xp_events_skill_id_fkey" FOREIGN KEY ("skill_id") REFERENCES "skills"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quests" ADD CONSTRAINT "quests_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quests" ADD CONSTRAINT "quests_boss_id_fkey" FOREIGN KEY ("boss_id") REFERENCES "bosses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quest_completions" ADD CONSTRAINT "quest_completions_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "quests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quest_completions" ADD CONSTRAINT "quest_completions_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bosses" ADD CONSTRAINT "bosses_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "character_achievements" ADD CONSTRAINT "character_achievements_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "character_achievements" ADD CONSTRAINT "character_achievements_achievement_id_fkey" FOREIGN KEY ("achievement_id") REFERENCES "achievements"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "inventory_items" ADD CONSTRAINT "inventory_items_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shop_rewards" ADD CONSTRAINT "shop_rewards_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gold_ledger_entries" ADD CONSTRAINT "gold_ledger_entries_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "streaks" ADD CONSTRAINT "streaks_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guild_members" ADD CONSTRAINT "guild_members_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guild_members" ADD CONSTRAINT "guild_members_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guild_missions" ADD CONSTRAINT "guild_missions_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "guild_messages" ADD CONSTRAINT "guild_messages_guild_id_fkey" FOREIGN KEY ("guild_id") REFERENCES "guilds"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "battle_pass_tiers" ADD CONSTRAINT "battle_pass_tiers_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "seasons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "battle_pass_progress" ADD CONSTRAINT "battle_pass_progress_character_id_fkey" FOREIGN KEY ("character_id") REFERENCES "characters"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "battle_pass_progress" ADD CONSTRAINT "battle_pass_progress_season_id_fkey" FOREIGN KEY ("season_id") REFERENCES "seasons"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

