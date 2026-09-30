# vps

One repo that turns a fresh Debian/Ubuntu VPS into *your* server: shell, git, ssh, Claude, Codex, bun, Docker, the `apps` CLI — plus the hardening and update routine a production box needs. The same repo manages every server; `hosts/<name>.env` says which parts each one gets.

## New server

As root on the fresh VPS (the repo must be reachable over https; it holds no secrets):

```bash
curl -fsSL https://raw.githubusercontent.com/teziovsky/vps/main/bootstrap.sh | VPS_USER=<login> bash
```

This creates the login user with root's SSH keys, clones the repo to `~/vps`, and runs `vps apply` as that user. Afterwards:

1. Add the printed public key (`~/.ssh/id_ed25519_github.pub`) to GitHub, then `vps apply apps` if the profile has apps.
2. **Open a second terminal and log in as the new user before closing the root session** — sshd is now key-only and root login is off.
3. `claude` and `codex login` once each (interactive).

Existing machine: `git clone git@github.com:teziovsky/vps.git ~/vps && ~/vps/vps apply`. Your current `~/.zshrc`, `~/.zsh_configs`, `~/.vimrc`, `~/.gitconfig` are moved to `~/.vps-backup/<timestamp>/` and replaced by symlinks into this repo.

## Daily use

```bash
vps audit            # security + health check, exit 1 on failure (sshd, ufw, fail2ban, updates, disk, units, containers)
vps update           # apt upgrade, bun/claude/codex/plugins, git pull this repo, re-apply
vps apply [module…]  # re-run everything, or only some modules; safe to repeat
vps list             # which modules the profile enables
vps profile <name>   # switch this machine's profile
```

Change a dotfile in `~/vps`, commit, push; on the other servers `vps update` picks it up (they are symlinks).

## Modules (`modules/NN-name.sh`, run in order)

| Module | What it does |
| --- | --- |
| `base` | packages (zsh, git, curl, rg, fzf, eza, bat, delta…), timezone, locale, time sync, optional swap |
| `dotfiles` | symlinks `~/.zshrc`, `~/.zsh_configs`, `~/.vimrc`, `~/.gitconfig`, `~/.ssh/config`, `~/.claude/settings.json` and the Claude status line into this repo (edit the live file = edit the repo) |
| `ssh-client` | a per-server GitHub key, your public keys (from `AUTHORIZED_KEYS_URL`) in `authorized_keys` |
| `ssh-harden` | key-only login, no root, `AllowUsers`; refuses to run if the user has no key; validates with `sshd -t` |
| `firewall` | ufw: deny in, allow out, SSH rate-limited, profile's ports |
| `fail2ban` | sshd jail via the systemd journal |
| `auto-updates` | unattended security upgrades, needrestart, optional timed reboot |
| `sysctl` | network/kernel hardening (leaves `ip_forward` for Docker) |
| `shell` | zsh plugins, starship, mcfly, login shell → zsh |
| `git` | falls back to plain `less` if delta is missing) |
| `bun` / `claude` / `codex` | the CLIs; Codex uses the static release binary, no Node needed |
| `docker` | Docker Engine, log rotation, docker group, lazydocker, weekly `docker system prune` timer (never volumes; `DOCKER_PRUNE=false` to skip) |
| `apps` | clones the repo in `APPS_REPO` (if set) and installs its `apps` CLI |

A failing module does not stop the run; `vps apply` lists what failed and how to retry.

## Profiles

`hosts/default.env` holds generic defaults. Server-specific profiles are **not** kept in this public repo: put them in `~/.config/vps/hosts/<name>.env` (picked by `VPS_PROFILE`, then `~/.config/vps/profile`, then the hostname) and machine-only values in `~/.config/vps/local.env`. On a fresh server pass a one-off module list with `VPS_MODULES="…"`. Per-machine shell tweaks go in `~/.zshrc.local`, git tweaks in `~/.gitconfig.local`.

## Things to know

- **Docker bypasses ufw.** A published port (`-p 8080:80`) is open to the world no matter what `ufw status` says. Bind to `127.0.0.1` or go through the reverse proxy.
- **Backup monitoring:** set `BACKUP_PATH` (and `BACKUP_MAX_AGE_HOURS`, default 26) in your profile; `vps audit` fails if the newest file there is too old.
- **Claude on the server** gets `~/.claude/CLAUDE.md` (server rules) and deny/ask permissions for destructive commands from `dotfiles/claude/`.
- **Security updates are automatic, reboots are not** (`AUTO_REBOOT=false`). `vps audit` warns when a reboot is pending.
- **Nothing secret lives here.** SSH private keys, Claude/Codex logins and `.env` files stay on each server; `apps backup` covers app state.
- `AUTHORIZED_KEYS_URL` trusts every key on that GitHub account. Remove old keys from GitHub when you retire a device (and from `~/.ssh/authorized_keys`, which this repo only appends to).
