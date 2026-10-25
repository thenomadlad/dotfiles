#!/bin/sh
# Runs inside the VM (via `just vm-check`): verifies it booted into this repo's config.
# The repo is mounted at /mnt/dotfiles, so this script always matches the host's working tree.

repo=/mnt/dotfiles
home=/home/tester
failed=0

check() {
    desc=$1; shift
    if "$@" >/dev/null 2>&1; then echo "ok    $desc"; else echo "FAIL  $desc"; failed=1; fi
}
hypr() { sudo -u tester XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 "$@"; }

# Let boot and Hyprland's autostart settle before checking.
systemctl is-system-running --wait >/dev/null 2>&1
i=0; until hypr version >/dev/null 2>&1 || [ $i -ge 30 ]; do i=$((i + 1)); sleep 1; done
sleep 3

check "system booted cleanly" test "$(systemctl is-system-running)" = running
check "dotfiles-stow succeeded" test "$(systemctl show -P Result dotfiles-stow)" = success

for f in $(cd "$repo" && find .config/hypr .config/waybar -type f | sort); do
    check "~/$f -> repo" test "$(readlink -f "$home/$f")" = "$repo/$f"
done

for p in Hyprland waybar mako hypridle hyprpolkitagent; do
    check "$p running" pgrep -x "$p"
done

check "no Hyprland config errors" test -z "$(hypr configerrors | tr -d '[:space:]')"

exit $failed
