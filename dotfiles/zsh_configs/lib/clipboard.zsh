# clipcopy / clippaste — same names as Oh My Zsh
function clipcopy() {
  local input="${1:-/dev/stdin}"
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && (( $+commands[wl-copy] )); then
    cat "$input" | wl-copy
  elif (( $+commands[pbcopy] )); then
    cat "$input" | pbcopy
  elif (( $+commands[xclip] )); then
    cat "$input" | xclip -selection clipboard
  elif (( $+commands[xsel] )); then
    cat "$input" | xsel --clipboard --input
  else
    echo "clipcopy: install pbcopy, wl-copy, xclip, or xsel" >&2
    return 1
  fi
}

function clippaste() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]] && (( $+commands[wl-paste] )); then
    wl-paste --no-newline
  elif (( $+commands[pbpaste] )); then
    pbpaste
  elif (( $+commands[xclip] )); then
    xclip -selection clipboard -out
  elif (( $+commands[xsel] )); then
    xsel --clipboard --output
  else
    echo "clippaste: install pbpaste, wl-paste, xclip, or xsel" >&2
    return 1
  fi
}
