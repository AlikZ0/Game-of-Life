# Prisma Migrations

Migrations are generated from `../schema.prisma`. They are intentionally **not**
committed in this foundation snapshot because they must be created against a live
PostgreSQL instance.

## Create the initial migration (dev)

```bash
# with a running Postgres (see infra/docker-compose.yml)
cd backend
npx prisma migrate dev --name init
```

This writes `migrations/<timestamp>_init/migration.sql` and applies it. Commit
the generated folder so it deploys deterministically.

## Apply migrations (staging / production)

```bash
npx prisma migrate deploy
```

Run as the `migrate-job` Kubernetes Job (see `infra/k8s/base/migrate-job.yaml`)
during each release, before the new API pods roll out. Follow the
**expand → migrate → contract** pattern for zero-downtime schema changes
(documented in `docs/DEPLOYMENT.md`).
