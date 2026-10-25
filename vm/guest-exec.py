#!/usr/bin/env python3
"""Run a shell command as root in the dotfiles VM over its serial console.

Prints the command's output and exits with its status. Waits for the VM to finish
booting (up to --timeout), so it can be used right after starting vm/run.sh.
The serial socket accepts one client at a time, so close `just vm-shell` first.
"""
import argparse
import os
import re
import socket
import sys
import time
import uuid

SOCKET = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "dotfiles-vm-serial.sock")
# OSC/DCS sequences, CSI sequences and carriage returns from the guest's prompt and tools.
ESCAPES = re.compile(r"\x1b[\]P][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-9;:?]*[A-Za-z]|\r")


def connect(deadline):
    while True:
        try:
            s = socket.socket(socket.AF_UNIX)
            s.connect(SOCKET)
            s.settimeout(0.5)
            return s
        except OSError:
            if time.time() > deadline:
                sys.exit(f"guest-exec: no VM serial socket at {SOCKET} (is `just vm` running?)")
            time.sleep(1)


def run(s, command, deadline, attempt_secs, started_only=False):
    """Send command bracketed by markers; return (output, status) or None if no reply in time.

    With started_only, return ("", 0) as soon as the guest starts running the command.

    The markers are printed with printf so the output form differs from the typed (echoed)
    form, which makes them unambiguous whether or not the terminal echoes input.
    """
    tag = uuid.uuid4().hex[:8]
    s.sendall(f"\nprintf '__%s_S__\\n' {tag}; {command}; printf '__%s_%s__\\n' {tag} \"$?\"\n".encode())
    end = re.compile(rf"__{tag}_S__\n" if started_only else rf"__{tag}_S__\n(.*?)__{tag}_(\d+)__", re.S)
    buf = ""
    stop = min(deadline, time.time() + attempt_secs)
    while time.time() < stop:
        try:
            buf += s.recv(65536).decode(errors="replace")
        except socket.timeout:
            continue
        if m := end.search(ESCAPES.sub("", buf)):
            return ("", 0) if started_only else (m.group(1), int(m.group(2)))
    return None


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("command", help="shell command (single line) to run as root")
    p.add_argument("--timeout", type=float, default=30, help="seconds to wait in total (default 30)")
    p.add_argument("--no-wait", action="store_true", help="return once the command starts; don't wait for a result")
    a = p.parse_args()

    deadline = time.time() + a.timeout
    env = "export TERM=dumb SYSTEMD_COLORS=0 SYSTEMD_PAGER=cat"
    # Until the serial getty is up, input is lost, and during early boot the socket can reset.
    # Probe (reconnecting as needed) until a command round-trips.
    s = None
    while True:
        try:
            s = s or connect(deadline)
            if run(s, env, deadline, attempt_secs=3) is not None:
                break
        except OSError:
            if s:
                s.close()
            s = None
            time.sleep(1)
        if time.time() > deadline:
            sys.exit("guest-exec: VM didn't answer on the serial console in time")

    # Even with --no-wait, wait for the command to start: QEMU drops serial input it hasn't
    # read yet when the socket closes, and the emulated UART only takes a few bytes at a time.
    try:
        result = run(s, a.command, deadline, attempt_secs=a.timeout, started_only=a.no_wait)
    except OSError as e:
        sys.exit(f"guest-exec: lost the serial connection: {e}")
    if result is None:
        sys.exit(f"guest-exec: command didn't finish within {a.timeout:.0f}s")
    output, status = result
    sys.stdout.write(output)
    sys.exit(status)


if __name__ == "__main__":
    main()
