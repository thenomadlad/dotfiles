# My dotfiles

This directory contains the dotfiles for my system. Currently geared towards macs

## Requirements

Ensure you have the following installed on your system

### Stow and just

```
pacman -S stow just
```

## Installation

First, check out the dotfiles repo in your $HOME directory using git

```
$ git clone git@github.com/thenomadlad/dotfiles
$ cd dotfiles
```

then use GNU stow (via `just`) to create symlinks

```
$ just stow-plan     # preview the links
$ just stow          # create them; fails without changes if a real file is in the way
$ just stow-adopt    # or: take over existing files in $HOME into the repo, then review with git
```

`just unstow` removes the links. Run `just` to see the other recipes.

## Hyprland (optional session)

Hyprland runs side by side with GNOME. Install it and its helpers:

```
pacman -S --needed hyprland hyprlauncher hyprshutdown xdg-desktop-portal-hyprland \
  waybar mako hyprlock hypridle hyprpolkitagent playerctl qt6-wayland
```

Run `just stow`, log out, and pick **Hyprland** from the gear icon on the GDM login screen.
The config is `.config/hypr/hyprland.lua` (Lua, Hyprland 0.56+). It's the upstream
example with small edits; see them with `diff /usr/share/hypr/hyprland.lua ~/.config/hypr/hyprland.lua`.

If Hyprland misbehaves, pick GNOME at GDM instead. If the session hangs, switch to a TTY
with Ctrl+Alt+F3.

### Remote desktop (wayvnc over Tailscale)

`pacman -S wayvnc`, then `just stow` and `systemctl --user daemon-reload`. Hyprland starts
`wayvnc.service`, which serves the desktop on this machine's Tailscale IP (port 5900) only, and
retries until Tailscale is up. From another tailnet device, connect to `<tailscale-ip>` with
TigerVNC (macOS: `brew install --cask tigervnc-viewer`). macOS Screen Sharing can't do wayvnc's
RSA-AES login.

The VNC login is your Linux username and password (PAM, `.config/wayvnc/config`).

#### Headless server

wayvnc needs a running Hyprland, and Hyprland needs a seat, which a plain user unit doesn't have.
`just headless-on` installs `system/hyprland-headless.service`, which replaces GDM: every boot goes
straight into a Hyprland session on tty1, no login and no monitor needed. With no monitor plugged
in, Hyprland adds a virtual `REMOTE` output for wayvnc. Then `sudo reboot now`, and from elsewhere:

1. TigerVNC to `<tailscale-ip>` (wayvnc retries until Tailscale is up, so give it a few seconds).
2. Log in to VNC, then unlock hyprlock, both with your Linux password. The session always starts
   locked, in case a monitor gets plugged in.

Exiting Hyprland (SUPER+M) starts a fresh session after 5 s. SSH still works if Hyprland doesn't;
check `journalctl -b -u hyprland-headless`. GNOME isn't reachable while this is on;
`just headless-off` and reboot brings GDM back. No password at boot means gnome-keyring stays locked.

To try config changes without touching your session, use the test VM: `just vm-test`
(see `vm/README.md`).
