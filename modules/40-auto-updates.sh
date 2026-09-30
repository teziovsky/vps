#!/usr/bin/env bash
# Unattended security updates; needrestart restarts affected services by itself.
source "$(dirname "$0")/../lib/common.sh"

apt_install unattended-upgrades apt-listchanges needrestart

write_root_file /etc/apt/apt.conf.d/20auto-upgrades 644 <<'CONF' || true
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
CONF

write_root_file /etc/apt/apt.conf.d/52vps-unattended-upgrades 644 <<CONF || true
// Managed by vps (modules/40-auto-updates.sh). Origins come from the distro's 50unattended-upgrades.
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "$AUTO_REBOOT";
Unattended-Upgrade::Automatic-Reboot-Time "$AUTO_REBOOT_TIME";
CONF

write_root_file /etc/needrestart/conf.d/50-vps.conf 644 <<'CONF' || true
# Managed by vps: restart services after upgrades without asking.
$nrconf{restart} = 'a';
CONF

as_root systemctl enable --now apt-daily.timer apt-daily-upgrade.timer >/dev/null 2>&1 \
  || warn "could not enable apt timers (no systemd?)"
