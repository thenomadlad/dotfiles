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

To try config changes without touching your session, use the test VM: `just vm-test`
(see `vm/README.md`).
