#!/usr/bin/env bash
# zsh plugins, starship, mcfly; zsh becomes the login shell. (Config files: see 12-dotfiles.)
source "$(dirname "$0")/../lib/common.sh"

plugins="$VPS_ROOT/dotfiles/zsh_configs/plugins"
git_sync https://github.com/zsh-users/zsh-autosuggestions.git      "$plugins/zsh-autosuggestions"
git_sync https://github.com/zsh-users/zsh-syntax-highlighting.git  "$plugins/zsh-syntax-highlighting"

# mcfly refuses to start without a history file.
touch "$HOME/.zsh_history"

mkdir -p "$HOME/.local/bin"
if ! have starship; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null
  ok "installed starship"
fi
if ! have mcfly; then
  curl -fsSL https://raw.githubusercontent.com/cantino/mcfly/master/ci/install.sh \
    | sh -s -- --git cantino/mcfly --to "$HOME/.local/bin" >/dev/null 2>&1 \
    && ok "installed mcfly" || warn "mcfly install failed (optional)"
fi

zsh_path="$(command -v zsh)"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
  as_root chsh -s "$zsh_path" "$USER" && ok "login shell is now zsh (next login)"
fi
