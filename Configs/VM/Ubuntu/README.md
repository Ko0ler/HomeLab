# Ubuntu Pentest Lab Auto-Setup

A single Bash script that turns a fresh Ubuntu VM into a ready-to-use web-pentest practice box: base tooling, a customized shell (aliases and helper functions), and intentionally vulnerable Docker targets.

> ⚠️ **Warning:** This script deploys **intentionally vulnerable applications** (DVWA, bWAPP, a default WordPress stack) and is primarily designed for the HomeLab environment (I've set IPs and ports accordingly). Run it only in an isolated lab VM (NAT or host-only networking). Never expose it to a shared network or the internet.

---

## What it does

| Stage | Action |
|---|---|
| 1. System | `apt update && apt upgrade` |
| 2. Tools | Installs `open-vm-tools-desktop`, `build-essential`, `docker-ce docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`, `gedit`, `net-tools`, `netcat-openbsd`, `btop`, `plocate`, `tree` |
| 3. Shell config | Appends a `CUSTOM SETUP` block to `~/.bashrc` (skipped if already present) |
| 4. Targets | Pulls DVWA, bWAPP, and httpbin images |
| 5. WordPress lab | Creates `~/wordpress/` with a `.env` and a `docker-compose.yml` (WordPress + MySQL 8.0) |

---

## Requirements

- Ubuntu (22.04 or newer recommended; `docker-compose-v2` must be available in your release's repos)
- A regular user with `sudo` rights
- Internet access (apt and Docker Hub)
- Designed for a VMware guest (`open-vm-tools-desktop`, `/mnt/hgfs` shared folders)

---

## Usage

```bash
git clone https://github.com/Ko0ler/HomeLab.git
cd HomeLab/Configs/VM/Ubuntu
chmod +x InitialSetup.sh
./InitialSetup.sh
```

When it finishes, load the new config in your current shell:

```bash
exec bash
```

Then edit the attacker variables if needed in `~/.bashrc` (see [Configuration](#configuration)).

---

## Configuration

Set these in the `CUSTOM SETUP` block of `~/.bashrc`:

| Variable | Meaning | Default |
|---|---|---|
| `lip` | Local IP (auto-detected) | `hostname -I` |
| `lp` | Local port reference | `8080` |
| `ip` | Attacker machine IP | `192.168.160.130` |
| `po` | Attacker listener port | `4444` |
| `iph` / `iphs` | `http://` / `https://` URL of `$ip` | derived |

WordPress credentials and port live in `~/wordpress/.env`. **Change the default passwords** before using the stack for anything beyond a throwaway lab.

---

## Vulnerable targets

| Alias | Target | Host port |
|---|---|---|
| `dvwa` | Damn Vulnerable Web Application | 8080 |
| `bwapp` | bWAPP | 8070 |
| `httpb` | httpbin | 8060 |
| `wpsql` | WordPress + MySQL 8.0 (Compose) | 8050 |

Quick start:

```bash
dvwa; bwapp; httpb; wpsql
dp        # list running containers
nnl       # list listening ports
```

Then browse to `http://[VM_IP]:[HOST_PORT]`.

---

## Aliases

**Navigation / files**

| Alias | Command |
|---|---|
| `lls` | `ls -alhi` |
| `t` / `tt` | `tree -L 1` / `tree -L 2` |
| `cl` | `clear` |

**Network**

| Alias | Purpose |
|---|---|
| `ii` | Print local IP, attacker IP/port and URLs |
| `h` | Show host IPs |
| `p` | Ping 8.8.8.8 (internet check) |
| `pp` | Ping the attacker machine (`$ip`) |
| `pn` | Continuous ping to `$ip` |
| `ppp` | Full connectivity report (interfaces, internet, attacker) |
| `nn` | Established connections |
| `nnl` | Listening sockets |
| `nnc` | Connections with PID and numeric output |
| `tp` | `nc -vz $ip` (port check against the attacker host) |

**Docker**

| Alias | Purpose |
|---|---|
| `dp` / `dpp` | List running / all container IDs |
| `dr` | `docker run -d -p` shortcut |
| `ds` / `drm` | Stop / force-remove a container |
| `dsa` / `dra` | Stop / remove **all** containers |
| `wpsql` | Start the WordPress + MySQL stack |

**Shell**

| Alias | Purpose |
|---|---|
| `sc` | Reload `~/.bashrc` |
| `ssc` | Reload and clear |
| `spp` | Reload and ping attacker |
| `sp` | Reload, clear and run the full connectivity report |

---

## Functions

| Function | Usage | Description |
|---|---|---|
| `dppa` | `dppa` | Start all existing (stopped) containers, and go from where you left off |
| `sr` | `sr [KEYWORD]` | Search `/usr/bin` and `/usr/sbin` for a binary by keyword. Ex: `sr dump` to search for tcpdump  |
| `checkState` | `checkState [TARGET_IP] [PORT] [INTERVAL_SEC]` | Check a TCP port every N seconds with `nc -vz`. With no arguments it uses `$ip`, `$po` and 20 s |
| `kb` | `kb &` | Scroll Lock LED workaround for external keyboards in the VM (loops forever, run in background) |

---

## Re-running the script

- The `.bashrc` block is added only once (detected by the `CUSTOM SETUP` marker). Edits to the block in this repo are **not** propagated to machines already configured.
- Package installs and image pulls are safe to repeat.

---

## Uninstall / cleanup

```bash
# Stop and remove all containers
dsa; dra

# Remove the WordPress stack and its volumes
cd ~/wordpress && sudo docker compose down -v

# Remove the custom block from ~/.bashrc manually
# (everything from "CUSTOM SETUP" to the end of the block)
```
