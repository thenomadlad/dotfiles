# Dotfiles test VM

A throwaway Arch VM for trying these dotfiles (Hyprland, etc.) without touching the host.
The repo is shared into the guest read-only over virtiofs, and on boot it's stowed into
`/home/tester`. The guest then autologs in on tty1 and starts Hyprland.

Host needs: `just mkosi qemu-desktop virglrenderer virtiofsd edk2-ovmf socat`, plus
`python-pefile dosfstools mtools systemd-ukify` for mkosi to build a bootable image.

```
just vm-test               # build if needed, boot, check it's running this repo's config
just vm                    # just boot it (vm-resume keeps the last run's disk)
just vm-reload             # after editing config on the host
just vm-shell              # root shell over serial (Ctrl+] to leave)
just vm-exec 'journalctl -b -p warning'
just vm-stop
just vm-rebuild            # after changing anything under vm/
```

Each boot starts from a fresh copy-on-write overlay of the image, so the guest is always clean.
Host-side edits don't trigger inotify across virtiofs, so Hyprland won't auto-reload: use
`just vm-reload`. New files show up as links after a reboot, when `dotfiles-stow.service` re-runs.

`vm-test` runs `vm/guest-check.sh` inside the guest: boot state, every file under
`.config/hypr` and `.config/waybar` linked into the guest's home, the session processes running,
and no Hyprland config errors.

Users: `tester` (no password, passwordless sudo), and `root` with password `root`.

What this can't test: anything NVIDIA-specific. The guest only sees a virtio GPU, so the
NVIDIA env vars, monitor modes, and which GPU renders still need a real login on the host.
Stow runs with `--no-folding` in the guest, so directories are real and only files are links.
