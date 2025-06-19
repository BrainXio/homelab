#!/bin/bash

# cache/stop.sh
# Interactively stops and removes the cache (Valkey) deployment services.
# Usage:
#   Interactive: ./cache/stop.sh
#   Non-interactive: ./cache/stop.sh --non-interactive [--profile loc|tail|--profile=loc|tail]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
DEFAULT_PROFILE="loc"

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
    echo -e "${YELLOW}Choose a deployment profile to stop:${NC}"
    echo "1) Local (stops local Valkey instance)"
    echo "2) Tailscale (stops Tailscale-connected instance)"
    echo "3) Exit without stopping"
    read -p "Enter option (1-3): " choice
    echo "[DEBUG] User selected option: $choice"
    case "$choice" in
        1)
            stop_services "loc"
            ;;
        2)
            stop_services "tail"
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
                echo "Usage: $0 [--non-interactive] [--profile loc|tail|--profile=loc|tail]"
                exit 1
                ;;
        esac
    done
    if [ "$non_interactive" = true ]; then
        if [ "$profile" != "loc" ] && [ "$profile" != "tail" ]; then
            echo -e "${RED}Error: Invalid profile '$profile'. Use 'loc' or 'tail'.${NC}"
            exit 1
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