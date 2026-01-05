#!/bin/bash

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/vpn.conf"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
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
echo -e "${BOLD}openvpn-yubikey${NC}"
echo -e "${DIM}--------------------------------${NC}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}[error]${NC} config not found: $CONFIG_FILE"
    echo -e "${DIM}        copy vpn.conf.example to vpn.conf${NC}"
    exit 1
fi

source "$CONFIG_FILE"

if [ -z "$CONFIG" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$TOTP_ACCOUNT" ]; then
    echo -e "${RED}[error]${NC} missing required config values"
    exit 1
fi

# Check if already connected
if [ "$OS_TYPE" = "macos" ]; then
    if pgrep -x openvpn > /dev/null; then
        echo -e "${DIM}[info]${NC} already connected"
        echo ""
        exit 0
    fi
else
    if openvpn3 sessions-list 2>/dev/null | grep -q "$CONFIG"; then
        echo -e "${DIM}[info]${NC} already connected to $CONFIG"
        echo ""
        exit 0
    fi
fi

# Check if YubiKey is connected
if ! ykman list 2>/dev/null | grep -q "YubiKey"; then
    echo -e "${RED}[error]${NC} no yubikey detected"
    echo -e "${DIM}        plug in your yubikey and try again${NC}"
    exit 1
fi

echo -e "${CYAN}[1/3]${NC} fetching totp from yubikey..."
TOTP=$(ykman oath accounts code "$TOTP_ACCOUNT" 2>&1)
TOTP_EXIT=$?

if [ $TOTP_EXIT -ne 0 ] || [ -z "$TOTP" ]; then
    if echo "$TOTP" | grep -q "No such account"; then
        echo -e "${RED}[error]${NC} totp account not found: $TOTP_ACCOUNT"
        echo -e "${DIM}        run 'ykman oath accounts list' to see available accounts${NC}"
    else
        echo -e "${RED}[error]${NC} failed to get totp code"
        echo -e "${DIM}        $TOTP${NC}"
    fi
    exit 1
fi

TOTP=$(echo "$TOTP" | awk '{print $NF}')

echo -e "${CYAN}[2/3]${NC} got totp: ${BOLD}$TOTP${NC}"
echo -e "${CYAN}[3/3]${NC} connecting to vpn..."

if [ "$OS_TYPE" = "macos" ]; then
    nohup sudo "${SCRIPT_DIR}/vpn-expect.exp" "$CONFIG" "$USERNAME" "$PASSWORD" "$TOTP" > /tmp/openvpn.log 2>&1 &
    sleep 8

    echo ""
    if pgrep -x openvpn > /dev/null; then
        echo -e "${GREEN}[connected]${NC} vpn running in background"
        echo -e "${DIM}            run 'vpn-off' to disconnect${NC}"
    else
        echo -e "${RED}[failed]${NC} check /tmp/openvpn.log for details"
    fi
else
    "${SCRIPT_DIR}/vpn-expect.exp" "$CONFIG" "$USERNAME" "$PASSWORD" "$TOTP" > /tmp/openvpn3.log 2>&1

    echo ""
    if openvpn3 sessions-list 2>/dev/null | grep -q "$CONFIG"; then
        echo -e "${GREEN}[connected]${NC} vpn session active"
        echo -e "${DIM}            run 'vpn-off' to disconnect${NC}"
    else
        echo -e "${RED}[failed]${NC} check /tmp/openvpn3.log for details"
    fi
fi
echo ""
