#!/usr/bin/env bash
# Kernel network and memory hardening. ip_forward is left alone (Docker needs it).
source "$(dirname "$0")/../lib/common.sh"

write_root_file /etc/sysctl.d/99-vps.conf 644 <<'CONF' || true
# Managed by vps (modules/50-sysctl.sh)
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_regular = 2
fs.protected_fifos = 2
vm.swappiness = 10
CONF

# Containers and some VPS types refuse individual keys; that is not fatal.
as_root sysctl --system >/dev/null 2>&1 || warn "some sysctl keys were rejected by this kernel"
