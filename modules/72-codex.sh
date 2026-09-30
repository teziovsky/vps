#!/usr/bin/env bash
# OpenAI Codex CLI: the static release binary (no Node needed). Also used by `vps update`.
source "$(dirname "$0")/../lib/common.sh"

target="$(arch_name)-unknown-linux-musl"
dest="$HOME/.local/bin/codex"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://github.com/openai/codex/releases/latest/download/codex-$target.tar.gz" -o "$tmp/codex.tgz"
tar -xzf "$tmp/codex.tgz" -C "$tmp"
mkdir -p "$HOME/.local/bin"
install -m 755 "$tmp/codex-$target" "$dest"
ok "codex $("$dest" --version 2>/dev/null | head -1)"

[[ -f "$HOME/.codex/auth.json" ]] || warn "not logged in yet: run 'codex login' (use --device-auth on a headless box)"
