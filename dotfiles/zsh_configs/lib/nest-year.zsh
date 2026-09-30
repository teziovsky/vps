# nest-year — move files into created-year subfolders
function _nest_year_usage() {
  echo "Usage: nest-year [-r] [-i] [-n] [path...]"
  echo ""
  echo "Move files into YYYY subfolders based on created (birth) year."
  echo "Creates the year folder when it is missing; otherwise moves into it."
  echo ""
  echo "  -r, --recursive        Recurse into directories"
  echo "  -i, --interactive      Confirm each move (y/n/a/q)"
  echo "  -n, --dry-run          Show moves without applying them"
  echo "  -h, --help             Show this help"
}

function _nest_year_of() {
  local file="$1"
  local year="" birth=""

  year="$(/usr/bin/stat -f '%SB' -t '%Y' "$file" 2>/dev/null)"
  if [[ "$year" != [0-9][0-9][0-9][0-9] ]]; then
    year="$(/usr/bin/stat -f '%Sm' -t '%Y' "$file" 2>/dev/null)"
  fi

  if [[ "$year" != [0-9][0-9][0-9][0-9] ]]; then
    birth="$(stat -c '%W' "$file" 2>/dev/null)"
    if [[ "$birth" == [1-9]* ]]; then
      year="$(date -d "@${birth}" +%Y 2>/dev/null)"
    fi
  fi

  if [[ "$year" != [0-9][0-9][0-9][0-9] ]]; then
    birth="$(stat -c '%Y' "$file" 2>/dev/null)"
    if [[ "$birth" == [1-9]* ]]; then
      year="$(date -d "@${birth}" +%Y 2>/dev/null)"
    fi
  fi

  [[ "$year" == [0-9][0-9][0-9][0-9] ]] || return 1
  print -r -- "$year"
}

function _nest_year_collect() {
  emulate -L zsh
  setopt localoptions extendedglob nullglob

  local root="$1"
  local recursive="$2"
  local -a collected
  local item

  if [[ -f "$root" ]]; then
    print -r -- "$root"
    return 0
  fi

  if (( recursive )); then
    collected=("$root"/**/*(N.))
  else
    collected=("$root"/*(N.))
  fi

  for item in "${collected[@]}"; do
    print -r -- "$item"
  done
}

function nest-year() {
  emulate -L zsh
  setopt localoptions extendedglob

  local interactive=0 recursive=0 dry_run=0 apply_all=0
  local -a paths
  local green="\033[0;32m"
  local yellow="\033[0;33m"
  local red="\033[0;31m"
  local no_color="\033[0m"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--interactive)
        interactive=1
        shift
        ;;
      -r|--recursive)
        recursive=1
        shift
        ;;
      -n|--dry-run)
        dry_run=1
        shift
        ;;
      -h|--help)
        _nest_year_usage
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        echo -e "${red}nest-year: unknown option: $1${no_color}" >&2
        _nest_year_usage >&2
        return 1
        ;;
      *)
        paths+=("$1")
        shift
        ;;
    esac
  done

  if (( ${#paths} == 0 )); then
    paths=(".")
  fi

  local -a targets
  local path item dest dir base year year_dir answer
  local moved=0 skipped=0 conflicts=0

  for path in "${paths[@]}"; do
    if [[ ! -e "$path" ]]; then
      echo -e "${red}nest-year: no such file or directory: $path${no_color}" >&2
      return 1
    fi

    while IFS= read -r item; do
      targets+=("$item")
    done < <(_nest_year_collect "$path" "$recursive")
  done

  for item in "${targets[@]}"; do
    [[ -f "$item" ]] || continue

    base="${item:t}"
    dir="${item:h}"

    if [[ "$base" == .* ]]; then
      continue
    fi

    year="$(_nest_year_of "$item")" || {
      echo -e "${yellow}skip (no year): ${item}${no_color}"
      ((skipped++))
      continue
    }

    if [[ "${dir:t}" == "$year" ]]; then
      continue
    fi

    year_dir="${dir}/${year}"
    dest="${year_dir}/${base}"

    if [[ -e "$year_dir" && ! -d "$year_dir" ]]; then
      echo -e "${red}skip (exists): ${item} -> ${dest}${no_color}"
      ((conflicts++))
      continue
    fi

    if [[ -e "$dest" ]]; then
      echo -e "${red}skip (exists): ${item} -> ${dest}${no_color}"
      ((conflicts++))
      continue
    fi

    if (( interactive && ! apply_all && ! dry_run )); then
      echo -ne "${yellow}Move '${item}' -> '${dest}'? [y/n/a/q] ${no_color}"
      read -r answer
      case "$answer" in
        y|Y) ;;
        a|A) apply_all=1 ;;
        q|Q)
          echo -e "${yellow}Aborted.${no_color}"
          break
          ;;
        *)
          ((skipped++))
          continue
          ;;
      esac
    fi

    if (( dry_run )); then
      echo -e "${yellow}${item} -> ${dest}${no_color}"
      ((moved++))
      continue
    fi

    if [[ ! -d "$year_dir" ]] && ! /bin/mkdir -p -- "$year_dir"; then
      echo -e "${red}failed: mkdir ${year_dir}${no_color}" >&2
      return 1
    fi

    if /bin/mv -- "$item" "$dest"; then
      echo -e "${green}${item} -> ${dest}${no_color}"
      ((moved++))
    else
      echo -e "${red}failed: ${item} -> ${dest}${no_color}" >&2
      return 1
    fi
  done

  echo -e "${green}Moved: ${moved}${no_color}  ${yellow}Skipped: ${skipped}${no_color}  ${red}Conflicts: ${conflicts}${no_color}"
}

function _nest-year() {
  _arguments \
    '(-r --recursive)'{-r,--recursive}'[recurse into directories]' \
    '(-i --interactive)'{-i,--interactive}'[confirm each move]' \
    '(-n --dry-run)'{-n,--dry-run}'[show moves without applying them]' \
    '(-h --help)'{-h,--help}'[show help]' \
    '*:path:_files'
}

compdef _nest-year nest-year 2>/dev/null
