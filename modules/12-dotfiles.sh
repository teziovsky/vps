#!/usr/bin/env bash
# Symlink every synced dotfile into $HOME, so editing the live file edits this repo.
# An existing real file is moved to ~/.vps-backup/<timestamp>/ first.
source "$(dirname "$0")/../lib/common.sh"

install -d -m 700 "$HOME/.ssh"
mkdir -p "$HOME/.claude"

while read -r src dst; do
  link_file "$src" "$dst"
done < <(dotfile_links)
