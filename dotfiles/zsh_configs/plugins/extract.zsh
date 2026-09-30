# Extract any common archive. Usage: extract [-r] [-t dir] file ...
alias x=extract

extract() {
  setopt localoptions noautopushd

  if (( $# == 0 )); then
    cat >&2 <<'EOF'
Usage: extract [-option] [file ...]

Options:
  -r, --remove         Remove archive after unpacking.
  -t, --to-directory   Extract into this directory.
EOF
    return 1
  fi

  local remove_archive=1
  local target_directory=""

  while (( $# > 0 )); do
    case "$1" in
      -r|--remove) remove_archive=0; shift ;;
      -t|--to-directory)
        shift
        [[ -d "$1" ]] || { echo "extract: '$1' is not a directory" >&2; return 1; }
        target_directory="${1%/}"
        shift
        ;;
      *) break ;;
    esac
  done

  local pwd="$PWD"
  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" >&2
      shift
      continue
    fi

    local success=0
    local file="$1" full_path="${1:A}"
    local extract_dir="${1:t:r}"
    [[ $extract_dir =~ '\.tar$' ]] && extract_dir="${extract_dir:r}"
    [[ -n "$target_directory" ]] && extract_dir="$target_directory/${extract_dir:t}"

    if [[ -e "$extract_dir" ]]; then
      local rnd="${(L)"${$(( [##36]$RANDOM*$RANDOM ))}":1:5}"
      extract_dir="${extract_dir}-${rnd}"
    fi

    command mkdir -p "$extract_dir"
    builtin cd -q "$extract_dir"
    echo "extract: extracting to $extract_dir" >&2

    case "${file:l}" in
      (*.tar.gz|*.tgz) tar zxvf "$full_path" ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$full_path" ;;
      (*.tar.xz|*.txz) tar --xz -xvf "$full_path" ;;
      (*.tar.zst|*.tzst) tar --zstd -xvf "$full_path" ;;
      (*.tar) tar xvf "$full_path" ;;
      (*.gz) gunzip -ck "$full_path" > "${file:t:r}" ;;
      (*.bz2) bunzip2 -ck "$full_path" > "${file:t:r}" ;;
      (*.xz) xzcat "$full_path" > "${file:t:r}" ;;
      (*.zip|*.war|*.jar|*.ear|*.ipa|*.apk|*.whl) unzip "$full_path" ;;
      (*.rar)
        if (( $+commands[unrar] )); then unrar x -ad "$full_path"
        elif (( $+commands[unar] )); then unar -o . "$full_path"
        else echo "extract: install unrar or unar" >&2; success=1; fi
        ;;
      (*.7z) 7za x "$full_path" ;;
      (*.zst) unzstd --stdout "$full_path" > "${file:t:r}" ;;
      (*) echo "extract: '$file' cannot be extracted" >&2; success=1 ;;
    esac

    (( success = success > 0 ? success : $? ))
    (( success == 0 && remove_archive == 0 )) && command rm "$full_path"
    shift
    builtin cd -q "$pwd"
  done
}
