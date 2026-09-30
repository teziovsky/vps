fpath=(/opt/homebrew/completions/zsh $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Official completions for docker / composer / npm (not kubectl)
autoload -U +X bashcompinit && bashcompinit

_load_cli_completion() {
  local cmd="$1" gen="$2"
  (( $+commands[$cmd] )) || return
  (( $+functions[_$cmd] )) && return
  local script
  script="$(eval "$gen" 2>/dev/null)" || return
  [[ -n "$script" ]] && source /dev/stdin <<<"$script"
}

_load_cli_completion docker 'docker completion zsh'
_load_cli_completion composer 'composer completion zsh'
_load_cli_completion npm 'npm completion'

unfunction _load_cli_completion
