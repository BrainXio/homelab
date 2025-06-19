# Cache Deployment

## Overview
This project deploys Valkey (a Redis-compatible in-memory data store) using Docker Compose. It supports two modes:
- **Local**: Access Valkey on `localhost:${VALKEY_PORT}` (default 6379).
- **Tailscale**: Access Valkey securely over a Tailscale VPN.

## Naming Convention
- **Project Name**: `cache`, used for container naming (e.g., `cache_app_1`).
- **Services**:
  - `app`: Local Valkey instance.
  - `tail`: Tailscale-connected Valkey instance.
  - `tun`: Tailscale VPN service.

## Prerequisites
- Docker and Docker Compose installed.
- A Tailscale account for Tailscale mode.
- Bash for setup scripts.
- Ensure `cache/setup-overcommit.sh` exists alongside `cache/start.sh` and `cache/stop.sh`.

## Setup
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Start the deployment**:
   - Run the start script (located in the `cache` directory) to configure memory overcommit, set up the Tailscale auth key, and deploy services:
     ```bash
     chmod +x cache/start.sh
     ./cache/start.sh
     ```
   - Follow prompts to configure `vm.overcommit_memory=1`, create the Tailscale auth key (if missing), and choose a profile (`loc` or `tail`).
   - For pipelines or non-interactive environments, specify the profile:
     ```bash
     ./cache/start.sh --non-interactive --profile loc
     ```
     or
     ```bash
     ./cache/start.sh --non-interactive --profile=loc
     ```

3. **Stop the deployment**:
   - Run the stop script (located in the `cache` directory) to stop and remove services:
     ```bash
     chmod +x cache/stop.sh
     ./cache/stop.sh
     ```
   - Follow prompts to choose a profile (`loc` or `tail`) to stop.
   - For pipelines or non-interactive environments, specify the profile:
     ```bash
     ./cache/stop.sh --non-interactive --profile loc
     ```
     or
     ```bash
     ./cache/stop.sh --non-interactive --profile=loc
     ```

4. **Manual configuration (optional)**:
   - **Configure .env**:
     - Copy `.env.example` to `.env`:
       ```bash
       cp .env.example .env
       ```
     - Edit `.env` to set `TSAUTHKEY_PATH`, `ENV_TYPE`, `ENV_SUFFIX`, and `VALKEY_PORT` as needed.
     - Optionally, configure Valkey-specific variables (e.g., `VALKEY_PASSWORD`, `VALKEY_MAXMEMORY`, `VALKEY_REPLICATION_MODE`) for authentication, memory limits, or replication. See `.env.example` for details.
   - **Generate Tailscale auth key**:
     - Create a key at [Tailscale Admin Console](https://login.tailscale.com/admin/authkeys).
     - Save it to the file specified in `TSAUTHKEY_PATH` (default: `./tsauthkey.key`):
       ```bash
       echo "tskey-xxxx" > tsauthkey.key
       chmod 600 tsauthkey.key
       ```
   - **Configure memory overcommit**:
     - Run the overcommit script manually (located in the `cache` directory):
       ```bash
       chmod +x cache/setup-overcommit.sh
       ./cache/setup-overcommit.sh
       ```
     - For pipelines, use:
       ```bash
       ./cache/setup-overcommit.sh --non-interactive
       ```

5. **Deploy manually (if not using start.sh)**:
   - For local access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile loc up -d
     ```
   - For Tailscale access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile tail up -d
     ```

6. **Stop manually (if not using stop.sh)**:
   - For local access:
     ```bash
     docker compose -f cache/docker-compose.yml --profile loc down
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
   - For local mode, test Valkey:
     ```bash
     valkey-cli -p ${VALKEY_PORT:-6379} ping
     ```
     Expected output: `PONG`
   - For Tailscale mode, use the Tailscale hostname (`${ENV_TYPE}cache${ENV_SUFFIX}`, e.g., `-devcache-0`) from another Tailscale-connected device.

## Configuration
- **Profiles**:
  - `loc`: Local access via exposed port.
  - `tail`: Tailscale VPN access.
- **Services**:
  - `app`: Runs Valkey with port mapping.
  - `tail`: Runs Valkey over Tailscale VPN, depends on `tun`.
  - `tun`: Tailscale VPN service.
- **Volumes**:
  - `tun_state`: Persists Tailscale state.
- **Networking**:
  - Local: Exposes `${VALKEY_PORT:-6379}`.
  - Tailscale: Uses `network_mode: service:tun` for VPN connectivity.
- **Secrets**:
  - `tsauthkey`: Tailscale auth key, loaded from `${TSAUTHKEY_PATH}`.

## Troubleshooting
- **Tailscale not connecting**:
  - Check `tun` logs:
    ```bash
    docker logs cache_tun_1
    ```
  - Verify `tsauthkey` file exists and contains a valid key.
- **Port conflicts**:
  - Ensure `${VALKEY_PORT}` is not in use or change it in `.env`.
- **Valkey not responding**:
  - Check healthcheck status:
    ```bash
    docker inspect --format '{{.State.Health.Status}}' cache_app_1
    ```
- **Memory overcommit warning**:
  - Ensure `vm.overcommit_memory=1` is set using `cache/start.sh` or `cache/setup-overcommit.sh`.
  - Verify with:
    ```bash
    sysctl vm.overcommit_memory
    ```
- **Script failures**:
  - If `start.sh` or `stop.sh` fails, run with debugging:
    ```bash
    bash -x cache/start.sh
    bash -x cache/stop.sh
    ```

## License
The Unlicense