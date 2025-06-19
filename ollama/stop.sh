#!/bin/bash

# cache/stop.sh
# Interactively stops and removes the ollama deployment services.
# Usage:
#   Interactive: ./cache/stop.sh
#   Non-interactive: ./cache/stop.sh --non-interactive [--profile loc-cpu|loc-gpu|cpu-tail|gpu-tail|--profile=loc-cpu|loc-gpu|cpu-tail|gpu-tail]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PROFILE="loc-cpu"

# Detect GPU
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

# Stop and remove Docker Compose services
stop_services() {
    local profile="$1"
    echo "[DEBUG] Stopping services with profile $profile"
    if ! docker compose -f $(dirname "$0")/docker-compose.yml --profile "$profile" down; then
        echo -e "${RED}Error: Failed to stop services with profile $profile.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Services stopped and removed successfully for profile $profile.${NC}"
}

# Interactive mode
interactive_mode() {
    check_requirements
    local gpu_type=$(detect_gpu)
    echo -e "${YELLOW}Choose a deployment profile to stop:${NC}"
    if [ "$gpu_type" = "cpu" ]; then
        echo "1) Local CPU (stops local Valkey instance)"
        echo "2) Tailscale CPU (stops Tailscale-connected instance)"
        echo "3) Exit without stopping"
        read -p "Enter option (1-3): " choice
        echo "[DEBUG] User selected option: $choice"
        case "$choice" in
            1)
                stop_services "loc-cpu"
                ;;
            2)
                stop_services "cpu-tail"
                ;;
            3)
                echo "No services stopped."
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option. Exiting.${NC}"
                exit 1
                ;;
        esac
    else
        echo "1) Local GPU (stops local GPU instance)"
        echo "2) Tailscale GPU (stops Tailscale-connected GPU instance)"
        echo "3) Local CPU (stops local CPU instance)"
        echo "4) Tailscale CPU (stops Tailscale-connected CPU instance)"
        echo "5) Exit without stopping"
        read -p "Enter option (1-5): " choice
        echo "[DEBUG] User selected option: $choice"
        case "$choice" in
            1)
                stop_services "loc-gpu"
                ;;
            2)
                stop_services "gpu-tail"
                ;;
            3)
                stop_services "loc-cpu"
                ;;
            4)
                stop_services "cpu-tail"
                ;;
            5)
                echo "No services stopped."
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
    stop_services "$profile"
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