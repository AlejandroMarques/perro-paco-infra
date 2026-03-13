# VPS Setup Guide — Perro Paco Infrastructure

Step-by-step record for provisioning and configuring the Hetzner CCX13 production server.

## Prerequisites

- **hcloud CLI** (`npm i -g hcloud-cli` or [binary](https://github.com/hetznercloud/cli/releases))
- **SSH key pair** for personal access (`~/.ssh/perropaco` / `~/.ssh/perropaco.pub`)
- **Deploy key pair** for GitHub Actions (`keys/deploy_perropaco` / `keys/deploy_perropaco.pub`)
- **Hetzner Cloud API token** (Hetzner Cloud Console → Security → API Tokens)
- **cloud-init** at `cloud-init/hetzner-init.yml` with both SSH public keys

### SSH keys in cloud-init

Edit `cloud-init/hetzner-init.yml` and replace the placeholder with your personal public key:

```yaml
ssh_authorized_keys:
  - ssh-ed25519 AAAAC3NzaC1l... your-actual-key perropaco-admin
  - ssh-ed25519 AAAAC3NzaC1l... perropaco-deploy # from keys/deploy_perropaco.pub
```

---

## 1. Hetzner CLI setup

```bash
hcloud context create perropaco
# Paste API token when prompted
```

---

## 2. Upload SSH key to Hetzner

```bash
hcloud ssh-key create --name perropaco --public-key-from-file ~/.ssh/perropaco.pub
```

---

## 3. Create the VPS

```bash
hcloud server create \
  --name perropaco-prod \
  --type ccx13 \
  --image ubuntu-24.04 \
  --location nbg1 \
  --ssh-key perropaco \
  --user-data-from-file cloud-init/hetzner-init.yml
```

Note the IPv4 address from the output. Cloud-init takes 1–3 minutes to complete.

---

## 4. Verify cloud-init

Wait ~90 seconds, then:

```bash
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "cloud-init status"
# Expected: status: done

ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "docker --version && docker compose version"
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "ls -la /opt/traefik /opt/perropaco-dev /opt/perropaco-prd && docker network ls | grep traefik"
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "sudo ufw status"
```

---

## 5. DNS (Dinahosting)

In Dinahosting control panel for `perropaco.org`, create A records pointing to `<SERVER_IP>`:

- `api.perropaco.org`
- `admin.perropaco.org`
- `api.dev.perropaco.org`
- `admin.dev.perropaco.org`
- Optional: `traefik.perropaco.org`, `portainer.perropaco.org`

---

## 6. Configure Traefik

From infra repo root:

```bash
scp -i ~/.ssh/perropaco -r traefik/* deploy@<SERVER_IP>:/opt/traefik/
```

Create `/opt/traefik/.env` (optional, for dashboard basic auth):

```bash
# Generate basicauth hash:
# echo -n 'admin:yourpassword' | openssl dgst -apr1 -binary | openssl base64 -A

ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "cat > /opt/traefik/.env << 'EOF'
TRAEFIK_DASHBOARD_AUTH=admin:\$apr1\$...
EOF"
```

Or leave `.env` empty; Traefik will still run (HTTP-01 needs no token).

Start Traefik:

```bash
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "cd /opt/traefik && docker compose up -d"
```

---

## 7. Doppler CLI on VPS

Install Doppler for deploy-time secret injection:

```bash
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP>
curl -sLf --retry 3 --retry-connrefused 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo gpg --dearmor -o /usr/share/keyrings/doppler-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/doppler-archive-keyring.gpg] https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install -y doppler
```

Configure Doppler per project (run in `/opt/perropaco-dev` and `/opt/perropaco-prd`):

```bash
cd /opt/perropaco-dev
doppler setup  # select project + config (e.g. perropaco / dev)
```

---

## 8. GHCR login on VPS

For pulling private images:

```bash
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP>
echo "<GHCR_PAT>" | docker login ghcr.io -u AlejandroMarques --password-stdin
```

Or use `GHCR_TOKEN` secret in the deploy workflow.

---

## 9. First deployment

After CI/CD is configured, push to `staging` or `main` to trigger builds and deploys. Or deploy manually:

```bash
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP>
cd /opt/perropaco-dev
# Ensure .env exists (from Doppler or manual)
docker compose -f docker-compose.prod.yml pull
docker compose -f docker-compose.prod.yml up -d
```

---

## Backup / Restore

```bash
# Backup
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> '/opt/scripts/backup-postgres.sh perropaco-dev'

# Restore
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> '/opt/scripts/restore-postgres.sh perropaco-dev /opt/backups/perropaco-dev/perropaco-dev_20260101_030000.sql.gz'
```

Copy scripts to VPS first:

```bash
scp -i ~/.ssh/perropaco scripts/*.sh deploy@<SERVER_IP>:/opt/scripts/
ssh -i ~/.ssh/perropaco deploy@<SERVER_IP> "chmod +x /opt/scripts/*.sh"
```
