#!/bin/bash

# setup-overcommit.sh
# Configures vm.overcommit_memory=1 for Valkey (v5y) to prevent memory allocation warnings.
# Usage:
#   Interactive: ./setup-overcommit.sh
#   Non-interactive (for pipelines): ./setup-overcommit.sh --non-interactive

# Constants
SYSCTL_CONF="/etc/sysctl.conf"
SYSCTL_KEY="vm.overcommit_memory"
SYSCTL_VALUE="1"
SYSCTL_D_DIR="/etc/sysctl.d"
SYSCTL_D_FILE="$SYSCTL_D_DIR/99-v5y-overcommit.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if sudo is available
check_sudo() {
    echo "[DEBUG] Checking sudo availability"
    if ! command -v sudo >/dev/null 2>&1; then
        echo -e "${RED}Error: sudo is required but not installed.${NC}"
        exit 1
    fi
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}Warning: sudo requires a password. You may be prompted for it.${NC}"
    fi
}

# Check current vm.overcommit_memory setting
check_current_setting() {
    echo "[DEBUG] Checking current $SYSCTL_KEY setting"
    local current=$(sysctl -n "$SYSCTL_KEY" 2>/dev/null || echo "unknown")
    echo -e "Current $SYSCTL_KEY: $current"
    if [ "$current" = "$SYSCTL_VALUE" ]; then
        return 0
    else
        return 1
    fi
}

# Apply temporary change
apply_temporary() {
    echo "[DEBUG] Applying temporary change"
    echo -e "Applying temporary change: $SYSCTL_KEY=$SYSCTL_VALUE"
    if sudo sysctl "$SYSCTL_KEY=$SYSCTL_VALUE" >/dev/null; then
        echo -e "${GREEN}Temporary change applied successfully.${NC}"
        return 0
    else
        echo -e "${RED}Error: Failed to apply temporary change.${NC}"
        return 1
    fi
}

# Apply persistent change
apply_persistent() {
    echo "[DEBUG] Applying persistent change"
    echo -e "Applying persistent change to $SYSCTL_D_FILE"
    # Create sysctl.d directory if it doesn't exist
    if [ ! -d "$SYSCTL_D_DIR" ]; then
        sudo mkdir -p "$SYSCTL_D_DIR" || {
            echo -e "${RED}Error: Failed to create $SYSCTL_D_DIR.${NC}"
            return 1
        }
    fi
    # Write to sysctl.d file
    echo "$SYSCTL_KEY=$SYSCTL_VALUE" | sudo tee "$SYSCTL_D_FILE" >/dev/null || {
        echo -e "${RED}Error: Failed to write to $SYSCTL_D_FILE.${NC}"
        return 1
    }
    # Apply the change
    if sudo sysctl -p "$SYSCTL_D_FILE" >/dev/null; then
        echo -e "${GREEN}Persistent change applied successfully.${NC}"
        return 0
    else
        echo -e "${RED}Error: Failed to apply persistent change.${NC}"
        return 1
    fi
}

# Interactive mode
interactive_mode() {
    echo "[DEBUG] Entering interactive mode"
    check_sudo
    check_current_setting
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$SYSCTL_KEY is already set to $SYSCTL_VALUE. No changes needed.${NC}"
        exit 0
    fi

    # Check if running in a terminal
    if [ ! -t 0 ]; then
        echo -e "${RED}Error: Interactive mode requires a terminal. Use --non-interactive for pipelines.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Valkey requires $SYSCTL_KEY=$SYSCTL_VALUE to prevent memory allocation issues.${NC}"
    echo "See https://github.com/jemalloc/jemalloc/issues/1328 for details."
    echo "Choose an option:"
    echo "1) Apply temporary change (until reboot)"
    echo "2) Apply persistent change (survives reboots)"
    echo "3) Exit without changes"
    read -p "Enter option (1-3): " choice

    echo "[DEBUG] User selected option: $choice"
    case "$choice" in
        1)
            apply_temporary && check_current_setting
            ;;
        2)
            apply_persistent && check_current_setting
            ;;
        3)
            echo "No changes made."
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
    echo "[DEBUG] Entering non-interactive mode"
    check_sudo
    check_current_setting
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$SYSCTL_KEY is already set to $SYSCTL_VALUE. No changes needed.${NC}"
        exit 0
    fi
    apply_persistent && check_current_setting
}

# Main logic
echo "[DEBUG] Starting script"
if [ "$1" = "--non-interactive" ]; then
    non_interactive_mode
else
    interactive_mode
fi