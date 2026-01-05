# openvpn-yubikey

Connect to OpenVPN with YubiKey TOTP authentication. Automatically fetches the TOTP code from your YubiKey and handles the interactive auth prompts.

## what it does

1. Reads your VPN credentials from `vpn.conf`
2. Fetches the current TOTP code from your YubiKey via `ykman`
3. Spawns OpenVPN and automatically enters username, password, and TOTP
4. Handles DNS configuration (platform-specific)

## platform support

| | macOS | Linux |
|---|---|---|
| OpenVPN | 2.x (brew) | 3 (openvpn3) |
| DNS handling | Custom script (`/etc/resolver`) | Automatic (openvpn3) |
| Connection | Background process | Session-based |

## requirements

### macOS

- OpenVPN 2.x (`brew install openvpn`)
- YubiKey Manager (`brew install ykman`)
- expect (`brew install expect`)

### Linux (Arch)

- OpenVPN 3 (`yay -S openvpn3`)
- YubiKey Manager (`yay -S yubikey-manager`)
- expect (`sudo pacman -S expect`)

### Linux (Ubuntu/Debian)

- OpenVPN 3 (see [openvpn.net docs](https://openvpn.net/cloud-docs/owner/connectors/connector-user-guides/openvpn-3-client-for-linux.html))
- YubiKey Manager (`sudo apt install yubikey-manager`)
- expect (`sudo apt install expect`)

## install

```bash
git clone https://github.com/antonbarchukov/openvpn-yubikey
cd openvpn-yubikey
./install.sh
```

### what install.sh does

1. Checks dependencies (`ykman`, `expect`, `openvpn`/`openvpn3`)
2. Creates symlinks:
   - `/usr/local/bin/vpn-on` -> `vpn-on.sh`
   - `/usr/local/bin/vpn-off` -> `vpn-off.sh`
   - `/usr/local/bin/vpn-status` -> `vpn-status.sh`
3. Installs DNS handler script (macOS only: `/etc/openvpn/update-dns.sh`)
4. Creates `vpn.conf` from template if it doesn't exist

## setup

### macOS

Copy your `.ovpn` config file to the repo directory, then edit `vpn.conf`:

```bash
CONFIG="/path/to/your-config.ovpn"   # full path to .ovpn file
USERNAME="your-username"
PASSWORD="your-password"
TOTP_ACCOUNT="OpenVPN:your-account@your-server.com"  # from ykman oath accounts list
```

### Linux

First, import your OpenVPN config:

```bash
openvpn3 config-import --config your-config.ovpn --name myconfig
```

Then edit `vpn.conf`:

```bash
CONFIG="myconfig"                                    # openvpn3 config name
USERNAME="your-username"
PASSWORD="your-password"
TOTP_ACCOUNT="OpenVPN:your-account@your-server.com"  # from ykman oath accounts list
```

To find your TOTP account name:

```bash
ykman oath accounts list
```

## usage

```bash
vpn-on       # connect (requires yubikey)
vpn-off      # disconnect
vpn-status   # show connection status
```

## how it works

### macOS

1. `vpn-on` reads credentials from `vpn.conf`
2. Fetches TOTP from YubiKey via `ykman`
3. Runs `openvpn` in background via expect script (requires sudo)
4. DNS is configured via `/etc/resolver` using the custom `update-dns.sh` script
5. `vpn-off` kills the openvpn process and DNS is cleaned up automatically

### Linux

1. `vpn-on` reads credentials from `vpn.conf`
2. Fetches TOTP from YubiKey via `ykman`
3. Runs `openvpn3 session-start` via expect script
4. DNS is handled automatically by openvpn3
5. `vpn-off` runs `openvpn3 session-manage --disconnect`

### files

```
vpn-on.sh         main script, fetches totp and launches vpn
vpn-expect.exp    expect script, handles interactive auth prompts
vpn-off.sh        disconnects the vpn session
vpn-status.sh     shows current vpn status
vpn.conf          your credentials (gitignored)
update-dns.sh     dns handler for macOS (copied to /etc/openvpn/)
```
