#!/bin/bash

GREEN='\033[0;32m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
if openvpn3 sessions-list 2>/dev/null | grep -q "Path:"; then
    echo -e "${GREEN}[connected]${NC} vpn session active"
    echo ""
    openvpn3 sessions-list 2>/dev/null | grep -E "(Config name:|Device:|Status:)" | sed 's/^/  /'
else
    echo -e "${DIM}[disconnected]${NC} no active vpn session"
fi
echo ""
