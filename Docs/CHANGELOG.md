# Changelog

All notable changes to this lab are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Known issues and misconfigs
- External source → DMZ and inside LAN → Internet throughput capped near 150 Kbps, while outside-segment traffic reaches 5+ Mbps (depending on the host internet speed.
- Frequent packets lost from the firewall. Suspecting the throttled bandwidth and eval mode
- Intermittent GNS3 controller 404 errors (`POST .../qemu/nodes/.../reload`) on random nodes, self-resolving. Suspected compute server resource starvation or CPU (host and VMs) synchronization issues.
- VLAN 100 has an SVI on SW-L3 and is trunked, but is absent from the ASA `INSIDE_SUBNETS` object group — no ACL permit or NAT coverage yet.

## [2026-10-12]

### Added
- Repository documentation (`README.md`), device configs, and topology diagram.

### Fixed
- SW-L3 had two default routes (an interface route and a next-hop route), causing ECMP/ARP inconsistency. Corrected to a single next-hop default route.
- ASA inside route was an overly broad `192.168.0.0/16`, bleeding into the `192.168.160.0/24` outside segment. Replaced with per-VLAN `/24` routes.
- ASAv was unregistered, capping throughput at ~100 Kbps. Fixed via local Smart Licensing declaration (`feature tier standard`, `throughput level 1G`) — now in Evaluation Mode, authorized, with a 90-day grace window.

### Confirmed working
- Inside LAN and `192.168.160.0/24` reach the internet and the DMZ with the intended ACLs, after the routing fixes above.
- NAT (PAT for inside subnets, static NAT for the DMZ host) configured and verified on the ASA.
