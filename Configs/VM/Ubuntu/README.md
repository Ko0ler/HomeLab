# Ubuntu Auto-Setup

A single Bash script that turns a fresh Ubuntu VM (or any Debian distro) into a ready-to-use web-pentest practice box: base tooling, a customized shell (aliases and helper functions), and intentionally vulnerable Docker targets. This is meant to be a target host for the Kali, which is set up [here](../Attack%20Host)

> ⚠️ **Warning:** This script deploys **intentionally vulnerable applications** (DVWA, bWAPP, a default WordPress stack) and is primarily designed for the HomeLab environment (I've set IPs and ports accordingly). Run it only in an isolated lab VM (NAT or host-only networking). Never expose it to a shared network or the internet. See the **Disclaimer & Responsible Use** section of the [main README](../../../README.md).

---

## What it does

| Stage | Action |
|---|---|
| 1. System | `apt update && apt upgrade` |
| 2. Tools | Installs `open-vm-tools-desktop`, `build-essential`, `docker-ce docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`, `gedit`, `net-tools`, `netcat-openbsd`, `btop`, `plocate`, `tree` |
| 3. Shell config | Appends a `CUSTOM SETUP` block to `~/.bashrc` (skipped if already present) |
| 4. Images | Pulls the DVWA, bWAPP, httpbin, Mailpit, and WordPress images |
| 5. WordPress lab | Creates `~/wordpress/` with a `.env` (randomly generated database passwords) and a `docker-compose.yml` (WordPress + MySQL 8.0 + Mailpit). Existing files are kept |
| 6. Bootstrap | WordPress auto-install and Mailpit binding. Resets any previous WordPress stack (`docker compose down -v`), starts the stack, waits until WordPress is ready, installs WP-CLI inside the container, runs `wp core install`, then installs **WP Mail SMTP** and points it to Mailpit |
| 7. Cleanup | Stops and removes created containers in the process (the WordPress stack from `docker-compose.yml`) so you start from a clean state (named volumes are kept). Start everything again with `fullweb` |

---

## Requirements

- Ubuntu (22.04 or newer recommended)
- A regular user with `sudo` rights (`openssl` is used to generate passwords and is preinstalled on Ubuntu)
- Internet access: apt, Docker Hub, GitHub (WP-CLI download), and wordpress.org (plugin download)
- Designed for a VMware guest (`open-vm-tools-desktop`, `/mnt/hgfs` shared folders), but fine to run on an Ubuntu/Debian as main host

> 💡 If the VM sits behind the lab firewall in evaluation mode, bandwidth is capped, and the image pulls will be slow. Use a temporary NAT adapter for the setup, as described in the main README.

---

## Usage

```bash
git clone https://github.com/Ko0ler/HomeLab.git
cd HomeLab/Configs/VM/Ubuntu
chmod +x InitialSetup.sh
./InitialSetup.sh
```

The script takes several minutes (updates, image pulls, WordPress bootstrap) and ends with `SETUP COMPLETED`. Then load the new shell config and start the targets with this oneliner:

```bash
{ source ~/.bashrc && { dsf; drf; } 2>/dev/null; fullweb && echo && dp && echo && nnl; } || { echo -e '\\\n[!] An error occurred!'; }
```

You can then edit the attacker variables if needed in `~/.bashrc` (see [Configuration](#configuration)).

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

The WordPress stack is configured in `~/wordpress/.env`, created once with permissions `600`. An existing `.env` is never overwritten.

| Variable | Meaning | Default |
|---|---|---|
| `MYSQL_ROOT_PASSWORD` | MySQL root password | generated randomly |
| `MYSQL_DATABASE` / `MYSQL_USER` | Database name / user | `wordpress` / `wordpress_user` |
| `MYSQL_PASSWORD` | Database user password | generated randomly |
| `WP_ADMIN_USER` | WordPress admin user | `admin` |
| `WP_ADMIN_PASSWORD` | WordPress admin password | generated randomly |
| `WORDPRESS_PORT` | Host port for WordPress | `8050` |
| `MAILPIT_UI_PORT` / `MAILPIT_SMTP_PORT` | Mailpit web UI / SMTP ports (bound to `127.0.0.1`) | `8025` / `1025` |
| `MP_MAX_MESSAGES`, `MP_SMTP_AUTH_*` | Mailpit message limit and SMTP auth behavior | `5000`, accept any |

---

## Vulnerable targets

| Alias | Target | Host port |
|---|---|---|
| `dvwa` | Damn Vulnerable Web Application | 8080 |
| `bwapp` | bWAPP | 8070 |
| `httpb` | httpbin | 8060 |
| `wpsql` | WordPress + MySQL 8.0 + Mailpit (Compose) | 8050 |
| `fullweb` | Starts all of the above | all |

Mailpit (mail catcher) is reachable at `http://localhost:8025` **from the VM only**, because its ports are bound to the loopback interface. WordPress sends mail through WP Mail SMTP to `mailpit:1025` inside the Docker network, so password-reset emails and similar messages land in Mailpit.

Quick start:

```bash
fullweb     # or start targets one by one: dvwa; bwapp; httpb; wpsql
dp          # list running containers
nnl         # list listening ports
```

Then, from the attack host (e.g., Kali or any other host), browse to `http://[VM_IP]:[HOST_PORT]`. In our lab context, it would be `http://10.10.3.3:8050`

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
| `dp` / `dpp` | List running containers / list all container IDs |
| `dr` | `docker run -d -p` shortcut |
| `dsf` / `drf` | Stop / remove target containers from `fullweb` |
| `dsa` / `dra` | Stop / remove **all** containers |
| `wpsql` | Start the WordPress + MySQL + Mailpit stack |
| `fullweb` | Start DVWA, bWAPP, httpbin and the WordPress stack |

**Shell**

| Alias | Purpose |
|---|---|
| `sc` | Reload `~/.bashrc` |
| `ssc` | Reload and clear |
| `spp` | Reload and ping attacker |
| `sp` | Reload, clear, and run the full connectivity report |

---

## Functions

| Function | Usage | Description |
|---|---|---|
| `dppa` | `dppa` | Start all existing (stopped) containers, and go from where you left off |
| `sr` | `sr [KEYWORD]` | Search `/usr/bin` and `/usr/sbin` for a binary by keyword. Ex: `sr dump` to search for tcpdump |
| `checkState` | `checkState [TARGET_IP] [PORT] [INTERVAL_SEC]` | Check a TCP port every N seconds with `nc -vz`. With no arguments it uses `$ip`, `$po` and 20 s |
| `kb` | `kb &` | Scroll Lock LED workaround for external keyboards in the VM (loops forever, runs in background) |

---

## Re-running the script

- The `.bashrc` block is added only once (detected by the `CUSTOM SETUP` marker). Edits to the block in this repo are **not** propagated to machines already configured.
- Package installs and image pulls are safe to repeat.
- `~/wordpress/.env` and `~/wordpress/docker-compose.yml` are not overwritten if they exist.
- ⚠️ The WordPress bootstrap runs `docker compose down -v` first: **the WordPress and database volumes are deleted** (posts, users, installed plugins), and WordPress is reinstalled. Copy anything you want to keep beforehand.
- WP-CLI is installed inside the WordPress container, so it disappears whenever that container is removed (cleanup stage).

---

## Uninstall / cleanup

```bash
# Stop and remove target containers
dsf; drf

# Remove the WordPress stack and its volumes
sudo docker compose -f ~/wordpress/docker-compose.yml down -v

# Remove the custom block from ~/.bashrc manually
# (everything from "CUSTOM SETUP" to "END CUSTOM SETUP" of the block)
```
