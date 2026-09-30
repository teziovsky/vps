#!/usr/bin/env bash
# fail2ban: ban hosts that hammer sshd.
source "$(dirname "$0")/../lib/common.sh"

apt_install fail2ban python3-systemd

ssh_ports="$(as_root sshd -T 2>/dev/null | awk '$1=="port"{print $2}' | paste -sd, -)"

# backend=systemd: Debian 13 has no /var/log/auth.log unless rsyslog is installed.
changed=0
write_root_file /etc/fail2ban/jail.d/vps.local 644 <<CONF && changed=1 || true
# Managed by vps (modules/35-fail2ban.sh)
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 ::1
backend  = systemd

[sshd]
enabled = true
port    = ${ssh_ports:-ssh}
CONF

as_root systemctl enable fail2ban >/dev/null 2>&1 || warn "could not enable fail2ban"
if ((changed)); then as_root systemctl restart fail2ban || warn "fail2ban did not start"
else as_root systemctl start fail2ban 2>/dev/null || true; fi
as_root fail2ban-client status sshd 2>/dev/null | sed 's/^/  /' || true
