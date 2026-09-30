#!/usr/bin/env bash
# ~/.ssh: a key for this server, and your public keys in authorized_keys.
source "$(dirname "$0")/../lib/common.sh"

install -d -m 700 "$HOME/.ssh"   # config itself is linked by 12-dotfiles

key="$HOME/.ssh/id_ed25519_github"
if [[ ! -f "$key" ]]; then
  ssh-keygen -q -t ed25519 -N '' -C "$USER@$(hostname -s)" -f "$key"
  ok "generated $key"
fi

if ! github_ssh_works; then
  warn "this server's key is not on GitHub yet. Add it (Settings > SSH keys, or a deploy key):"
  cat "$key.pub"
fi

if [[ -n "${AUTHORIZED_KEYS_URL:-}" ]]; then
  auth="$HOME/.ssh/authorized_keys"
  touch "$auth"; chmod 600 "$auth"
  if keys="$(curl -fsSL --max-time 15 "$AUTHORIZED_KEYS_URL")" && [[ -n "$keys" ]]; then
    added=0
    while IFS= read -r line; do
      [[ "$line" == ssh-* || "$line" == ecdsa-* || "$line" == sk-* ]] || continue
      grep -qxF "$line" "$auth" || { echo "$line" >>"$auth"; added=$((added + 1)); }
    done <<<"$keys"
    ok "authorized_keys: $added new key(s) from $AUTHORIZED_KEYS_URL"
  else
    warn "could not fetch $AUTHORIZED_KEYS_URL"
  fi
fi

# A clone made over https can push once GitHub accepts the key.
if github_ssh_works && [[ "$(git -C "$VPS_ROOT" remote get-url origin 2>/dev/null)" == https://github.com/* ]]; then
  git -C "$VPS_ROOT" remote set-url origin "$(git -C "$VPS_ROOT" remote get-url origin | sed 's|https://github.com/|git@github.com:|')"
  ok "vps repo remote switched to ssh"
fi
