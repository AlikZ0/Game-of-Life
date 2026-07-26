/**
 * Centralised, typed configuration loaded from environment variables.
 * Registered via `ConfigModule.forRoot({ load: [configuration] })`.
 */
export interface AppConfig {
  env: string;
  port: number;
  apiPrefix: string;
  corsOrigins: string[];
  logLevel: string;
}

export interface JwtConfig {
  accessSecret: string;
  accessTtl: number;
  refreshSecret: string;
  refreshTtl: number;
}

export interface RedisConfig {
  host: string;
  port: number;
  url: string;
}

export interface OAuthConfig {
  googleClientId?: string;
  appleClientId?: string;
}

export interface BillingConfig {
  stripeSecretKey?: string;
  stripeWebhookSecret?: string;
  stripePremiumPriceId?: string;
}

export interface FirebaseConfig {
  projectId?: string;
  clientEmail?: string;
  privateKey?: string;
}

export interface AiConfig {
  provider: string;
  apiKey?: string;
  model: string;
}

export interface Configuration {
  app: AppConfig;
  database: { url: string };
  redis: RedisConfig;
  jwt: JwtConfig;
  oauth: OAuthConfig;
  billing: BillingConfig;
  firebase: FirebaseConfig;
  ai: AiConfig;
  throttle: { ttl: number; limit: number };
}

const toInt = (v: string | undefined, fallback: number): number => {
  const n = Number(v);
  return Number.isFinite(n) ? n : fallback;
};

export default (): Configuration => ({
  app: {
    env: process.env.NODE_ENV ?? 'development',
    port: toInt(process.env.PORT, 3000),
    apiPrefix: process.env.API_PREFIX ?? 'api/v1',
    corsOrigins: (process.env.CORS_ORIGINS ?? '*')
      .split(',')
      .map((s) => s.trim()),
    logLevel: process.env.LOG_LEVEL ?? 'info',
  },
  database: {
    url: process.env.DATABASE_URL ?? '',
  },
  redis: {
    host: process.env.REDIS_HOST ?? 'localhost',
    port: toInt(process.env.REDIS_PORT, 6379),
    url: process.env.REDIS_URL ?? 'redis://localhost:6379',
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET ?? 'dev-access-secret',
    accessTtl: toInt(process.env.JWT_ACCESS_TTL, 900),
    refreshSecret: process.env.JWT_REFRESH_SECRET ?? 'dev-refresh-secret',
    refreshTtl: toInt(process.env.JWT_REFRESH_TTL, 2592000),
  },
  oauth: {
    googleClientId: process.env.GOOGLE_CLIENT_ID,
    appleClientId: process.env.APPLE_CLIENT_ID,
  },
  billing: {
    stripeSecretKey: process.env.STRIPE_SECRET_KEY,
    stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
    stripePremiumPriceId: process.env.STRIPE_PREMIUM_PRICE_ID,
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY,
  },
  ai: {
    provider: process.env.AI_PROVIDER ?? 'anthropic',
    apiKey: process.env.AI_API_KEY,
    model: process.env.AI_MODEL ?? 'claude-sonnet-5',
  },
  throttle: {
    ttl: toInt(process.env.THROTTLE_TTL, 60),
    limit: toInt(process.env.THROTTLE_LIMIT, 120),
  },
});
