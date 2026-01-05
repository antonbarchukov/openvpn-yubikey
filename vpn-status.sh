#!/bin/bash

GREEN='\033[0;32m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)  OS_TYPE="linux" ;;
    Darwin*) OS_TYPE="macos" ;;
    *)       OS_TYPE="unknown" ;;
esac

echo ""
if [ "$OS_TYPE" = "macos" ]; then
    if pgrep -x openvpn > /dev/null; then
        echo -e "${GREEN}[connected]${NC} vpn running"
        echo ""
        PID=$(pgrep -x openvpn)
        echo -e "  ${DIM}PID:${NC} $PID"
        CONFIG=$(ps -p $PID -o args= 2>/dev/null | grep -o -- '--config [^ ]*' | awk '{print $2}')
        if [ -n "$CONFIG" ]; then
            echo -e "  ${DIM}Config:${NC} $(basename "$CONFIG")"
        fi
    else
        echo -e "${DIM}[disconnected]${NC} vpn not running"
    fi
else
    if openvpn3 sessions-list 2>/dev/null | grep -q "Path:"; then
        echo -e "${GREEN}[connected]${NC} vpn session active"
        echo ""
        openvpn3 sessions-list 2>/dev/null | grep -E "(Config name:|Device:|Status:)" | sed 's/^/  /'
    else
        echo -e "${DIM}[disconnected]${NC} no active vpn session"
    fi
fi
echo ""
