# ============================================================================
#  Life Quest — Backend (NestJS) production image
#  Multi-stage build:  deps → build → runtime
#  - Node 20 Alpine, non-root user
#  - Prisma client generated at build time
#  - Final stage ships only prod deps + compiled dist + prisma schema
# ============================================================================

# ─────────────────────────────── 1. deps ───────────────────────────────────
# Installs the FULL dependency tree (incl. devDeps) needed to build + generate.
FROM node:20-alpine AS deps
WORKDIR /app

# libc compat + openssl are required by Prisma engines on Alpine.
RUN apk add --no-cache libc6-compat openssl

# Copy only manifests first to maximise Docker layer caching.
COPY package*.json ./
COPY prisma ./prisma

# Deterministic install of the complete dependency tree.
RUN npm ci

# ─────────────────────────────── 2. build ──────────────────────────────────
# Compiles TypeScript (nest build) and generates the Prisma client.
FROM node:20-alpine AS build
WORKDIR /app

RUN apk add --no-cache libc6-compat openssl

# Reuse the already-installed node_modules from the deps stage.
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate the Prisma client against the schema, then compile the app.
RUN npx prisma generate
RUN npm run build

# Strip devDependencies so we can copy a lean, prod-only node_modules
# into the runtime stage (keeps the Prisma client that was just generated).
RUN npm prune --omit=dev

# ─────────────────────────────── 3. runtime ────────────────────────────────
# Minimal image that actually runs in production.
FROM node:20-alpine AS runtime
WORKDIR /app

# openssl needed at runtime by the Prisma query engine; wget for healthcheck.
RUN apk add --no-cache libc6-compat openssl wget \
    && addgroup -g 1001 -S nodejs \
    && adduser  -u 1001 -S nestjs -G nodejs

ENV NODE_ENV=production \
    PORT=3000

# Copy prod-only deps + generated Prisma client from the build stage.
COPY --from=build --chown=nestjs:nodejs /app/node_modules ./node_modules
# Compiled application code.
COPY --from=build --chown=nestjs:nodejs /app/dist ./dist
# Prisma schema + migrations (needed for `prisma migrate deploy` at deploy time).
COPY --from=build --chown=nestjs:nodejs /app/prisma ./prisma
# package.json for runtime metadata / npm scripts.
COPY --from=build --chown=nestjs:nodejs /app/package.json ./package.json

USER nestjs

EXPOSE 3000

# Container-level healthcheck against the app's health endpoint.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:${PORT}/api/v1/health || exit 1

# Default command runs the API. The worker container overrides this with
# `node dist/worker.js` (see docker-compose / k8s worker-deployment).
CMD ["node", "dist/main.js"]
