#!/usr/bin/env bash
source "$(dirname "$0")/../lib/common.sh"

if [[ -x "$HOME/.bun/bin/bun" ]]; then
  ok "bun $("$HOME/.bun/bin/bun" --version)"
else
  curl -fsSL https://bun.sh/install | bash >/dev/null
  ok "installed bun $("$HOME/.bun/bin/bun" --version)"
fi
