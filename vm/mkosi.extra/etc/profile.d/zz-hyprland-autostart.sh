if [ "$(tty)" = /dev/tty1 ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(id -un)" = tester ]; then
    exec start-hyprland
fi
