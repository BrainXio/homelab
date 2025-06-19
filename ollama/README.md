# Ollama Deployment

## Overview
This project deploys Ollama (an open-source LLM runtime) using Docker Compose. It supports four modes:
- **Local CPU**: Access Ollama on `localhost:${OLLAMA_PORT}` (default 11434) using CPU.
- **Local GPU**: Access Ollama on `localhost:${OLLAMA_PORT}` using GPU.
- **Tailscale CPU**: Access Ollama securely over a Tailscale VPN using CPU.
- **Tailscale GPU**: Access Ollama securely over a Tailscale VPN using GPU.

## Naming Convention
- **Project Name**: `ollama`, used for container naming (e.g., `ollama_cpu-app_1`).
- **Services**:
  - `cpu-app`: Local Ollama instance using CPU.
  - `gpu-app`: Local Ollama instance using GPU.
  - `cpu-tail`: Tailscale-connected Ollama instance using CPU.
  - `gpu-tail`: Tailscale-connected Ollama instance using GPU.
  - `tail-tun`: Tailscale VPN service.

## Prerequisites
- Docker and Docker Compose installed.
- A Tailscale account for Tailscale modes.
- Bash for setup scripts.
- For GPU profiles (`loc-gpu`, `gpu-tail`), an NVIDIA GPU with `nvidia-smi` installed.
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
   - Follow prompts to create the Tailscale auth key (if missing) and choose a profile (`loc-cpu`, `loc-gpu`, `cpu-tail`, or `gpu-tail`). GPU options are shown only if an NVIDIA GPU is detected.
   - For pipelines or non-interactive environments, specify the profile:
     ```bash
     ./cache/start.sh --non-interactive --profile loc-cpu
     ```
     or
     ```bash
     ./cache/start.sh --non-interactive --profile=loc-cpu
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
     ./cache/stop.sh --non-interactive --profile loc-cpu
     ```
     or
     ```bash
     ./cache/stop.sh --non-interactive --profile=loc-cpu
     ```

4. **Manual configuration (optional)**:
   - **Configure .env**:
     - Copy `.env.example` to `.env`:
       ```bash
       cp .env.example .env
       ```
     - Edit `.env` to set `TSAUTHKEY_PATH`, `ENV_TYPE`, `ENV_SUFFIX`, `OLLAMA_PORT`, and other variables (e.g., `OLLAMA_KEEP_ALIVE`, `LLM_CHAT_MODEL`). See `.env.example` for details.
   - **Generate Tailscale auth key**:
     - Create a key at [Tailscale Admin Console](https://login.tailscale.com/admin/authkeys).
     - Save it to the file specified in `TSAUTHKEY_PATH` (default: `~/.secrets/tsauthkey-tag-llm.key`):
       ```bash
       mkdir -p ~/.secrets
       echo "tskey-xxxx" > ~/.secrets/tsauthkey-tag-llm.key
       chmod 600 ~/.secrets/tsauthkey-tag-llm.key
       ```

5. **Deploy manually (if not using start.sh)**:
   - For local CPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile loc-cpu up -d
     ```
   - For local GPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile loc-gpu up -d
     ```
   - For Tailscale CPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile cpu-tail up -d
     ```
   - For Tailscale GPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile gpu-tail up -d
     ```

6. **Stop manually (if not using stop.sh)**:
   - For local CPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile loc-cpu down
     ```
   - For local GPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile loc-gpu down
     ```
   - For Tailscale CPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile cpu-tail down
     ```
   - For Tailscale GPU:
     ```bash
     docker compose -f cache/docker-compose.yml --profile gpu-tail down
     ```

7. **Verify**:
   - Check running services:
     ```bash
     docker compose -f cache/docker-compose.yml ps
     ```
   - Test Ollama:
     ```bash
     curl http://localhost:${OLLAMA_PORT:-11434}/api/version
     ```
     Expected output: JSON response with Ollama version.
   - For Tailscale modes, use the Tailscale hostname (`${ENV_TYPE}ollama${ENV_SUFFIX}`, e.g., `-devollama-0`) from another Tailscale-connected device.

## Configuration
- **Profiles**:
  - `loc-cpu`: Local access using CPU.
  - `loc-gpu`: Local access using GPU.
  - `cpu-tail`: Tailscale VPN access using CPU.
  - `gpu-tail`: Tailscale VPN access using GPU.
- **Services**:
  - `cpu-app`: Runs Ollama with CPU, port mapping.
  - `gpu-app`: Runs Ollama with GPU, port mapping.
  - `cpu-tail`: Runs Ollama with CPU over Tailscale VPN, depends on `tail-tun`.
  - `gpu-tail`: Runs Ollama with GPU over Tailscale VPN, depends on `tail-tun`.
  - `tail-tun`: Tailscale VPN service.
- **Volumes**:
  - `app_data`: Persists Ollama models (`/root/.ollama`).
  - `tun_state`: Persists Tailscale state (`/var/lib/tailscale`).
- **Networking**:
  - Local: Exposes `${OLLAMA_PORT:-11434}`.
  - Tailscale: Uses `network_mode: service:tail-tun` for VPN connectivity.
- **Secrets**:
  - `tsauthkey`: Tailscale auth key, loaded from `${TSAUTHKEY_PATH}`.

## Troubleshooting
- **Tailscale not connecting**:
  - Check `tail-tun` logs:
    ```bash
    docker logs ollama_tail-tun_1
    ```
  - Verify `tsauthkey` file exists and contains a valid key.
- **Port conflicts**:
  - Ensure `${OLLAMA_PORT}` is not in use or change it in `.env`.
- **Ollama not responding**:
  - Check healthcheck status:
    ```bash
    docker inspect --format '{{.State.Health.Status}}' ollama_cpu-app_1
    ```
- **GPU not detected**:
  - Verify NVIDIA drivers and `nvidia-smi`:
    ```bash
    nvidia-smi
    ```
- **Script failures**:
  - Run with debugging:
    ```bash
    bash -x cache/start.sh
    bash -x cache/stop.sh
    ```

## License
The Unlicense