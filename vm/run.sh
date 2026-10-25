#!/usr/bin/env bash
# Boot the dotfiles test VM with GPU acceleration and the repo shared read-only.
#
# Each run starts from a fresh copy-on-write overlay of the built image, so the guest
# is always clean. Set KEEP=1 to reuse the previous run's overlay instead.
# Set DISPLAY_BACKEND=sdl if the gtk window misbehaves.
# A root shell is on the serial port: socat -,raw,echo=0 UNIX-CONNECT:"$XDG_RUNTIME_DIR/dotfiles-vm-serial.sock"
# QEMU_EXTRA is appended to the qemu command line (e.g. a -qmp socket for screendumps).
set -euo pipefail

vm_dir="$(cd "$(dirname "$0")" && pwd)"
repo_dir="$(dirname "$vm_dir")"
out_dir="$vm_dir/mkosi.output"
image="$out_dir/dotfiles-vm.raw"
overlay="$out_dir/overlay.qcow2"
ovmf_code=/usr/share/edk2/x64/OVMF_CODE.4m.fd
ovmf_vars="$out_dir/OVMF_VARS.4m.fd"
mem=4G

if pgrep -f '^qemu-system-x86_64 -name dotfiles-vm' >/dev/null; then
    echo "A dotfiles VM is already running. Stop it first: just vm-stop" >&2
    exit 1
fi
[[ -f $image ]] || { echo "No image at $image. Build it first: mkosi -C vm build" >&2; exit 1; }

if [[ ${KEEP:-0} != 1 || ! -f $overlay ]]; then
    qemu-img create -q -f qcow2 -b "$image" -F raw "$overlay"
    cp /usr/share/edk2/x64/OVMF_VARS.4m.fd "$ovmf_vars"
fi

runtime_dir="$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/dotfiles-vm.XXXXXX")"
sock="$runtime_dir/virtiofs.sock"
trap 'kill "$virtiofsd_pid" 2>/dev/null || true; rm -rf "$runtime_dir"' EXIT

# --readonly: the guest can't modify the repo, even as root.
virtiofsd --socket-path="$sock" --shared-dir="$repo_dir" --readonly --sandbox=none \
    --log-level=error &
virtiofsd_pid=$!
while [[ ! -S $sock ]]; do sleep 0.1; done

qemu-system-x86_64 \
    -name dotfiles-vm \
    -machine q35,accel=kvm -cpu host -smp 4 -m "$mem" \
    -object memory-backend-memfd,id=mem,size="$mem",share=on -numa node,memdev=mem \
    -drive if=pflash,format=raw,readonly=on,file="$ovmf_code" \
    -drive if=pflash,format=raw,file="$ovmf_vars" \
    -drive if=virtio,format=qcow2,file="$overlay" \
    -chardev socket,id=dotfiles,path="$sock" \
    -device vhost-user-fs-pci,chardev=dotfiles,tag=dotfiles \
    -device virtio-vga-gl -display "${DISPLAY_BACKEND:-gtk},gl=on" \
    -device qemu-xhci -device usb-tablet -device usb-kbd \
    -nic user,model=virtio-net-pci \
    -serial unix:"${XDG_RUNTIME_DIR:-/tmp}/dotfiles-vm-serial.sock",server=on,wait=off \
    -audio driver=pipewire,model=virtio \
    ${QEMU_EXTRA:-}
