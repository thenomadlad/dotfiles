# Tasks for this dotfiles repo. Not stowed (see .stow-local-ignore).
# The vm-* recipes drive a throwaway Arch VM for testing the config; see vm/README.md.

guest-exec := "python3 -I vm/guest-exec.py"
vm-process := "^qemu-system-x86_64 -name dotfiles-vm"

# List recipes
default:
    @just --list

# Show what stow would link into $HOME, without changing anything
stow-plan:
    stow --simulate --verbose .

# Link the dotfiles into $HOME; restows to also prune links to files removed from the repo
stow:
    stow --restow --verbose .

# Like stow, but move existing $HOME files into the repo instead of failing on them
stow-adopt:
    #!/usr/bin/env bash
    set -euo pipefail
    # --adopt overwrites repo files with the $HOME versions. On a clean tree, git shows exactly
    # what was taken over, and `git checkout -- <file>` restores the repo's version.
    if ! git diff --quiet HEAD; then
        echo "Uncommitted changes; commit or stash first so adopted files show up cleanly in git." >&2
        exit 1
    fi
    stow --adopt --restow --verbose .
    if git diff --quiet HEAD; then
        echo "Nothing adopted changed the repo."
    else
        echo "Adopted files changed the repo. Review, then commit or 'git checkout -- <file>':"
        git status --short
    fi

# Remove the dotfiles' links from $HOME
unstow:
    stow --delete --verbose .

# Build the test VM image (skipped if it already exists)
vm-build:
    mkosi -C vm build

# Rebuild the test VM image, e.g. after changing anything under vm/
vm-rebuild:
    mkosi -C vm --force build

# Boot the VM in a window, from a fresh copy of the image
vm: _vm-not-running vm-build
    vm/run.sh

# Boot the VM keeping the disk from the last run
vm-resume: _vm-not-running vm-build
    KEEP=1 vm/run.sh

# Boot the VM, check it came up on this repo's config, then leave it open to try out
vm-test: _vm-not-running vm-build
    #!/usr/bin/env bash
    set -uo pipefail
    vm/run.sh & vm_pid=$!
    trap 'kill $vm_pid 2>/dev/null' INT TERM
    {{ guest-exec }} --timeout 180 'sh /mnt/dotfiles/vm/guest-check.sh'
    status=$?
    if (( status == 0 )); then echo "All checks passed. Try it out; close the VM window when done."
    else echo "Some checks failed (exit $status). The VM stays up for poking at: just vm-shell"; fi
    wait $vm_pid
    exit $status

# Re-run the boot checks against a VM that's already running
vm-check:
    {{ guest-exec }} --timeout 180 'sh /mnt/dotfiles/vm/guest-check.sh'

# Root shell on the running VM's serial console (Ctrl+] to leave)
vm-shell:
    socat -,raw,echo=0,escape=0x1d UNIX-CONNECT:"${XDG_RUNTIME_DIR:-/tmp}/dotfiles-vm-serial.sock"

# Run a single-line command as root in the running VM
vm-exec cmd:
    {{ guest-exec }} {{ quote(cmd) }}

# Reload Hyprland in the VM after editing config on the host
vm-reload:
    {{ guest-exec }} 'sudo -u tester XDG_RUNTIME_DIR=/run/user/1000 hyprctl -i 0 reload'

# Power off the running VM and wait for it to exit
vm-stop:
    #!/usr/bin/env bash
    pgrep -f '{{ vm-process }}' >/dev/null || { echo "No dotfiles VM running"; exit 0; }
    {{ guest-exec }} --no-wait 'systemctl poweroff' || exit
    for _ in $(seq 60); do pgrep -f '{{ vm-process }}' >/dev/null || exit 0; sleep 1; done
    echo "VM still running after 60s" >&2; exit 1

# Fail early if a VM is already running, so checks can't hit a stale instance
[private]
_vm-not-running:
    @! pgrep -f '{{ vm-process }}' >/dev/null || { echo "A dotfiles VM is already running. Stop it first: just vm-stop" >&2; exit 1; }

# Delete the built image and mkosi's caches
vm-clean:
    mkosi -C vm -ff clean
