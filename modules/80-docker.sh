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

# lazydocker: terminal UI for containers (the `lzd` alias). Static release binary.
if ! have lazydocker; then
  case "$(arch_name)" in x86_64) ld_arch=x86_64 ;; *) ld_arch=arm64 ;; esac
  ld_tmp="$(mktemp -d)"
  ld_url="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest \
    | grep -o "https://[^\"]*Linux_${ld_arch}\.tar\.gz" | head -1 || true)"
  if [[ -n "$ld_url" ]] && curl -fsSL "$ld_url" | tar -xz -C "$ld_tmp" lazydocker; then
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$ld_tmp/lazydocker" "$HOME/.local/bin/lazydocker"
    ok "installed lazydocker"
  else
    warn "could not install lazydocker"
  fi
  rm -rf "$ld_tmp"
else
  ok "lazydocker present"
fi

# Weekly prune of unused images, stopped containers and build cache older than a week.
# Never touches volumes.
if [[ "${DOCKER_PRUNE:-true}" == true ]]; then
  write_root_file /etc/systemd/system/docker-prune.service 644 <<'UNIT' || true
[Unit]
Description=Prune unused Docker data (managed by vps)
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker system prune --all --force --filter until=168h
UNIT
  write_root_file /etc/systemd/system/docker-prune.timer 644 <<'UNIT' || true
[Unit]
Description=Weekly Docker prune (managed by vps)

[Timer]
OnCalendar=Sun 03:30
RandomizedDelaySec=30m
Persistent=true

[Install]
WantedBy=timers.target
UNIT
  as_root systemctl daemon-reload
  as_root systemctl enable --now docker-prune.timer >/dev/null 2>&1 || warn "could not enable docker-prune.timer"
fi
