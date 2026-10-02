#!/usr/bin/env bash
# Fresh VPS, as root (or via sudo):
#   curl -fsSL https://raw.githubusercontent.com/teziovsky/vps/main/bootstrap.sh | sudo VPS_USER=<login> bash
# Optional: VPS_MODULES="base dotfiles ..." (one-off module list), VPS_REF=<commit or tag> (pin the code).
# Creates the login user (with your SSH keys), clones this repo into its home and runs `vps apply` as that user.
set -euo pipefail

VPS_REPO="${VPS_REPO:-https://github.com/teziovsky/vps.git}"
VPS_USER="${VPS_USER:?set VPS_USER to the login name to create}"
VPS_REF="${VPS_REF:-}"
VPS_MODULES="${VPS_MODULES:-}"
VPS_PROFILE="${VPS_PROFILE:-}"

((EUID == 0)) || { echo "run as root: sudo bash bootstrap.sh" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends git curl sudo ca-certificates >/dev/null

if ! id "$VPS_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos '' "$VPS_USER"
  echo "created user $VPS_USER"
fi
usermod -aG sudo "$VPS_USER"

# Give the new user whatever keys root logs in with, so closing the root session is safe.
home="$(getent passwd "$VPS_USER" | cut -d: -f6)"
if [[ -s /root/.ssh/authorized_keys ]]; then
  install -d -m 700 -o "$VPS_USER" -g "$VPS_USER" "$home/.ssh"
  touch "$home/.ssh/authorized_keys"
  while IFS= read -r key; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    grep -qxF "$key" "$home/.ssh/authorized_keys" || echo "$key" >>"$home/.ssh/authorized_keys"
  done </root/.ssh/authorized_keys
  chown "$VPS_USER:$VPS_USER" "$home/.ssh/authorized_keys"
  chmod 600 "$home/.ssh/authorized_keys"
fi

# Passwordless sudo is the default for a key-only user; vps apply can tighten it (SUDO_NOPASSWD=no).
if [[ ! -f /etc/sudoers.d/90-vps-user ]]; then
  echo "$VPS_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-vps-user.tmp
  chmod 440 /etc/sudoers.d/90-vps-user.tmp
  visudo -cf /etc/sudoers.d/90-vps-user.tmp >/dev/null
  mv /etc/sudoers.d/90-vps-user.tmp /etc/sudoers.d/90-vps-user
fi

VPS_DIR="${VPS_DIR:-/opt/vps}"
if [[ ! -d "$VPS_DIR/.git" ]]; then
  install -d -o "$VPS_USER" -g "$(id -gn "$VPS_USER")" "$VPS_DIR"
  runuser -u "$VPS_USER" -- git clone -q "$VPS_REPO" "$VPS_DIR"
  [[ -z "$VPS_REF" ]] || runuser -u "$VPS_USER" -- git -C "$VPS_DIR" checkout -q "$VPS_REF"
fi

exec runuser -u "$VPS_USER" -- env HOME="$home" VPS_USER="$VPS_USER" VPS_PROFILE="$VPS_PROFILE" VPS_MODULES="$VPS_MODULES" "$VPS_DIR/vps" apply
