#!/usr/bin/env bash
# A repo with an `apps` CLI (APPS_REPO). Needs GitHub SSH access (see ssh-client).
source "$(dirname "$0")/../lib/common.sh"

[[ -n "$APPS_REPO" ]] || { ok "APPS_REPO not set; nothing to do"; exit 0; }

if [[ ! -d "$APPS_DIR/.git" ]]; then
  github_ssh_works || die "GitHub rejects this server's key; add ~/.ssh/id_ed25519_github.pub to GitHub, then: vps apply apps"
  git clone -q "$APPS_REPO" "$APPS_DIR"
  ok "cloned $APPS_REPO"
else
  git -C "$APPS_DIR" pull --ff-only -q || warn "could not fast-forward $APPS_DIR"
fi

have docker && { docker network inspect proxy >/dev/null 2>&1 || docker network create proxy >/dev/null; }

(cd "$APPS_DIR" && ./scripts/install.sh cli)
ok "apps CLI ready. Next: 'apps clone', then restore state ('apps offsite restore state ~/restore && apps restore ~/restore/state')"
