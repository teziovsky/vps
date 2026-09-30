#!/usr/bin/env bash
# Docker Engine from Docker's own repo, with log rotation.
source "$(dirname "$0")/../lib/common.sh"

if have docker; then
  ok "docker $(docker --version)"
else
  curl -fsSL https://get.docker.com | as_root sh >/dev/null 2>&1 || die "docker install failed"
  ok "installed docker"
fi

# Unrotated json logs are the classic way a small VPS disk fills up.
if [[ ! -f /etc/docker/daemon.json ]]; then
  write_root_file /etc/docker/daemon.json 644 <<'CONF' || true
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "3" }
}
CONF
  as_root systemctl restart docker 2>/dev/null || warn "restart docker to apply log rotation"
else
  ok "keeping existing /etc/docker/daemon.json"
fi

as_root systemctl enable --now docker >/dev/null 2>&1 || true
if ! id -nG "$USER" | grep -qw docker; then
  as_root usermod -aG docker "$USER"
  warn "added $USER to the docker group; log out and in for it to apply"
fi
