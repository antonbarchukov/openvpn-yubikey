#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
DIM='\033[2m'
NC='\033[0m'

echo ""
if pgrep -x openvpn > /dev/null; then
    sudo killall openvpn 2>/dev/null
    sleep 1
    echo -e "${GREEN}[disconnected]${NC} vpn stopped"
else
    echo -e "${DIM}[info]${NC} vpn not running"
fi
echo ""
