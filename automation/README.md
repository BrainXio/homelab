# Automation Deployment

## Overview
This project deploys n8n (a workflow automation platform) using Docker Compose. It supports two modes:
- **Local**: Access n8n on `localhost:${N8N_PORT}` (default 5678).
- **Tailscale**: Access n8n securely over a Tailscale VPN.

## Naming Convention
- **Project Name**: `automation`, used for container naming (e.g., `automation_app_1`).
- **Services**:
  - `app`: Local n8n instance.
  - `tail`: Tailscale-connected n8n instance.
  - `tun`: Tailscale VPN service.

## Prerequisites
- Docker and Docker Compose installed.
- A Tailscale account for Tailscale mode.
- Bash for setup scripts.
- Ensure `cache/start.sh` and `cache/stop.sh` are in the `cache` directory.

## Setup
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Start the deployment**:
   - Run the start script (located in the `cache` directory) to set up the Tailscale auth key and deploy services:
     ```bash
     chmod +x cache/start.sh
     ./cache/start.sh
     ```
   - Follow prompts to create the Tailscale auth key (if missing) and choose a profile (`local` or `tail`).
   - For pipelines or non-interactive environments, specify the profile:
     ```bash
     ./cache/start.sh --non-interactive --profile local
     ```
     or
     ```bash
     ./cache/start.sh --non-interactive --profile=local
     ```

3. **Stop the deployment**:
   - Run the stop script (located in the `cache` directory) to stop and remove services:
     ```bash
     chmod +x cache/stop.sh
     ./cache/stop.sh
     ```
   - Follow prompts to choose a profile to stop.
   - For pipelines or non-interactive environments, specify the profile:
     ```bash
     ./cache/stop.sh --non-interactive --profile local
     ```
     or
     ```bash
     ./cache/stop.sh --non-interactive --profile=local
     ```

4. **Manual configuration (optional)**:
   - **Configure .env**:
     - Copy `.env.example` to `.env`:
       ```bash
       cp .env.example .env
       ```
     - Edit `.env` to set `TSAUTHKEY_PATH`, `ENV_TYPE`, `ENV_SUFFIX`, `N8N_PORT`, and other variables (e.g., `N8N_HOST`, `N8N_AUTH_JWT_SECRET`). See `.env.example` for details.
   - **Generate Tailscale auth key**:
     - Create a key at [Tailscale Admin Console](https://login.tailscale.com/admin/authkeys).
     - Save it to the file specified in `TSAUTHKEY_PATH` (default: `./tsauthkey.key`):
       ```bash
       echo "tskey-xxxx" > tsauthkey.key
       chmod 600 tsauthkey.key
       ```

5. **Deploy manually (if not using start.sh)**:
   - For local access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile local up -d
     ```
   - For Tailscale access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile tail up -d
     ```

6. **Stop manually (if not using stop.sh)**:
   - For local access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile local down
     ```
   - For Tailscale access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile tail down
     ```

7. **Verify**:
   - Check running services:
     ```bash
     docker compose -f cache/docker-compose.yml ps
     ```
   - Test n8n:
     ```bash
     curl http://localhost:${N8N_PORT:-5678}/healthz
     ```
     Expected output: `{"status":"ok"}`
   - For Tailscale mode, use the Tailscale hostname (`${ENV_TYPE}automation${ENV_SUFFIX}`, e.g., `-devautomation-0`) from another Tailscale-connected device.

## Configuration
- **Profiles**:
  - `local`: Local access via exposed port.
  - `tail`: Tailscale VPN access.
- **Services**:
  - `app`: Runs n8n with port mapping.
  - `tail`: Runs n8n over Tailscale VPN, depends on `tun`.
  - `tun`: Tailscale VPN service.
- **Volumes**:
  - `app_data`: Persists n8n configuration (`/home/node/.n8n`).
  - `app_files`: Mounts local files (`/files`).
  - `tun_state`: Persists Tailscale state (`/var/lib/tailscale`).
- **Networking**:
  - Local: Exposes `${N8N_PORT:-5678}`.
  - Tailscale: Uses `network_mode: service:tun` for VPN connectivity.
- **Secrets**:
  - `tsauthkey`: Tailscale auth key, loaded from `${TSAUTHKEY_PATH}`.

## Troubleshooting
- **Tailscale not connecting**:
  - Check `tun` logs:
    ```bash
    docker logs automation_tun_1
    ```
  - Verify `tsauthkey` file exists and contains a valid key.
- **Port conflicts**:
  - Ensure `${N8N_PORT}` is not in use or change it in `.env`.
- **n8n not responding**:
  - Check healthcheck status:
    ```bash
    docker inspect --format '{{.State.Health.Status}}' automation_app_1
    ```
- **Script failures**:
  - Run with debugging:
    ```bash
    bash -x cache/start.sh
    bash -x cache/stop.sh
    ```

## License
The Unlicense