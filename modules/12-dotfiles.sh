#!/usr/bin/env bash
# Symlink every synced dotfile into $HOME, so editing the live file edits this repo.
# An existing real file is moved to ~/.vps-backup/<timestamp>/ first.
source "$(dirname "$0")/../lib/common.sh"

d="$VPS_ROOT/dotfiles"
install -d -m 700 "$HOME/.ssh"
mkdir -p "$HOME/.claude"

link_file "$d/zshrc"                "$HOME/.zshrc"
link_file "$d/zsh_configs"          "$HOME/.zsh_configs"
link_file "$d/vimrc"                "$HOME/.vimrc"
link_file "$d/gitconfig"            "$HOME/.gitconfig"
link_file "$d/ssh_config"           "$HOME/.ssh/config"
link_file "$d/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$d/claude/statusline-starship.sh"   "$HOME/.claude/statusline-starship.sh"
link_file "$d/claude/starship-statusline.toml" "$HOME/.claude/starship-statusline.toml"
