alias dps="docker ps --format 'table {{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Names}}'"
alias dpsa="docker ps -a --format 'table {{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Names}}'"
alias dkill='docker rm $(docker stop $(docker ps -aq))'
alias recursive-docker-up="find . -type d -name develop -exec bash -c 'cd '{}' && ./docker_up.sh' \;"
alias docker-watch-stats="watch -n 1 'docker stats --no-stream --format \"table {{.Name}}\t{{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\" | sort -k 3 -h -r'"
alias docker-logs-current='docker logs -f $(basename "$PWD")'
alias lzd="lazydocker"
