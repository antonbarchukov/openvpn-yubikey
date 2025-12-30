# openvpn-yubikey

Connect to OpenVPN with YubiKey TOTP authentication. Automatically fetches the TOTP code from your YubiKey and handles the interactive auth prompts.

## what it does

1. Reads your VPN credentials from `vpn-connect.conf`
2. Fetches the current TOTP code from your YubiKey via `ykman`
3. Spawns OpenVPN and automatically enters username, password, and TOTP
4. Configures DNS resolvers for VPN domains (macOS `/etc/resolver`)

## requirements

- macOS
- OpenVPN (`brew install openvpn`)
- YubiKey with OATH TOTP configured (`brew install ykman`)
- expect (`brew install expect`)

## install

```bash
git clone https://github.com/antonbarchukov/openvpn-yubikey
cd openvpn-yubikey
./install.sh
```

### what install.sh does

1. Checks that `ykman`, `expect`, and `openvpn` are installed
2. Creates symlinks:
   - `/usr/local/bin/vpn-connect` -> `vpn-connect.sh`
   - `/usr/local/bin/vpn-disconnect` -> `vpn-disconnect.sh`
3. Installs DNS handler:
   - `/etc/openvpn/update-dns.sh` -> `update-dns.sh`
4. Creates `vpn-connect.conf` from template if it doesn't exist

## setup

Edit `vpn-connect.conf` with your credentials:

```bash
CONFIG="/path/to/your-config.ovpn"
USERNAME="your-username"
PASSWORD="your-password"
TOTP_ACCOUNT="OpenVPN:your-account@your-server.com"
```

To find your TOTP account name:

```bash
ykman oath accounts list
```

## usage

```bash
vpn-connect      # connect (requires yubikey)
vpn-disconnect   # disconnect
```

## how it works

### connect flow

1. `vpn-connect` reads credentials from `vpn-connect.conf`
2. Calls `ykman oath accounts code <account>` to get the current 6-digit TOTP from your YubiKey
3. Spawns `vpn-expect.exp` which launches OpenVPN in the background
4. The expect script handles OpenVPN's interactive prompts:
   - "Enter Auth Username:" -> sends username
   - "Enter Auth Password:" -> sends password
   - "CHALLENGE:" -> sends TOTP code
5. Once connected, OpenVPN calls `update-dns.sh` with `script_type=up`
6. DNS handler creates `/etc/resolver/<domain>` files for each VPN domain
7. macOS automatically routes DNS queries for those domains through the VPN

### disconnect flow

1. `vpn-disconnect` runs `killall openvpn`
2. OpenVPN receives SIGTERM and calls `update-dns.sh` with `script_type=down`
3. DNS handler removes the `/etc/resolver/<domain>` files it created
4. DNS returns to normal

### files

```
vpn-connect.sh      main script, fetches totp and launches vpn
vpn-expect.exp      expect script, handles interactive auth prompts
update-dns.sh       called by openvpn to configure/cleanup dns
vpn-disconnect.sh   kills openvpn (cleanup happens automatically)
vpn-connect.conf    your credentials (gitignored)
```
