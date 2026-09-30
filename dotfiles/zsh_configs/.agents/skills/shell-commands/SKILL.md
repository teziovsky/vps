---
name: shell-commands
description: Decides whether a new zsh command belongs as an alias, a functions.zsh helper, or a lib package. Use when adding or refactoring aliases, functions, slugify-like tools, or any user-facing shell command in this repo.
---

# Shell commands

Pick the smallest home that fits. Do not promote a one-liner into a package.

## Decision

1. **Alias** — single command or a short pipe, no branching, no flags of its own.
   - File: `aliases/<topic>.zsh` (extend an existing topic file when one fits).
   - Keep aliases grouped by tool: git, docker, brew, npm, github, db, ai, shell, general.

2. **Function in `functions.zsh`** — a few branches or args, still one job, no private helpers.
   - Add it under a `# TOPIC` comment matching nearby sections (`# GIT`, `# DOCKER`, `# POSTGRES`).
   - Print a usage line and `return 1` when argc is wrong.

3. **Lib package** — options, helpers, completions, or it outgrew an alias.
   - File: `lib/<name>.zsh`.
   - Public command name = filename when possible (`slugify` → `lib/slugify.zsh`).
   - Prefix private helpers with `_<name>_`.
   - If an alias file becomes a package, move it to `lib/` and delete the alias file.

## Do not

- Put multi-flag tools in `aliases/`.
- Duplicate the same command as both an alias and a function.
- Add wrapper aliases for a new command unless the user asks (old names are not kept by default).
- Reach for `find`/`xargs` when zsh globs or an existing tool in the config (`fd`, `rg`, `eza`) already covers it.

## After adding

The command is available after `source ~/.zshrc` (alias `sz`). Mention that if the user needs it in the current session.
