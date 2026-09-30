# This is a VPS

You are running on a remote server managed by the `vps` repo (`~/vps`). Treat it as production.

- **Do not lock yourself out.** Never change sshd or ufw rules without confirming first. Before any sshd change run `sudo sshd -t`, and keep the current session open while testing a new login in another one. SSH is key-only and root login is off.
- **Docker bypasses ufw.** A published port (`-p 8080:80`) is open to the world. Bind to `127.0.0.1` or go through the reverse proxy.
- **Configuration lives in `~/vps`.** Dotfiles under `~` are symlinks into that repo; edit the repo file, not a copy. Change system setup through a module in `~/vps/modules/` and `vps apply <module>` rather than by hand, so it survives a rebuild.
- **Useful commands:** `vps audit` (health and security), `vps update`, `vps apply [module]`, `systemctl --failed`, `journalctl -u <unit> -e`, `docker ps`, `lazydocker`.
- **Destructive actions need an explicit go-ahead:** deleting data or volumes, `docker rm`/`down`, stopping services, reboots, removing packages, force pushes.
- **Never print or commit secrets.** `.env` files, keys and `~/.config/vps/local.env` are off limits. Per-server values belong in `~/.config/vps/`, not in the repo (it is public).
- **Small box:** check `df -h /`, `free -h` and `docker system df` before pulling big images or builds.
