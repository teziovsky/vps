#!/usr/bin/env bash
# sshd: key-only login, no root, limited users. Refuses to lock you out.
source "$(dirname "$0")/../lib/common.sh"

have sshd || apt_install openssh-server

# Every allowed user must already hold a key, or password login going away would end the session.
for u in $SSH_ALLOW_USERS; do
  home="$(getent passwd "$u" | cut -d: -f6)" || die "user $u does not exist"
  [[ -s "$home/.ssh/authorized_keys" ]] || die "$u has no ~/.ssh/authorized_keys; add a key first (refusing to disable passwords)"
done

# sshd uses the FIRST value it sees per keyword and reads sshd_config.d alphabetically,
# so this must sort before cloud-init's 50-cloud-init.conf (PasswordAuthentication yes).
conf=/etc/ssh/sshd_config.d/00-vps-hardening.conf
if ! grep -qE '^\s*Include\s+/etc/ssh/sshd_config.d/\*\.conf' /etc/ssh/sshd_config; then
  warn "sshd_config has no Include for sshd_config.d; adding one at the top"
  as_root sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
fi

changed=0
write_root_file "$conf" 644 <<CONF && changed=1 || true
# Managed by vps (modules/20-ssh-harden.sh)
PermitRootLogin $SSH_PERMIT_ROOT
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
AllowUsers $SSH_ALLOW_USERS
MaxAuthTries 3
LoginGraceTime 30
MaxStartups 10:30:60
X11Forwarding no
AllowAgentForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
CONF

as_root mkdir -p /run/sshd
if ! as_root sshd -t; then
  as_root rm -f "$conf"
  die "sshd rejected the new config; removed it"
fi

if ((changed)); then
  as_root systemctl reload ssh 2>/dev/null || as_root systemctl reload sshd 2>/dev/null \
    || warn "could not reload sshd (no systemd?); restart it yourself"
  warn "sshd hardened. Keep this session open and test a NEW login before you log out."
fi
as_root sshd -T | grep -Ei '^(passwordauthentication|permitrootlogin|allowusers) ' | sed 's/^/  /'
