alias c="clear"
alias e="exit"
(( $+commands[batcat] )) && alias cat="batcat --style=plain,header"
(( $+commands[bat] )) && alias cat="bat --style=plain,header"
alias week="date +%V"
alias localip="curl https://ipinfo.io/json"
alias externalip="curl ifconfig.me"
if (( $+commands[eza] )); then
  alias la="eza -lah --group-directories-first"
  alias ll="eza -lh --group-directories-first"
  alias ls="eza -G --group-directories-first"
  alias lsa="eza -lah --group-directories-first"
else
  alias la="ls -lah"
  alias ll="ls -lh"
  alias lsa="ls -lah"
fi
alias fsf='file="$(fd . -t f --full-path "$HOME/" | fzf -i)" && [ -n "$file" ] && vim "$file"'
alias fsd='dir="$(fd . -t d --full-path "$HOME/" | fzf -i)" && [ -n "$dir" ] && cd "$dir"'
alias find-large-files='du -h . | rg "[0-9\,]\+G"'
alias system-update="vps update"
