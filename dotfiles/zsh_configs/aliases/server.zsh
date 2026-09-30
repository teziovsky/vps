if (( $+commands[systemctl] )); then
  alias sc="sudo systemctl"
  alias scu="systemctl --user"
  alias jc='journalctl -u'
  alias jcf='journalctl -fu'
  alias failed="systemctl --failed"
  alias ports="sudo ss -tulpn"
  alias mem="free -h"
  alias disk="df -h /"
  alias duh="du -h --max-depth=1 | sort -rh | head -20"
  alias ufws="sudo ufw status verbose"
  alias f2b="sudo fail2ban-client status sshd"
  alias audit="vps audit"
fi
