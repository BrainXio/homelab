# o4a Deployment

Deploys [Ollama](https://ollama.ai) with Docker Compose, supporting local and Tailscale-based access, with CPU (`runc`) or GPU (NVIDIA) configurations.

## Naming Convention
- **Numeronym**: Service names use numeronyms, e.g., `o4a` for "Ollama" (`o` + 4 letters + `a`), like `k8s` for Kubernetes. `tail-tun` represents the Tailscale tunnel.
- **Project**: Named `o4a`, ensuring container names like `o4a_dev-loc-cpu_1`.

## Prerequisites
- Docker and Docker Compose
- NVIDIA Container Toolkit (for GPU profiles)
- Tailscale account (for `tail-cpu` or `tail-gpu`)
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
- `OLLAMA_PORT`: Ollama API port (default: `11434`)
- `ENV_TYPE`: Environment type (e.g., `-dev`)
- `ENV_SUFFIX`: Instance suffix (e.g., `-0`)
- `TSAUTHKEY_PATH`: Tailscale auth key file path
- `TSAUTHKEY_EXTERNAL`: `true` for external secrets
- Ollama settings (e.g., `OLLAMA_NUM_CTX`)

Example `.env`:
```plaintext
OLLAMA_PORT=11434
ENV_TYPE=-dev
ENV_SUFFIX=-0
TSAUTHKEY_PATH=./tsauthkey.key
TSAUTHKEY_EXTERNAL=false
OLLAMA_NUM_CTX=8192
```

### 3. Generate Tailscale Auth Key
For `tail-cpu` or `tail-gpu`, generate a key from [Tailscale Admin Console](https://login.tailscale.com/admin/authkeys):
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
- **Local CPU**: `docker-compose --profile loc-cpu up -d`
- **Local GPU**: `docker-compose --profile loc-gpu up -d`
- **Tailscale CPU**: `docker-compose --profile tail-cpu up -d`
- **Tailscale GPU**: `docker-compose --profile tail-gpu up -d`

### 5. Verify
Check services:
```bash
docker-compose ps
```

Test Ollama API:
- Local: `curl http://localhost:11434`
- Tailscale: `curl http://o4a${ENV_TYPE}${ENV_SUFFIX}:11434`

## Configuration
- **Profiles**: `loc-cpu`, `loc-gpu`, `tail-cpu`, `tail-gpu` for specific deployments.
- **Services**:
  - `dev-loc-cpu`, `dev-loc-gpu`: Local Ollama instances.
  - `tail-cpu`, `tail-gpu`: Tailscale-enabled Ollama instances.
  - `tail-tun`: Tailscale VPN service.
- **Volumes**:
  - `model_data`: Persists Ollama models.
  - `tail_tun_state`: Persists Tailscale state.
- **Networking**:
  - Local: Exposes `OLLAMA_PORT`.
  - Tailscale: Uses `network_mode: service:tail-tun`.

## Troubleshooting
- **GPU Issues**: Verify NVIDIA toolkit (`nvidia-smi`).
- **Tailscale**: Check logs (`docker-compose logs tail-tun`).
- **API Errors**: Ensure correct port/hostname.

## License
The Unlicense