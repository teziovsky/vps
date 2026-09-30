#!/usr/bin/env bash
# Per-machine git tweaks in ~/.gitconfig.local. (~/.gitconfig itself: see 12-dotfiles.)
source "$(dirname "$0")/../lib/common.sh"

# The shared config pages through delta; not every distro packages it.
local_cfg="$HOME/.gitconfig.local"
marker="# managed by vps: delta missing"
if ! have delta; then
  cat >"$local_cfg" <<CONF
$marker
[core]
pager = less -FRX
[interactive]
diffFilter = cat
CONF
  warn "delta not installed; using plain less as git pager"
elif [[ -f "$local_cfg" ]] && grep -qxF "$marker" "$local_cfg"; then
  rm -f "$local_cfg"
fi
git config --global user.name >/dev/null && ok "git user: $(git config --global user.name) <$(git config --global user.email)>"
