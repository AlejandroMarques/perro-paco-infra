#!/bin/bash
set -euo pipefail

# Run once to start Portainer on the VPS
# Usage: ssh -i ~/.ssh/perropaco deploy@<vps-ip> 'bash -s' < scripts/setup-portainer.sh
#
# Prerequisites (run locally first):
#   scp -i ~/.ssh/perropaco portainer/docker-compose.yml deploy@<vps-ip>:/opt/portainer/
#   echo "PORTAINER_DASHBOARD_AUTH=$(doppler secrets get PORTAINER_DASHBOARD_AUTH --project perropaco-infra --config main --plain)" | ssh -i ~/.ssh/perropaco deploy@<vps-ip> "cat > /opt/portainer/.env"

echo "[$(date)] Setting up Portainer..."

sudo mkdir -p /opt/portainer
sudo chown deploy:deploy /opt/portainer

cd /opt/portainer

if [ ! -f docker-compose.yml ]; then
  echo "Error: /opt/portainer/docker-compose.yml not found"
  echo "SCP the portainer/docker-compose.yml to /opt/portainer/ first"
  exit 1
fi

if [ ! -f .env ]; then
  echo "Error: /opt/portainer/.env not found"
  echo "Create .env with PORTAINER_DASHBOARD_AUTH (from Doppler perropaco-infra/main)"
  exit 1
fi

docker compose up -d

echo "[$(date)] Portainer is running at https://portainer.perropaco.org"
echo "First visit: create admin user in Portainer UI (after Traefik basic auth)"
docker compose ps
