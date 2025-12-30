#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/vpn-connect.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${BOLD}openvpn-yubikey${NC}"
echo -e "${DIM}--------------------------------${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}[error]${NC} config not found: $CONFIG_FILE"
    echo -e "${DIM}        copy vpn-connect.conf.example to vpn-connect.conf${NC}"
    exit 1
fi

source "$CONFIG_FILE"

if [ -z "$CONFIG" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$TOTP_ACCOUNT" ]; then
    echo -e "${RED}[error]${NC} missing required config values"
    exit 1
fi

echo -e "${CYAN}[1/3]${NC} fetching totp from yubikey..."
TOTP=$(ykman oath accounts code "$TOTP_ACCOUNT" 2>/dev/null | awk '{print $NF}')

if [ -z "$TOTP" ]; then
    echo -e "${RED}[error]${NC} failed to get totp - is yubikey connected?"
    exit 1
fi

echo -e "${CYAN}[2/3]${NC} got totp: ${BOLD}$TOTP${NC}"
echo -e "${CYAN}[3/3]${NC} connecting to vpn..."

nohup sudo "${SCRIPT_DIR}/vpn-expect.exp" "$CONFIG" "$USERNAME" "$PASSWORD" "$TOTP" > /tmp/openvpn.log 2>&1 &

sleep 8

echo ""
if pgrep -x openvpn > /dev/null; then
    echo -e "${GREEN}[connected]${NC} vpn running in background"
    echo -e "${DIM}            run 'vpn-disconnect' to disconnect${NC}"
else
    echo -e "${RED}[failed]${NC} check /tmp/openvpn.log for details"
fi
echo ""
