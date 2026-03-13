# CI/CD Design — Perro Paco

## Overview

- **Build**: Reusable workflow `build-reusable.yml` builds Docker images and pushes to GHCR.
- **Deploy**: Reusable workflow `deploy-reusable.yml` SSHs to the VPS, refreshes `.env` from Doppler, pulls images, and restarts containers.

## Branch mapping

| Branch   | Environment | Project       | Domains                          |
|----------|-------------|---------------|----------------------------------|
| `staging`| dev         | perropaco-dev | api.dev.perropaco.org, app.dev.perropaco.org |
| `main`   | prod        | perropaco-prd | api.perropaco.org, app.perropaco.org       |

## Image tagging

- `staging` → `staging-{run}-{sha}`
- `main` → `release-{run}-{sha}`
- Other branches → `snapshot-{branch}-{run}-{sha}`

## Doppler

Use a single Doppler project (e.g. `perropaco`) with configs `dev` and `prd`. Each config holds all secrets for that environment:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `CLERK_JWKS_URL`, `JWT_AUDIENCE`, `JWT_ISSUER`, `CLERK_SECRET_KEY`
- `FCM_SERVICE_ACCOUNT_PATH`, `FCM_PROJECT_ID` (optional)
- `LOG_LEVEL`

Create service tokens for `dev` and `prd` and store as `DOPPLER_TOKEN` in GitHub repo secrets for `perro-paco-api` and `perro-paco-admin-app`.

## GitHub secrets (per app repo)

- `INFRA_TOKEN` — PAT with read access to `AlejandroMarques/perro-paco-infra`
- `DEPLOY_HOST` — Hetzner server IP
- `DEPLOY_USER` — `deploy`
- `DEPLOY_SSH_KEY` — Private key from `keys/deploy_perropaco`
- `DOPPLER_TOKEN` — Doppler service token for the target env (dev or prd)
- `GHCR_TOKEN` — Optional; PAT with `read:packages` for VPS image pulls
