#!/usr/bin/env bash
# LXC guests cannot mount configfs or remount the root fs, and snapd cannot run
# without squashfs/apparmor. Mask those units so `vps audit` stays clean.
# snapd is only masked when no snaps are installed.
source "$(dirname "$0")/../lib/common.sh"

units=()
if [[ "$(systemd-detect-virt 2>/dev/null || true)" == lxc ]]; then
  units+=(sys-kernel-config.mount systemd-remount-fs.service)
fi
if ! compgen -G '/var/lib/snapd/snaps/*.snap' >/dev/null; then
  units+=(snapd.service snapd.socket snapd.seeded.service)
fi

((${#units[@]})) || { ok "nothing to mask"; exit 0; }
as_root systemctl mask "${units[@]}" >/dev/null 2>&1 || warn "could not mask: ${units[*]}"
as_root systemctl reset-failed >/dev/null 2>&1 || true
ok "masked: ${units[*]}"
