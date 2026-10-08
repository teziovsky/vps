#!/usr/bin/env bash
# Tailscale SSH: devices signed in to your tailnet can ssh in without a key in authorized_keys.
# Does nothing when Tailscale is not installed or not logged in.
source "$(dirname "$0")/../lib/common.sh"

have tailscale || { warn "tailscale is not installed; skipping"; exit 0; }
as_root tailscale status >/dev/null 2>&1 || { warn "tailscale is not logged in; skipping"; exit 0; }

want="${TAILSCALE_SSH:-true}"
now="$(as_root tailscale debug prefs | awk -F'[:,]' '/"RunSSH"/{gsub(/ /,"",$2); print $2}')"

if [[ "$want" == "$now" ]]; then
  ok "tailscale ssh already $([[ $want == true ]] && echo on || echo off)"
else
  as_root tailscale set --ssh="$want"
  ok "tailscale ssh set to $want"
fi
warn "Tailscale SSH is gated by the tailnet ACL 'ssh' rules (login.tailscale.com/admin/acls); keep 2FA on the account."
