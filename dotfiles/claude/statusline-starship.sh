#!/usr/bin/env bash
# Claude Code status line rendered by starship, plus Claude info in starship style.
input=$(cat)

dir=$(jq -r '.workspace.current_dir // .cwd // empty' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
ctx=$(jq -r '.context_window.used_percentage // empty' <<<"$input")
cost=$(jq -r '.cost.total_cost_usd // empty' <<<"$input")
five=$(jq -r '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
week=$(jq -r '.rate_limits.seven_day.used_percentage // empty' <<<"$input")

# Starship's own prompt for this directory; path + branch only (see starship-statusline.toml).
line=$(cd "${dir:-$PWD}" 2>/dev/null && STARSHIP_SHELL= STARSHIP_CONFIG="$HOME/.claude/starship-statusline.toml" starship prompt --terminal-width "${COLUMNS:-120}" 2>/dev/null |
  awk 'NF && !/❯/ { sub(/ *\033\[0m[ \t]*$/, "\033[0m"); sub(/[ \t]+$/, ""); print; exit }')

bold() { printf '\033[1;%sm%s\033[0m' "$1" "$2"; }

# Bright label + remaining percentage colored by level: green >50, yellow >20, red otherwise.
meter() {
  local label=$1 left color
  left=$(( 100 - $(printf '%.0f' "$2") )); [ "$left" -lt 0 ] && left=0
  color=31; [ "$left" -gt 20 ] && color=33; [ "$left" -gt 50 ] && color=32
  printf '\033[1;37m%s\033[0m \033[1;%sm%d%%\033[0m' "$label" "$color" "$left"
}

# Agent section in starship style: plain connector words between colored segments,
# e.g. "✳ Opus 5.5 with ctx 57%, 5h 23%, 7d 86% for $1.23".
usage=()
[ -n "$ctx" ] && usage+=("$(meter ctx "$ctx")")
[ -n "$five" ] && usage+=("$(meter 5h "$five")")
[ -n "$week" ] && usage+=("$(meter 7d "$week")")

agent=""
[ -n "$model" ] && agent="$(bold 33 "✳ $model")"
if [ ${#usage[@]} -gt 0 ]; then
  printf -v joined "%s, " "${usage[@]}"
  agent+="${agent:+ with }${joined%, } left"
fi
[ -n "$cost" ] && agent+="${agent:+ for }$(bold 37 "\$$(printf '%.2f' "$cost")")"

out="$line"
[ -n "$out" ] && [ -n "$agent" ] && out+=" │ "
out+="$agent"

printf '%s' "$out"
