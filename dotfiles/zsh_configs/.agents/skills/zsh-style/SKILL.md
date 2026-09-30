---
name: zsh-style
description: Zsh coding conventions for this personal config. Use when writing or editing .zsh files, functions, aliases, completions, or lib packages in ~/.zsh_configs.
---

# Zsh style

Match existing files. This is interactive shell config, not a product codebase.

## Language

- Write zsh, not bash. Use `[[ ]]`, `local`, `emulate -L zsh` in non-trivial functions.
- Quote every expansion that is a path or user input: `"$path"`, `"$item"`.
- Prefer zsh modifiers (`${file:t}`, `${file:h}`, `${(L)s}`) over `basename`/`dirname`.
- Prefer zsh globs with `(N)` / `nullglob` over `find` for walking the tree.
- Use `setopt localoptions` inside functions so options do not leak.
- Absolute paths for `mv`/`cp` when the function must work even if `PATH` is thin (`/bin/mv`).

## Functions

```zsh
function name() {
  emulate -L zsh
  setopt localoptions extendedglob

  local foo="$1"
  # ...
}
```

- `local` every variable.
- Early `return 1` on bad input; print errors to stderr.
- Reuse the existing ANSI locals when coloring: green / yellow / red / `no_color`.
- Interactive prompts: `read -r` with `y/n/a/q` when a destructive loop needs confirmation.
- Offer `-n` / `--dry-run` on bulk rename or delete helpers.

## Aliases

- One alias per line, `alias name="..."`.
- No `function` in alias files.
- Topic file stays small; if it grows flags and helpers, it is no longer an alias file.

## Completions

- Define `_name` with `_arguments` next to the command.
- `compdef _name name 2>/dev/null` so sourcing the file alone does not fail.
- Do not add new `_load_cli_completion` entries unless the tool ships its own generator.

## Safety

- Skip no-op renames and existing destinations; do not overwrite.
- Do not `eval` user paths.
- Do not change `~/.zshrc` or other dotfiles outside this repo unless asked.
