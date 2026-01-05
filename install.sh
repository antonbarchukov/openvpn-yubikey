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

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)  OS_TYPE="linux" ;;
    Darwin*) OS_TYPE="macos" ;;
    *)       OS_TYPE="unknown" ;;
esac

echo -e "${DIM}detected: ${OS_TYPE}${NC}"
echo ""

# Check dependencies
echo -e "${CYAN}[1/3]${NC} checking dependencies..."

missing=0

if ! command -v ykman &> /dev/null; then
    if [ "$OS_TYPE" = "macos" ]; then
        echo -e "      ${RED}x${NC} ykman      ${DIM}brew install ykman${NC}"
    else
        echo -e "      ${RED}x${NC} ykman      ${DIM}yay -S yubikey-manager ${NC}${DIM}OR${NC}${DIM} sudo apt install yubikey-manager${NC}"
    fi
    missing=1
else
    echo -e "      ${GREEN}+${NC} ykman"
fi

if ! command -v expect &> /dev/null; then
    if [ "$OS_TYPE" = "macos" ]; then
        echo -e "      ${RED}x${NC} expect     ${DIM}brew install expect${NC}"
    else
        echo -e "      ${RED}x${NC} expect     ${DIM}sudo pacman -S expect ${NC}${DIM}OR${NC}${DIM} sudo apt install expect${NC}"
    fi
    missing=1
else
    echo -e "      ${GREEN}+${NC} expect"
fi

if ! command -v openvpn3 &> /dev/null; then
    if [ "$OS_TYPE" = "macos" ]; then
        echo -e "      ${RED}x${NC} openvpn3   ${DIM}brew install openvpn${NC}"
    else
        echo -e "      ${RED}x${NC} openvpn3   ${DIM}yay -S openvpn3 ${NC}${DIM}OR${NC}${DIM} see openvpn.net/cloud-docs${NC}"
    fi
    missing=1
else
    echo -e "      ${GREEN}+${NC} openvpn3"
fi

if [ $missing -eq 1 ]; then
    echo ""
    echo -e "${RED}[error]${NC} install missing dependencies and try again"
    exit 1
fi

echo ""
echo -e "${CYAN}[2/3]${NC} creating symlinks..."
sudo ln -sf "${SCRIPT_DIR}/vpn-on.sh" /usr/local/bin/vpn-on
sudo ln -sf "${SCRIPT_DIR}/vpn-off.sh" /usr/local/bin/vpn-off
sudo ln -sf "${SCRIPT_DIR}/vpn-status.sh" /usr/local/bin/vpn-status
echo -e "      ${GREEN}+${NC} /usr/local/bin/vpn-on"
echo -e "      ${GREEN}+${NC} /usr/local/bin/vpn-off"
echo -e "      ${GREEN}+${NC} /usr/local/bin/vpn-status"

echo ""
echo -e "${CYAN}[3/3]${NC} setting up config..."
if [ ! -f "${SCRIPT_DIR}/vpn.conf" ]; then
    cp "${SCRIPT_DIR}/vpn.conf.example" "${SCRIPT_DIR}/vpn.conf"
    echo -e "      ${GREEN}+${NC} created vpn.conf from template"
else
    echo -e "      ${DIM}-${NC} vpn.conf already exists"
fi

echo ""
echo -e "${DIM}--------------------------------${NC}"
echo -e "${GREEN}[done]${NC} installation complete"
echo ""
echo -e "${BOLD}usage${NC}"
echo -e "  vpn-on       connect to vpn"
echo -e "  vpn-off      disconnect from vpn"
echo -e "  vpn-status   show vpn status"
echo ""
echo -e "${BOLD}next steps${NC}"
echo -e "  1. import your ovpn config: ${CYAN}openvpn3 config-import --config your.ovpn --name myconfig${NC}"
echo -e "  2. edit ${CYAN}vpn.conf${NC} with your credentials"
echo -e "  3. run ${CYAN}ykman oath accounts list${NC} to find your totp account"
echo ""
