#!/usr/bin/env bash
# Isolate the Hermes gateway from ~/apps, ~/backups and ~/src (systemd drop-in) and keep it
# running across logouts and reboots (linger + enabled user unit).
# Does nothing on hosts without the hermes-gateway user unit.
source "$(dirname "$0")/../lib/common.sh"

unit="$HOME/.config/systemd/user/hermes-gateway.service"
[[ -f "$unit" ]] || { ok "no hermes-gateway user unit; nothing to do"; exit 0; }

link_file "$VPS_ROOT/dotfiles/systemd/hermes-gateway-isolation.conf" \
  "$HOME/.config/systemd/user/hermes-gateway.service.d/isolation.conf"
systemctl --user daemon-reload

# Without linger the user manager (and so the gateway) only starts at login, which never
# happens after a reboot of a headless box.
if [[ "$(loginctl show-user "$USER" -p Linger --value 2>/dev/null)" != yes ]]; then
  as_root loginctl enable-linger "$USER"
fi
systemctl --user enable hermes-gateway.service >/dev/null 2>&1
ok "hermes-gateway enabled at boot (linger on)"
warn "restart to apply: systemctl --user restart hermes-gateway (briefly drops Slack/Telegram)"
