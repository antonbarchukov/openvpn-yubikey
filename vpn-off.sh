#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
DIM='\033[2m'
NC='\033[0m'

echo ""
if openvpn3 sessions-list 2>/dev/null | grep -q "Path:"; then
    openvpn3 session-manage --disconnect --config "$(openvpn3 sessions-list 2>/dev/null | grep "Config name:" | head -1 | awk '{print $NF}')" 2>/dev/null
    echo -e "${GREEN}[disconnected]${NC} vpn session closed"
else
    echo -e "${DIM}[info]${NC} no active vpn session"
fi
echo ""
