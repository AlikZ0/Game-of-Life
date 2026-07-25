# ⚙️ Life Quest — Infrastructure

Deployment assets for the Life Quest platform: local Docker Compose stack,
production Kubernetes manifests (Kustomize base + overlays), Nginx reverse
proxy, and CI/CD workflows.

```
infra/
├── docker-compose.yml            # base stack: postgres, redis, api, worker, nginx
├── docker-compose.override.yml   # dev conveniences (hot reload, exposed ports)
├── nginx/nginx.conf              # reverse proxy (local/dev)
├── k8s/
│   ├── base/                     # env-agnostic manifests + kustomization.yaml
│   └── overlays/
│       ├── staging/              # staging patches (replicas, host, tag)
│       └── prod/                 # prod patches (replicas, host, tag)
└── README.md                     # you are here
```

CI/CD lives at repo root under `.github/workflows/` (`ci.yml`, `deploy.yml`).

---

## 🐳 Run locally with Docker Compose

```bash
cd infra
cp ../backend/.env.example ../backend/.env      # fill in JWT secrets etc.
docker compose up --build
```

This starts Postgres 16, Redis 7, the NestJS **api** (runs `prisma migrate
deploy` then boots), the BullMQ **worker**, and **nginx**.

| Service   | URL                                  |
|-----------|--------------------------------------|
| API       | http://localhost:3000/api/v1         |
| Swagger   | http://localhost:3000/docs           |
| Health    | http://localhost:3000/api/v1/health  |
| Via Nginx | http://localhost/api/v1/health       |

The dev override (auto-merged) enables **hot reload** (`npm run start:dev`),
bind-mounts `../backend`, and exposes Postgres `5432` / Redis `6379` to the host.

Production-like run (base file only, no bind mounts / hot reload):

```bash
docker compose -f docker-compose.yml up --build
```

Common commands:

```bash
docker compose logs -f api worker      # tail logs
docker compose exec api sh             # shell into the API container
docker compose down -v                 # stop and wipe volumes
```

---

## ☸️ Deploy to Kubernetes

Manifests use **Kustomize** (`base` + `overlays/staging` + `overlays/prod`).

### Prerequisites
- A cluster with **ingress-nginx**, **cert-manager** (ClusterIssuer
  `letsencrypt-prod`), **metrics-server** (for the HPA), and a
  NetworkPolicy-capable CNI (Calico/Cilium).
- The backend image pushed to `ghcr.io/<owner>/api`.
- The **Secret** provisioned out-of-band (see below) — it is *not* in the
  kustomization on purpose.

### 1. Provision secrets (never commit plaintext)
`k8s/base/secret.example.yaml` documents the exact keys the app expects. Use
one of:
- **Sealed Secrets** — `kubeseal` the real Secret, commit the SealedSecret.
- **SOPS + age/KMS** — encrypt `secret.yaml`, decrypt in CI before apply.
- **External Secrets Operator** — sync from AWS Secrets Manager / Vault / GCP SM.

### 2. Apply an overlay
```bash
# Staging
kubectl apply -k infra/k8s/overlays/staging

# Production
kubectl apply -k infra/k8s/overlays/prod
```

### 3. Migrations
The `migrate` Job runs `npx prisma migrate deploy`. CI (`deploy.yml`) recreates
and waits on it before the rollout. Manually:

```bash
kubectl -n lifequest delete job/migrate --ignore-not-found
kubectl apply -k infra/k8s/overlays/prod
kubectl -n lifequest wait --for=condition=complete job/migrate --timeout=300s
kubectl -n lifequest rollout status deployment/api
```

### Database in production
The in-cluster `postgres` StatefulSet is fine for staging/self-hosted, but for
production a **managed database (RDS / Cloud SQL)** is strongly recommended
(backups, HA, PITR). To switch: point `DATABASE_URL` at the managed endpoint and
drop the StatefulSet from the prod overlay.

---

## 🔐 Environment variables

Consumed by the API, worker and migrate Job. Non-secret values live in the
ConfigMap; sensitive ones in the Secret.

| Variable | Required | Source | Description |
|----------|:--------:|--------|-------------|
| `NODE_ENV` | ✓ | ConfigMap | `development` / `staging` / `production` |
| `PORT` | ✓ | ConfigMap | HTTP port (default `3000`) |
| `API_PREFIX` | ✓ | ConfigMap | Path prefix (`api/v1`) |
| `DATABASE_URL` | ✓ | **Secret** | Postgres connection string |
| `REDIS_URL` | ✓ | ConfigMap | Redis connection URL |
| `REDIS_HOST` / `REDIS_PORT` | ✓ | ConfigMap | Redis host/port (alt to URL) |
| `JWT_ACCESS_SECRET` | ✓ | **Secret** | Access-token signing secret |
| `JWT_REFRESH_SECRET` | ✓ | **Secret** | Refresh-token signing secret |
| `JWT_ACCESS_TTL` | – | ConfigMap | Access token TTL (seconds) |
| `JWT_REFRESH_TTL` | – | ConfigMap | Refresh token TTL (seconds) |
| `CORS_ORIGINS` | – | ConfigMap | Comma-separated allowed origins |
| `THROTTLE_TTL` / `THROTTLE_LIMIT` | – | ConfigMap | Rate limiting |
| `LOG_LEVEL` | – | ConfigMap | `debug` / `info` / `warn` |
| `STRIPE_SECRET_KEY` | – | **Secret** | Stripe API key (monetization) |
| `STRIPE_WEBHOOK_SECRET` | – | **Secret** | Stripe webhook signing secret |
| `FIREBASE_PROJECT_ID` | – | **Secret** | FCM project id (push) |
| `FIREBASE_CLIENT_EMAIL` | – | **Secret** | FCM service-account email |
| `FIREBASE_PRIVATE_KEY` | – | **Secret** | FCM service-account key |
| `AI_API_KEY` | – | **Secret** | AI Coach provider key |

For local dev these come from `backend/.env` (`env_file` in compose). See
`backend/.env.example`.

---

## 📈 Scaling notes

- **API** scales horizontally behind the Service via the **HPA**
  (`hpa.yaml`): CPU 70% / memory 80%, staging 1–3 replicas, prod 3–20.
  Requires metrics-server.
- **Worker** scales by replica count (BullMQ distributes jobs across
  consumers on the same Redis). Prod defaults to 2; raise for heavier queues.
- **Rolling updates** with `maxUnavailable: 0` keep the API available during
  deploys; readiness/startup probes gate traffic until `/api/v1/health` is OK.
- **Redis** is single-writer (`strategy: Recreate`); for durable/HA queues use
  managed Redis and point `REDIS_URL` at it.
- **Postgres**: vertical-scale the managed instance and add read replicas as
  needed; the app writes to the primary via `DATABASE_URL`.
- **NetworkPolicies** enforce default-deny ingress; only ingress-nginx reaches
  the API, and only api/worker/migrate reach Postgres/Redis.

---

## 🔁 CI/CD

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `.github/workflows/ci.yml` | PR / push to `main`,`develop` | Node matrix: install, lint, prisma generate, unit + e2e (pg+redis services), build, Docker smoke build; Flutter analyze |
| `.github/workflows/deploy.yml` | push to `main` / `v*` tag | Build & push image to GHCR, run migrate Job, `kubectl apply -k` staging (main) or prod (tag) |

`deploy.yml` uses GitHub **Environments** (`staging` / `production`) for
required reviewers and per-env secrets (`KUBE_CONFIG_STAGING`,
`KUBE_CONFIG_PROD`). GHCR auth uses the built-in `GITHUB_TOKEN`.
