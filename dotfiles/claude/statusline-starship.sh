#!/usr/bin/env bash
# Claude Code status line rendered by starship, plus Claude info in starship style.
input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
ctx=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
five=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
week=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
five_reset=$(jq -r '.rate_limits.five_hour.resets_at // empty' <<<"$input")
week_reset=$(jq -r '.rate_limits.seven_day.resets_at // empty' <<<"$input")

# Starship's own prompt for this directory; path + branch only (see starship-statusline.toml).
line=$(cd "${dir:-$PWD}" 2>/dev/null && STARSHIP_SHELL= STARSHIP_CONFIG="$HOME/.claude/starship-statusline.toml" starship prompt --terminal-width "${COLUMNS:-120}" 2>/dev/null |
  awk 'NF && !/❯/ { sub(/ *\033\[0m[ \t]*$/, "\033[0m"); sub(/[ \t]+$/, ""); print; exit }')

bold() { printf '\033[1;%sm%s\033[0m' "$1" "$2"; }

# Time until an epoch-seconds reset: 2h13m, 45m, 3d4h. Empty when unknown or already past.
until_reset() {
  local s=$(( $1 - $(date +%s) )) d h m
  [ "$s" -gt 0 ] 2>/dev/null || return 0
  d=$((s / 86400)); h=$((s % 86400 / 3600)); m=$((s % 3600 / 60))
  if [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"; fi
}

# Bright label + remaining percentage colored by level: green >50, yellow >20, red otherwise.
# Optional $3: epoch reset time, shown dimmed as "(2h13m)".
meter() {
  local label=$1 left color eta=""
  [ -n "${3:-}" ] && eta=$(until_reset "$3")
  left=$(( 100 - $(printf '%.0f' "$2") )); [ "$left" -lt 0 ] && left=0
  color=31; [ "$left" -gt 20 ] && color=33; [ "$left" -gt 50 ] && color=32
  printf '\033[1;37m%s\033[0m \033[1;%sm%d%%\033[0m' "$label" "$color" "$left"
  [ -n "$eta" ] && printf ' \033[38;5;248m(%s)\033[0m' "$eta"
  return 0
}

# Agent section in starship style: plain connector words between colored segments,
# e.g. "✳ Opus 5.5 with ctx 57%, 5h 23% (2h13m), 7d 86% (3d4h)".
usage=()
[ -n "$ctx" ] && usage+=("$(meter ctx "$ctx")")
[ -n "$five" ] && usage+=("$(meter 5h "$five" "$five_reset")")
[ -n "$week" ] && usage+=("$(meter 7d "$week" "$week_reset")")

agent=""
[ -n "$model" ] && agent="$(bold 33 "✳ $model")"
if [ ${#usage[@]} -gt 0 ]; then
  printf -v joined "%s, " "${usage[@]}"
  agent+="${agent:+ with }${joined%, }"
fi

out="$line"
[ -n "$out" ] && [ -n "$agent" ] && out+=" │ "
out+="$agent"

printf '%s' "$out"
