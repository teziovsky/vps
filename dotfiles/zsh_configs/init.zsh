# PLUGINS
[ -f "$ZSH_CONFIG/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "$ZSH_CONFIG/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$ZSH_CONFIG/plugins/extract.zsh"
source "$ZSH_CONFIG/plugins/sudo.zsh"
source "$ZSH_CONFIG/plugins/colored-man-pages.zsh"

# FZF (fzf >= 0.48 has `fzf --zsh`; older packages ship ~/.fzf.zsh)
if (( $+commands[fzf] )); then
  source <(fzf --zsh 2>/dev/null) 2>/dev/null || { [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh; }
fi

for file in "$ZSH_CONFIG"/{exports,completions}.zsh; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done

for file in "$ZSH_CONFIG"/lib/**/*.zsh(N.); do
  [ -r "$file" ] && source "$file"
done

for file in "$ZSH_CONFIG"/{functions,history}.zsh; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file"
done

for file in "$ZSH_CONFIG"/aliases/**/*.zsh(N.); do
  [ -r "$file" ] && source "$file"
done
unset file

# BUN COMPLETIONS
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# MCFLY
if command -v mcfly &>/dev/null; then
  eval "$(mcfly init zsh)"
fi

if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be sourced last, after everything that binds widgets.
[ -f "$ZSH_CONFIG/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "$ZSH_CONFIG/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# Per-machine overrides that are not synced (aliases, secrets, PATH tweaks).
[ -r "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
