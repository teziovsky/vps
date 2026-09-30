#!/usr/bin/env bash
# Claude Code (native installer -> ~/.local/bin/claude). settings.json: see 12-dotfiles.
source "$(dirname "$0")/../lib/common.sh"

export PATH="$HOME/.local/bin:$PATH"
if have claude; then
  ok "claude $(claude --version 2>/dev/null | head -1)"
else
  curl -fsSL https://claude.ai/install.sh | bash >/dev/null
  ok "installed claude"
fi

[[ -f "$HOME/.claude.json" ]] || warn "not logged in yet: run 'claude' once and sign in"
