# Attack Host Initial Setup

A single script that prepares a Kali-style attack VM for our homelab and CTF work: base tooling, a customized **zsh** environment (target variables, aliases, helper functions), and a **tmux** configuration.

> ⚠️ **Use only against systems you own or have explicit written permission to test.** It is primarily designed and meant as the attack host for the HomeLab environment (I've set IPs and ports accordingly). The scan helpers in this setup are meant for lab targets (HTB, local VMs, authorized engagements).

---

## What it does

| Stage | Action |
|---|---|
| 1. System | `apt update && apt full-upgrade` |
| 2. Tools | Installs `open-vm-tools-desktop`, `zsh`, `gedit`, `build-essential`, `openvpn`, `tmux`, `tree`, `locate`, `btop`, `nmap`, `wafw00f`, `whatweb`, `curl`, `netcat-openbsd`, `git`, `python3-pip`, `python3-venv` |
| 3. Zsh config | Appends a `CUSTOM SETUP` block to `~/.zshrc` (skipped if already present) |
| 4. Tmux config | Writes custom settings to `~/.tmux.conf` (skipped if already present) |
| 5. Finalize | Refreshes the `locate` database |

---

## Requirements

- Kali Linux or a similar distro (Parrot, Debian-based) with `zsh` as the login shell
- A regular user with `sudo` rights
- Internet access

---

## Usage

```bash
git clone https://github.com/Ko0ler/HomeLab.git
cd HomeLab/Configs/VM/Attack\ Host/
chmod +x InitialSetup.sh
./InitialSetup.sh
```

When it finishes, load the new config:

```bash
exec zsh
```

---

## Configuration

Edit the variables at the top of the script **before** running it:

| Variable | Meaning | Default |
|---|---|---|
| `LOCAL_TARGET_IP` | Local lab target | `10.10.3.3` - This is the DMZ IP as configured in the [ASA firewall](../Appliance/FW.cfg) |
| `LOCAL_TARGET_PORT` | Local target service port | `8080` - for the DVWA |
| `ONLINE_TARGET_IP` | Online target (HackTheBox, Pentest, etc.) | read from `$TARGET`, or set as you wish |
| `ONLINE_TARGET_PORT` | Online target service port | `80` |

They become these shell variables:

| Variable | Description |
|---|---|
| `ipo`, `po` | Local target IP and port |
| `ipho`, `iphso` | `http://` and `https://` URLs of the local target |
| `lipo`, `lpo` | Your attacker IP and listener port (local lab) |
| `ip`, `p` | Online target IP and port |
| `iph`, `iphs` | `http://` and `https://` URLs of the online target |
| `lip`, `lp` | Your attacker IP (VPN interface) and listener port |

To change the online target during an engagement:

```bash
export TARGET=[TARGET_IP]
sc          # reload zsh config
```

### Path variables

Uncomment and adjust these to your own shared-folder layout. **Always quote them** because they contain spaces:

```bash
cd "$ws"
```

---

## Aliases

**Navigation and system**

| Alias | Command |
|---|---|
| `lls` | `ls -alhi` |
| `t` / `tt` | `tree -L 1` / `tree -L 2` |
| `cl` | `clear` |
| `sc` | Reload `~/.zshrc` |
| `ssc` | Reload and clear |
| `rr` | Clean the current directory, keeping `Data.txt` (**destructive**, see warning below) |

**Networking**

| Alias | Purpose |
|---|---|
| `ii` | Print all target and attacker variables |
| `h` | Show host IPs |
| `p` | Ping `8.8.8.8` (internet check) |
| `pp` / `ppo` | Ping the online / local target |
| `ppp` | Full report: interfaces, variables, internet, local target, online target |
| `nn` | Established connections (`ss`) |
| `nnl` | Listening sockets (`ss -tulpn`) |
| `nnc` | Connections with PIDs, numeric output |
| `tp` / `tpo` | `nc -vz` against the online / local target |

---

## Functions

| Function | Usage | Description |
|---|---|---|
| `sr` | `sr [KEYWORD]` | Search `/usr/bin`, `/usr/local/bin` and `/opt/tools` for a binary by keyword. Ex: `sr blood` to search for bloodhound-python |
| `checktarget` | `checktarget [TARGET_IP] [PORT] [INTERVAL_SEC]` | Check a TCP port every N seconds with `nc -vz`. With no arguments it uses `$ip`, `$p` and 20 s |
| `targetscan` | `targetscan` | Two Nmap passes against `$ip`: `-sS -sV` and `-sS -A`. Output saved as `nmap-tcp-1` and `nmap-tcp-2` |
| `webscan` | `webscan` | Web footprinting with `wafw00f` and `whatweb` against `$iph:$p`. Output saved as `wafcheck-1` and `whatweb-1` |

Notes:

- `targetscan` covers the **top 1000 ports only**. Add a full `-p-` pass for complete coverage.
- Output files are written to the **current directory**, so run these from your target's working folder.

---

## Tmux

**Prefix:** `Ctrl + Space`

| Key (after prefix) | Action |
|---|---|
| `r` | Reload `~/.tmux.conf` |
| `x` | Split pane vertically (top/bottom) |
| `y` | Split pane horizontally (left/right) |
| `h` `j` `k` `l` | Move to left / down / up / right pane |

Other settings: mouse enabled, 50,000-line scrollback, windows and panes numbered from 1.

---

## Re-running the script

- The `.zshrc` and `.tmux.conf` blocks are added only once. Edits to them in this repo **do not propagate** to machines already configured.
- Package installs are safe to repeat.
