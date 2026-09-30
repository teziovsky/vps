---
name: repo-layout
description: Maps this zsh config repo's load order and file placement. Use when adding, moving, or editing files in ~/.zsh_configs, or when deciding where a change belongs.
---

# Repo layout

Personal zsh config. `$ZSH_CONFIG` points here. `init.zsh` is the only entrypoint.

## Load order

`init.zsh` sources in this order. Later files can depend on earlier ones:

1. `plugins/` (autosuggestions, syntax-highlighting, extract, sudo, colored-man-pages)
2. `~/.fzf.zsh` if present
3. `exports.zsh`, `completions.zsh` (`compinit` happens here)
4. `lib/**/*.zsh`
5. `functions.zsh`, `history.zsh`
6. `aliases/**/*.zsh`
7. Optional tool inits (bun, mcfly, fnm, mole, starship)

Do not add new top-level source loops unless the user asks. Put new files where an existing glob already picks them up.

## Where things go

| Kind | Path | Examples |
|------|------|----------|
| Env / PATH | `exports.zsh` | `EDITOR`, tool prefixes |
| Completions bootstrap | `completions.zsh` | `compinit`, CLI completion loaders |
| History options | `history.zsh` | `HISTFILE`, `setopt hist_*` |
| One-off / small helpers | `functions.zsh` | `tcd`, `drm`, `pgdump` |
| Domain command packages | `lib/<name>.zsh` | `slugify`, clipboard, directories, key-bindings |
| Short aliases by topic | `aliases/<topic>.zsh` | `git.zsh`, `docker.zsh` |
| Vendored / copied plugins | `plugins/` | zsh-autosuggestions |

## Rules

- Do not edit vendored plugin trees (`plugins/zsh-autosuggestions`, `plugins/zsh-syntax-highlighting`) unless the user explicitly asks to vendor-update them.
- `plugins/extract.zsh`, `plugins/sudo.zsh`, and `plugins/colored-man-pages.zsh` are local copies; treat them as owned, but prefer adding new owned code in `lib/` or `functions.zsh`.
- New alias files: `aliases/<topic>.zsh`, lowercase topic, no extra nesting.
- New packages: `lib/<name>.zsh`. `init.zsh` already sources `lib/**/*.zsh`.
- Completions for a lib command live in that same `lib/<name>.zsh` file (`compdef` is safe because `compinit` already ran).
- Do not create a README or extra docs unless asked.
- This is not a git repo by default; do not invent git workflow unless the user initializes one.
