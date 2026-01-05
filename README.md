# openvpn-yubikey

Connect to OpenVPN with YubiKey TOTP authentication. Automatically fetches the TOTP code from your YubiKey and handles the interactive auth prompts.

## what it does

1. Reads your VPN credentials from `vpn.conf`
2. Fetches the current TOTP code from your YubiKey via `ykman`
3. Spawns OpenVPN 3 and automatically enters username, password, and TOTP
4. DNS is handled automatically by OpenVPN 3

## requirements

### macOS

- OpenVPN 3 (`brew install openvpn`)
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

1. Checks that `ykman`, `expect`, and `openvpn3` are installed
2. Creates symlinks:
   - `/usr/local/bin/vpn-on` -> `vpn-on.sh`
   - `/usr/local/bin/vpn-off` -> `vpn-off.sh`
   - `/usr/local/bin/vpn-status` -> `vpn-status.sh`
3. Creates `vpn.conf` from template if it doesn't exist

## setup

First, import your OpenVPN config:

```bash
openvpn3 config-import --config your-config.ovpn --name myconfig
```

Then edit `vpn.conf` with your credentials:

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

### connect flow

1. `vpn-on` reads credentials from `vpn.conf`
2. Calls `ykman oath accounts code <account>` to get the current 6-digit TOTP from your YubiKey
3. Spawns `vpn-expect.exp` which runs `openvpn3 session-start`
4. The expect script handles OpenVPN's interactive prompts:
   - "Auth User name:" -> sends username
   - "Auth Password:" -> sends password
   - "CHALLENGE:" / "Response:" -> sends TOTP code
5. OpenVPN 3 handles DNS configuration automatically

### disconnect flow

1. `vpn-off` runs `openvpn3 session-manage --disconnect`
2. OpenVPN 3 cleans up DNS automatically

### files

```
vpn-on.sh         main script, fetches totp and launches vpn
vpn-expect.exp    expect script, handles interactive auth prompts
vpn-off.sh        disconnects the vpn session
vpn-status.sh     shows current vpn status
vpn.conf          your credentials (gitignored)
```
