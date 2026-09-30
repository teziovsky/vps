# slugify — rename files and directories to URL-safe slugs
function _slugify_usage() {
  echo "Usage: slugify [-r] [-i] [-n] [-c] [-s SEPARATOR] [path...]"
  echo ""
  echo "Slugify file and directory names. Default separator is '_'."
  echo "Multiple separators in a row are collapsed to one."
  echo "Short options can be grouped (e.g. slugify -ri)."
  echo "By default, letter case is kept; already-valid names like Something_etc are left alone."
  echo ""
  echo "  -s, --separator CHAR     Separator used in slugs (default: _)"
  echo "  -r, --recursive          Recurse into directories"
  echo "  -i, --interactive        Confirm each rename (y/n/a/q)"
  echo "  -n, --dry-run            Show renames without applying them"
  echo "  -c, --case-sensitive     Lowercase slugs (Something_etc -> something_etc)"
  echo "  -h, --help               Show this help"
}

function _slugify_translit() {
  local s="$1"
  local i
  local -a from to
  from=(ą ć ę ł ń ó ś ź ż Ą Ć Ę Ł Ń Ó Ś Ź Ż)
  to=(a c e l n o s z z A C E L N O S Z Z)
  for i in {1..${#from}}; do
    s="${s//${from[i]}/${to[i]}}"
  done
  print -r -- "$s"
}

function _slugify_stem() {
  local s="$1"
  local separator="$2"
  local case_sensitive="$3"

  s="$(_slugify_translit "$s")"

  if (( case_sensitive )); then
    s="${(L)s}"
    s="${s//[^a-z0-9]/$separator}"
  else
    s="${s//[^a-zA-Z0-9]/$separator}"
  fi

  while [[ -n "$separator" && "$s" == *"${separator}${separator}"* ]]; do
    s="${s//${separator}${separator}/$separator}"
  done

  while [[ -n "$separator" && "$s" == "${separator}"* ]]; do
    s="${s#$separator}"
  done
  while [[ -n "$separator" && "$s" == *"${separator}" ]]; do
    s="${s%$separator}"
  done

  print -r -- "$s"
}

function _slugify_basename() {
  local base="$1"
  local separator="$2"
  local case_sensitive="$3"
  local prefix="" stem ext=""

  if [[ "$base" == .* && "$base" != . && "$base" != .. ]]; then
    prefix="."
    base="${base#.}"
  fi

  if [[ "$base" == *.* ]]; then
    stem="${base%.*}"
    if (( case_sensitive )); then
      ext=".${(L)base##*.}"
    else
      ext=".${base##*.}"
    fi
  else
    stem="$base"
  fi

  local slugged
  slugged="$(_slugify_stem "$stem" "$separator" "$case_sensitive")"
  [[ -n "$slugged" ]] || return 1
  print -r -- "${prefix}${slugged}${ext}"
}

function _slugify_is_numbers_bundle() {
  [[ "${1:t:l}" == *.numbers ]]
}

function _slugify_collect() {
  emulate -L zsh
  setopt localoptions extendedglob nullglob

  local root="$1"
  local recursive="$2"
  local -a collected keyed
  local item depth

  if [[ -f "$root" ]] || _slugify_is_numbers_bundle "$root"; then
    print -r -- "$root"
    return 0
  fi

  if (( recursive )); then
    collected=("$root"/**/*(N))
  else
    collected=("$root"/*(N))
  fi

  if [[ "$root" != . && "$root" != / ]]; then
    collected+=("$root")
  fi

  for item in "${collected[@]}"; do
    if (( ${${item:l}[(Ie).numbers/]} )); then
      continue
    fi
    depth="${item//[^\/]}"
    keyed+=("${(l:4::0:)${#depth}}"$'\t'"$item")
  done

  local -a ordered
  ordered=("${(@O)keyed}")
  for item in "${ordered[@]}"; do
    print -r -- "${item#*$'\t'}"
  done
}

function slugify() {
  emulate -L zsh
  setopt localoptions extendedglob

  local sep='_'
  local interactive=0 recursive=0 dry_run=0 case_sensitive=0 apply_all=0
  local -a paths
  local green="\033[0;32m"
  local yellow="\033[0;33m"
  local red="\033[0;31m"
  local no_color="\033[0m"
  local opts opt

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --separator)
        if [[ $# -lt 2 ]]; then
          echo -e "${red}slugify: missing separator${no_color}" >&2
          return 1
        fi
        sep="$2"
        shift 2
        ;;
      --separator=*)
        sep="${1#*=}"
        shift
        ;;
      --interactive)
        interactive=1
        shift
        ;;
      --recursive)
        recursive=1
        shift
        ;;
      --dry-run)
        dry_run=1
        shift
        ;;
      --case-sensitive)
        case_sensitive=1
        shift
        ;;
      --help)
        _slugify_usage
        return 0
        ;;
      --)
        shift
        paths+=("$@")
        break
        ;;
      -*)
        opts="${1#-}"
        shift
        if [[ -z "$opts" ]]; then
          echo -e "${red}slugify: unknown option: -${no_color}" >&2
          _slugify_usage >&2
          return 1
        fi
        while [[ -n "$opts" ]]; do
          opt="${opts[1]}"
          opts="${opts[2,-1]}"
          case "$opt" in
            s)
              if [[ -n "$opts" ]]; then
                sep="$opts"
                opts=""
              elif [[ $# -gt 0 ]]; then
                sep="$1"
                shift
              else
                echo -e "${red}slugify: missing separator${no_color}" >&2
                return 1
              fi
              ;;
            i)
              interactive=1
              ;;
            r)
              recursive=1
              ;;
            n)
              dry_run=1
              ;;
            c)
              case_sensitive=1
              ;;
            h)
              _slugify_usage
              return 0
              ;;
            *)
              echo -e "${red}slugify: unknown option: -${opt}${no_color}" >&2
              _slugify_usage >&2
              return 1
              ;;
          esac
        done
        ;;
      *)
        paths+=("$1")
        shift
        ;;
    esac
  done

  if [[ -z "$sep" ]]; then
    echo -e "${red}slugify: separator cannot be empty${no_color}" >&2
    return 1
  fi

  if (( ${#paths} == 0 )); then
    paths=(".")
  fi

  local -a targets
  local path item dest dir base new_base answer tmp
  local renamed=0 skipped=0 conflicts=0

  for path in "${paths[@]}"; do
    if [[ ! -e "$path" ]]; then
      echo -e "${red}slugify: no such file or directory: $path${no_color}" >&2
      return 1
    fi

    while IFS= read -r item; do
      targets+=("$item")
    done < <(_slugify_collect "$path" "$recursive")
  done

  for item in "${targets[@]}"; do
    base="${item:t}"
    dir="${item:h}"

    if [[ "$base" == .* ]]; then
      continue
    fi

    new_base="$(_slugify_basename "$base" "$sep" "$case_sensitive")" || {
      echo -e "${yellow}skip (empty slug): ${item}${no_color}"
      ((skipped++))
      continue
    }

    dest="${dir}/${new_base}"

    if [[ "$item" == "$dest" ]]; then
      continue
    fi

    if [[ -e "$dest" && ! ( "$item" -ef "$dest" ) ]]; then
      echo -e "${red}skip (exists): ${item} -> ${dest}${no_color}"
      ((conflicts++))
      continue
    fi

    if (( interactive && ! apply_all && ! dry_run )); then
      echo -ne "${yellow}Rename '${item}' -> '${dest}'? [y/n/a/q] ${no_color}"
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
      ((renamed++))
      continue
    fi

    if [[ -e "$dest" && "$item" -ef "$dest" ]]; then
      tmp="${dir}/.slugify.${$}.${RANDOM}"
      if /bin/mv -- "$item" "$tmp" && /bin/mv -- "$tmp" "$dest"; then
        echo -e "${green}${item} -> ${dest}${no_color}"
        ((renamed++))
      else
        echo -e "${red}failed: ${item} -> ${dest}${no_color}" >&2
        return 1
      fi
    elif /bin/mv -- "$item" "$dest"; then
      echo -e "${green}${item} -> ${dest}${no_color}"
      ((renamed++))
    else
      echo -e "${red}failed: ${item} -> ${dest}${no_color}" >&2
      return 1
    fi
  done

  echo -e "${green}Renamed: ${renamed}${no_color}  ${yellow}Skipped: ${skipped}${no_color}  ${red}Conflicts: ${conflicts}${no_color}"
}

function _slugify() {
  _arguments \
    '(-s --separator)'{-s,--separator}'[separator used in slugs]:separator:' \
    '(-r --recursive)'{-r,--recursive}'[recurse into directories]' \
    '(-i --interactive)'{-i,--interactive}'[confirm each rename]' \
    '(-n --dry-run)'{-n,--dry-run}'[show renames without applying them]' \
    '(-c --case-sensitive)'{-c,--case-sensitive}'[lowercase slugs]' \
    '(-h --help)'{-h,--help}'[show help]' \
    '*:path:_files'
}

compdef _slugify slugify 2>/dev/null
