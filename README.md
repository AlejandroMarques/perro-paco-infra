# Perro Paco Infrastructure

Shared infrastructure and CI/CD for Perro Paco (API + Admin app) on a single Hetzner CCX13 VPS.

## Structure

```
perro-paco-infra/
├── cloud-init/          VPS bootstrap (Hetzner)
├── traefik/             Reverse proxy + Let's Encrypt (HTTP-01)
├── portainer/           Optional container management UI
├── scripts/             Backup, restore, setup helpers
├── projects/
│   ├── perropaco-dev/   Dev environment (staging branch)
│   │   ├── api/         Dockerfile + entrypoint
│   │   ├── admin/       Dockerfile + nginx
│   │   └── docker-compose.prod.yml
│   └── perropaco-prd/   Prod environment (main branch)
│       └── ...
├── .github/workflows/
│   ├── build-reusable.yml
│   └── deploy-reusable.yml
└── docs/
    ├── SETUP_HETZNER.md
    └── CICD_PERROPACO.md
```

## Quick start

1. Create Hetzner CCX13 with `cloud-init/hetzner-init.yml` (see [SETUP_HETZNER.md](docs/SETUP_HETZNER.md)).
2. Add DNS A records in Dinahosting for `api.perropaco.org`, `app.perropaco.org`, `api.dev.perropaco.org`, `app.dev.perropaco.org`.
3. Bootstrap Traefik, Doppler, and GHCR on the VPS.
4. Configure GitHub Actions in `perro-paco-api` and `perro-paco-admin-app` to call the reusable workflows.

## Pipeline flow

```
Push to staging → build-reusable (API + Admin) → deploy-reusable → /opt/perropaco-dev
Push to main   → build-reusable (API + Admin) → deploy-reusable → /opt/perropaco-prd
```

## Domains

| Env | API | Admin |
|-----|-----|-------|
| Dev | api.dev.perropaco.org | app.dev.perropaco.org |
| Prod | api.perropaco.org | app.perropaco.org |
