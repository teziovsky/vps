#!/usr/bin/env bash
# Packages everything else relies on, timezone, locale, optional swap.
source "$(dirname "$0")/../lib/common.sh"

apt_install ca-certificates curl git sudo unzip zip jq htop vim tmux ncdu rsync less locales tzdata \
  openssh-client zsh
apt_install_optional ripgrep fzf fd-find eza bat git-delta systemd-timesyncd

# Debian names these fdfind/batcat; the dotfiles expect fd.
mkdir -p "$HOME/.local/bin"
if have fdfind && ! have fd; then ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi

if [[ -n "${TIMEZONE:-}" && "$(cat /etc/timezone 2>/dev/null)" != "$TIMEZONE" ]]; then
  as_root timedatectl set-timezone "$TIMEZONE" 2>/dev/null \
    || as_root ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime \
    || warn "could not set timezone"
fi

if ! locale -a 2>/dev/null | grep -qi '^en_US.utf-\?8$'; then
  as_root sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
  as_root locale-gen >/dev/null
  ok "generated en_US.UTF-8"
fi

if ((${SWAP_MB:-0} > 0)) && [[ -z "$(swapon --show --noheadings)" ]]; then
  if as_root fallocate -l "${SWAP_MB}M" /swapfile 2>/dev/null; then
    as_root chmod 600 /swapfile
    as_root mkswap /swapfile >/dev/null
    as_root swapon /swapfile
    grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' | as_root tee -a /etc/fstab >/dev/null
    ok "swap ${SWAP_MB}M"
  else
    warn "could not create swap (containers and some VPS types forbid it)"
  fi
fi
