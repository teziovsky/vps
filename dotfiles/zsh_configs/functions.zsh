# GREP
function findtext() {
  rg -H --no-heading --color=always -i --files-with-matches --hidden "$@"
}

# DOCKER
function drm() {
  for container in "$@"; do
    docker stop "$container"
    docker rm "$container"
  done
}

# GIT
function deep_check_branches() {
  fd -t d -H -I -L ".git$" . --exec sh -c '
        cd "{}" &&
        repo=$(basename "$(dirname "$(pwd)")") &&
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) &&
        [ "$branch" != "develop" ] &&
        [ "$branch" != "udev" ] &&
        echo "Repo: $repo is actually on branch $branch"
    ' \;
}

