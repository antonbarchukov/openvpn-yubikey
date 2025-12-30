#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

echo ""
echo -e "${BOLD}openvpn-yubikey installer${NC}"
echo -e "${DIM}--------------------------------${NC}"
echo ""

# Check dependencies
echo -e "${CYAN}[1/4]${NC} checking dependencies..."

missing=0

if ! command -v ykman &> /dev/null; then
    echo -e "      ${RED}x${NC} ykman      ${DIM}brew install ykman${NC}"
    missing=1
else
    echo -e "      ${GREEN}+${NC} ykman"
fi

if ! command -v expect &> /dev/null; then
    echo -e "      ${RED}x${NC} expect     ${DIM}brew install expect${NC}"
    missing=1
else
    echo -e "      ${GREEN}+${NC} expect"
fi

if [ ! -f /opt/homebrew/sbin/openvpn ] && [ ! -f /usr/local/sbin/openvpn ]; then
    echo -e "      ${RED}x${NC} openvpn    ${DIM}brew install openvpn${NC}"
    missing=1
else
    echo -e "      ${GREEN}+${NC} openvpn"
fi

if [ $missing -eq 1 ]; then
    echo ""
    echo -e "${RED}[error]${NC} install missing dependencies and try again"
    exit 1
fi

echo ""
echo -e "${CYAN}[2/4]${NC} creating symlinks..."
sudo ln -sf "${SCRIPT_DIR}/vpn-connect.sh" /usr/local/bin/vpn-connect
sudo ln -sf "${SCRIPT_DIR}/vpn-disconnect.sh" /usr/local/bin/vpn-disconnect
echo -e "      ${GREEN}+${NC} /usr/local/bin/vpn-connect"
echo -e "      ${GREEN}+${NC} /usr/local/bin/vpn-disconnect"

echo ""
echo -e "${CYAN}[3/4]${NC} installing dns handler..."
sudo mkdir -p /etc/openvpn
sudo ln -sf "${SCRIPT_DIR}/update-dns.sh" /etc/openvpn/update-dns.sh
echo -e "      ${GREEN}+${NC} /etc/openvpn/update-dns.sh"

echo ""
echo -e "${CYAN}[4/4]${NC} setting up config..."
if [ ! -f "${SCRIPT_DIR}/vpn-connect.conf" ]; then
    cp "${SCRIPT_DIR}/vpn-connect.conf.example" "${SCRIPT_DIR}/vpn-connect.conf"
    echo -e "      ${GREEN}+${NC} created vpn-connect.conf from template"
else
    echo -e "      ${DIM}-${NC} vpn-connect.conf already exists"
fi

echo ""
echo -e "${DIM}--------------------------------${NC}"
echo -e "${GREEN}[done]${NC} installation complete"
echo ""
echo -e "${BOLD}usage${NC}"
echo -e "  vpn-connect      connect to vpn"
echo -e "  vpn-disconnect   disconnect from vpn"
echo ""
echo -e "${BOLD}next steps${NC}"
echo -e "  1. edit ${CYAN}vpn-connect.conf${NC} with your credentials"
echo -e "  2. run ${CYAN}ykman oath accounts list${NC} to find your totp account"
echo ""
