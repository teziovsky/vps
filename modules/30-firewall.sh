#!/usr/bin/env bash
# ufw: deny incoming except SSH (rate-limited) and the profile's ports.
source "$(dirname "$0")/../lib/common.sh"

apt_install ufw

# Whatever port sshd really listens on, read from its live config.
ssh_ports="$(as_root sshd -T 2>/dev/null | awk '$1=="port"{print $2}')"
[[ -n "$ssh_ports" ]] || ssh_ports=22

as_root ufw default deny incoming >/dev/null
as_root ufw default allow outgoing >/dev/null
for p in $ssh_ports; do as_root ufw limit "$p/tcp" >/dev/null; done
for p in ${FIREWALL_ALLOW_TCP:-}; do as_root ufw allow "$p/tcp" >/dev/null; done
for p in ${FIREWALL_ALLOW_UDP:-}; do as_root ufw allow "$p/udp" >/dev/null; done
as_root ufw --force enable >/dev/null
as_root ufw status | sed 's/^/  /'
warn "Docker-published ports (-p 8080:80) bypass ufw. Bind them to 127.0.0.1 or put them behind the reverse proxy."
