#!/bin/bash

# cache/start.sh
# Interactively starts the ollama deployment, handling Tailscale auth key creation and GPU detection.
# Usage:
#   Interactive: ./cache/start.sh
#   Non-interactive: ./cache/start.sh --non-interactive [--profile loc-cpu|loc-gpu|cpu-tail|gpu-tail|--profile=loc-cpu|loc-gpu|cpu-tail|gpu-tail]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
TSAUTHKEY_PATH="${TSAUTHKEY_PATH:-~/.secrets/ollama-tsauthkey.key}"
DEFAULT_PROFILE="loc-cpu"

# Detect GPU and VRAM
detect_gpu() {
    echo "[DEBUG] Checking for GPU"
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "${YELLOW}No NVIDIA GPU detected. Defaulting to CPU profiles.${NC}"
        echo "cpu"
        return
    fi
    local vram_mib=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [ -z "$vram_mib" ]; then
        echo -e "${YELLOW}No NVIDIA GPU detected. Defaulting to CPU profiles.${NC}"
        echo "cpu"
        return
    fi
    local vram_gb=$((vram_mib / 1024))
    echo -e "${GREEN}NVIDIA GPU detected with ${vram_gb} GB VRAM.${NC}"
    echo "gpu"
}

# Check for required commands
check_requirements() {
    echo "[DEBUG] Checking requirements"
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}Error: docker is required but not installed.${NC}"
        exit 1
    fi
    if ! docker compose version >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker Compose plugin is required but not installed.${NC}"
        exit 1
    fi
}

# Check and create Tailscale auth key
check_tsauthkey() {
    echo "[DEBUG] Checking Tailscale auth key at $TSAUTHKEY_PATH"
    if [ -f "$TSAUTHKEY_PATH" ]; then
        echo -e "${GREEN}Tailscale auth key found at $TSAUTHKEY_PATH.${NC}"
        return 0
    fi
    echo -e "${YELLOW}No Tailscale auth key found at $TSAUTHKEY_PATH.${NC}"
    if [ ! -t 0 ]; then
        echo -e "${RED}Error: Cannot create auth key in non-interactive mode. Please create $TSAUTHKEY_PATH manually.${NC}"
        exit 1
    fi
    echo "Generate a key at https://login.tailscale.com/admin/authkeys."
    echo -n "Enter Tailscale auth key (input hidden): "
    read -s tsauthkey
    echo
    if [ -z "$tsauthkey" ]; then
        echo -e "${RED}Error: No auth key provided.${NC}"
        exit 1
    fi
    mkdir -p "$(dirname "$TSAUTHKEY_PATH")" || {
        echo -e "${RED}Error: Failed to create directory for $TSAUTHKEY_PATH.${NC}"
        exit 1
    }
    echo "$tsauthkey" > "$TSAUTHKEY_PATH" || {
        echo -e "${RED}Error: Failed to write to $TSAUTHKEY_PATH.${NC}"
        exit 1
    }
    chmod 600 "$TSAUTHKEY_PATH" || {
        echo -e "${RED}Error: Failed to set permissions on $TSAUTHKEY_PATH.${NC}"
        exit 1
    }
    echo -e "${GREEN}Tailscale auth key created at $TSAUTHKEY_PATH.${NC}"
}

# Start Docker Compose services
start_services() {
    local profile="$1"
    echo "[DEBUG] Starting services with profile $profile"
    if ! docker compose -f $(dirname "$0")/docker-compose.yml --profile "$profile" up -d; then
        echo -e "${RED}Error: Failed to start services with profile $profile.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Services started successfully with profile $profile.${NC}"
}

# Interactive mode
interactive_mode() {
    check_requirements
    check_tsauthkey
    local gpu_type=$(detect_gpu)
    echo -e "${YELLOW}Choose a deployment profile:${NC}"
    if [ "$gpu_type" = "cpu" ]; then
        echo "1) Local CPU (access via localhost:${OLLAMA_PORT:-11434})"
        echo "2) Tailscale CPU (access via VPN)"
        echo "3) Exit without starting"
        read -p "Enter option (1-3): " choice
        echo "[DEBUG] User selected option: $choice"
        case "$choice" in
            1)
                start_services "loc-cpu"
                ;;
            2)
                start_services "cpu-tail"
                ;;
            3)
                echo "No services started."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Exiting.${NC}"
                exit 1
                ;;
        esac
    else
        echo "1) Local GPU (access via localhost:${OLLAMA_PORT:-11434})"
        echo "2) Tailscale GPU (access via VPN)"
        echo "3) Local CPU (access via localhost:${OLLAMA_PORT:-11434})"
        echo "4) Tailscale CPU (access via VPN)"
        echo "5) Exit without starting"
        read -p "Enter option (1-5): " choice
        echo "[DEBUG] User selected option: $choice"
        case "$choice" in
            1)
                start_services "loc-gpu"
                ;;
            2)
                start_services "gpu-tail"
                ;;
            3)
                start_services "loc-cpu"
                ;;
            4)
                start_services "cpu-tail"
                ;;
            5)
                echo "No services started."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Exiting.${NC}"
                exit 1
                ;;
        esac
    fi
}

# Non-interactive mode
non_interactive_mode() {
    local profile="$1"
    check_requirements
    check_tsauthkey
    start_services "$profile"
}

# Parse arguments
parse_args() {
    local non_interactive=false
    local profile="$DEFAULT_PROFILE"
    while [ $# -gt 0 ]; do
        case "$1" in
            --non-interactive)
                non_interactive=true
                shift
                ;;
            --profile)
                profile="$2"
                shift 2
                ;;
            --profile=*)
                profile="${1#--profile=}"
                shift
                ;;
            *)
                echo -e "${RED}Error: Unknown argument '$1'.${NC}"
                echo "Usage: $0 [--non-interactive] [--profile loc-cpu|loc-gpu|cpu-tail|gpu-tail|--profile=loc-cpu|loc-gpu|cpu-tail|gpu-tail]"
                exit 1
                ;;
        esac
    done
    if [ "$non_interactive" = true ]; then
        if [ "$profile" != "loc-cpu" ] && [ "$profile" != "loc-gpu" ] && [ "$profile" != "cpu-tail" ] && [ "$profile" != "gpu-tail" ]; then
            echo -e "${RED}Error: Invalid profile '$profile'. Use 'loc-cpu', 'loc-gpu', 'cpu-tail', or 'gpu-tail'.${NC}"
            exit 1
        fi
        if [[ "$profile" == *-gpu ]]; then
            if ! command -v nvidia-smi >/dev/null 2>&1 || ! nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits >/dev/null 2>&1; then
                echo -e "${RED}Error: GPU profile '$profile' selected, but no NVIDIA GPU detected.${NC}"
                exit 1
            fi
        fi
        non_interactive_mode "$profile"
    else
        if [ ! -t 0 ]; then
            echo -e "${RED}Error: Interactive mode requires a terminal.${NC}"
            exit 1
        fi
        interactive_mode
    fi
}

# Main logic
echo "[DEBUG] Starting script"
parse_args "$@"