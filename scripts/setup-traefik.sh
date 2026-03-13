#!/bin/bash
set -euo pipefail

# Run once after cloud-init to start Traefik on the VPS
# Usage: ssh -i ~/.ssh/perropaco deploy@<vps-ip> 'bash -s' < scripts/setup-traefik.sh
#
# Prerequisites (run from infra repo root):
#   scp -i ~/.ssh/perropaco -r traefik/* deploy@<vps-ip>:/opt/traefik/
#   Create /opt/traefik/.env with TRAEFIK_DASHBOARD_AUTH (optional, for dashboard basic auth)

echo "[$(date)] Setting up Traefik..."

docker network create traefik-public 2>/dev/null || true

cd /opt/traefik

if [ ! -f docker-compose.yml ]; then
  echo "Error: /opt/traefik/docker-compose.yml not found"
  echo "SCP the traefik/ directory contents to /opt/traefik/ first"
  exit 1
fi

# .env is optional for HTTP-01 (no CF token); TRAEFIK_DASHBOARD_AUTH for dashboard auth
touch .env 2>/dev/null || true

docker compose up -d

echo "[$(date)] Traefik is running"
docker compose ps
