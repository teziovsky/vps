#!/usr/bin/env bash
# Isolate the Hermes gateway from ~/apps, ~/backups and ~/src (systemd drop-in).
# Does nothing on hosts without the hermes-gateway user unit.
source "$(dirname "$0")/../lib/common.sh"

unit="$HOME/.config/systemd/user/hermes-gateway.service"
[[ -f "$unit" ]] || { ok "no hermes-gateway user unit; nothing to do"; exit 0; }

link_file "$VPS_ROOT/dotfiles/systemd/hermes-gateway-isolation.conf" \
  "$HOME/.config/systemd/user/hermes-gateway.service.d/isolation.conf"
systemctl --user daemon-reload
warn "restart to apply: systemctl --user restart hermes-gateway (briefly drops Slack/Telegram)"
