# Shared helpers for vps modules. Source it; never run it.
set -euo pipefail

VPS_ROOT="${VPS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export VPS_ROOT
USER="${USER:-$(id -un)}"; export USER
export VPS_RUN_TS="${VPS_RUN_TS:-$(date +%Y%m%d-%H%M%S)}"
VPS_STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/vps"

export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

as_root() {
  if ((EUID == 0)); then "$@"; else sudo "$@"; fi
}

# ---- profile ---------------------------------------------------------------
# default.env, then hosts/<profile>.env, then ~/.config/vps/local.env (untracked).
vps_profile_name() {
  if [[ -n "${VPS_PROFILE:-}" ]]; then echo "$VPS_PROFILE"
  elif [[ -f "$VPS_STATE_DIR/profile" ]]; then cat "$VPS_STATE_DIR/profile"
  elif [[ -f "$VPS_STATE_DIR/hosts/$(hostname -s).env" || -f "$VPS_ROOT/hosts/$(hostname -s).env" ]]; then hostname -s
  else echo default
  fi
}

load_profile() {
  VPS_PROFILE="$(vps_profile_name)"
  export VPS_PROFILE
  # shellcheck disable=SC1090
  source "$VPS_ROOT/hosts/default.env"
  if [[ "$VPS_PROFILE" != default ]]; then
    local f="$VPS_STATE_DIR/hosts/$VPS_PROFILE.env"
    [[ -f "$f" ]] || f="$VPS_ROOT/hosts/$VPS_PROFILE.env"
    [[ -f "$f" ]] || die "no profile $VPS_PROFILE (looked in $VPS_STATE_DIR/hosts and hosts/)"
    source "$f"
  fi
  [[ -f "$VPS_STATE_DIR/local.env" ]] && source "$VPS_STATE_DIR/local.env"
  # One-off override from the command line (used by bootstrap.sh on a fresh server).
  [[ -n "${VPS_MODULES:-}" ]] && MODULES="$VPS_MODULES"
  return 0
}

module_enabled() { [[ " $MODULES " == *" $1 "* ]]; }

# ---- packages --------------------------------------------------------------
apt_update_once() {
  [[ -n "${_APT_UPDATED:-}" ]] && return 0
  as_root apt-get update -qq
  _APT_UPDATED=1
}

apt_install() {
  apt_update_once
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends "$@" >/dev/null
}

# Install what the distro has; a package missing on this release is not an error.
apt_install_optional() {
  local pkg
  apt_update_once
  for pkg in "$@"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      apt_install "$pkg" || warn "could not install $pkg"
    else
      warn "package $pkg not available on this release"
    fi
  done
}

# ---- files -----------------------------------------------------------------
# Symlink $2 -> $1. An existing real file/dir is moved to ~/.vps-backup/<ts>/ first.
link_file() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then return 0; fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    local bak="$HOME/.vps-backup/${VPS_RUN_TS:-$(date +%Y%m%d-%H%M%S)}"
    mkdir -p "$bak"
    mv "$dst" "$bak/$(basename "$dst")"
    warn "moved existing $dst to $bak/"
  fi
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
  ok "linked $dst"
}

# write_root_file <dest> <mode>   (content on stdin)
# Returns 0 when the file changed, 1 when it was already identical.
write_root_file() {
  local dest="$1" mode="$2" tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  if [[ -f "$dest" ]] && as_root cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    return 1
  fi
  as_root install -D -o root -g root -m "$mode" "$tmp" "$dest"
  rm -f "$tmp"
  ok "wrote $dest"
}

# Clone or fast-forward a git checkout.
git_sync() {
  local url="$1" dir="$2"
  if [[ -d "$dir/.git" ]]; then
    git -C "$dir" pull --ff-only -q || warn "could not update $dir"
  else
    git clone --depth 1 -q "$url" "$dir"
    ok "cloned $url"
  fi
}

github_ssh_works() {
  local out
  out="$(ssh -o BatchMode=yes -o ConnectTimeout=8 -T git@github.com 2>&1 || true)"
  [[ "$out" == *"successfully authenticated"* ]]
}

arch_name() {
  case "$(uname -m)" in
    x86_64) echo x86_64 ;;
    aarch64|arm64) echo aarch64 ;;
    *) die "unsupported architecture $(uname -m)" ;;
  esac
}

load_profile
