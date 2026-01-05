#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
DIM='\033[2m'
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
        sudo killall openvpn 2>/dev/null
        sleep 1
        echo -e "${GREEN}[disconnected]${NC} vpn stopped"
    else
        echo -e "${DIM}[info]${NC} vpn not running"
    fi
else
    if openvpn3 sessions-list 2>/dev/null | grep -q "Path:"; then
        openvpn3 session-manage --disconnect --config "$(openvpn3 sessions-list 2>/dev/null | grep "Config name:" | head -1 | awk '{print $NF}')" 2>/dev/null
        echo -e "${GREEN}[disconnected]${NC} vpn session closed"
    else
        echo -e "${DIM}[info]${NC} no active vpn session"
    fi
fi
echo ""
