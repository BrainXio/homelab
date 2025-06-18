# a8n Deployment

Deploys [n8n](https://n8n.io), a workflow automation platform, with Docker Compose, supporting local and Tailscale-based access.

## Naming Convention
- **Numeronym**: Service names use numeronyms, e.g., `a8n` for "n8n" (a + 8 letters + n), similar to `k8s` for Kubernetes. `tail-tun` represents the Tailscale tunnel.
- **Project**: Named `a8n`, ensuring container names like `a8n-loc-n8n-1`.

## Prerequisites
- Docker and Docker Compose
- Tailscale account (for `tail` profile)
- Bash shell

## Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Configure Environment
Copy and edit `.env`:
```bash
cp .env.example .env
```

Set in `.env`:
- `N8N_PORT`: n8n web interface port (default: `5678`)
- `ENV_TYPE`: Environment type (e.g., `-dev`)
- `ENV_SUFFIX`: Instance suffix (e.g., `-0`)
- `TSAUTHKEY_PATH`: Tailscale auth key file path
- `TSAUTHKEY_EXTERNAL`: `true` for external secrets
- n8n settings (e.g., `WEBHOOK_URL`, `N8N_PROTOCOL`)

Example `.env`:
```plaintext
N8N_PORT=5678
ENV_TYPE=-dev
ENV_SUFFIX=-0
TSAUTHKEY_PATH=./tsauthkey.key
TSAUTHKEY_EXTERNAL=false
WEBHOOK_URL=https://a8n-workflow.example.com
N8N_PROTOCOL=https
```

### 3. Generate Tailscale Auth Key
For `tail` profile, generate a key from [Tailscale Admin Console](https://login.tailscale.com/admin/authkeys):
```bash
mkdir -p ~/.secrets
echo "<your-auth-key>" > ~/.secrets/tsauthkey.key
chmod 600 ~/.secrets/tsauthkey.key
```

Or set `TSAUTHKEY_PATH`:
```bash
export TSAUTHKEY_PATH=/path/to/tsauthkey.key
```

### 4. Deploy
Choose a profile:
- **Local**: `docker-compose --profile loc up -d`
- **Tailscale**: `docker-compose --profile tail up -d`

### 5. Verify
Check services:
```bash
docker-compose ps
```

Test n8n web interface:
- Local: `curl http://localhost:5678/healthz`
- Tailscale: `curl http://a8n${ENV_TYPE}${ENV_SUFFIX}:5678/healthz`

## Configuration
- **Profiles**:
  - `loc`: Local n8n instance.
  - `tail`: Tailscale-enabled n8n instance.
- **Services**:
  - `loc-n8n`: Local n8n service.
  - `tail-n8n`: Tailscale-enabled n8n service.
  - `tail-tun`: Tailscale VPN service.
- **Volumes**:
  - `loc_data`: Persists n8n configurations and workflows.
  - `loc_files`: Mounts local files for workflows.
  - `tail_tun_state`: Persists Tailscale state.
- **Networking**:
  - Local: Exposes `N8N_PORT`.
  - Tailscale: Uses `network_mode: service:tail-tun`.

## Troubleshooting
- **Tailscale Issues**: Check logs (`docker-compose logs tail-tun`).
- **Web Interface Errors**: Verify `N8N_PORT` or Tailscale hostname.
- **File Access**: Ensure `./local_files` exists for `loc_files` volume.

## License
The Unlicense