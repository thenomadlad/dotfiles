#!/usr/bin/env python3
import json
import os
import shlex
import subprocess
import sys


def is_in_git_repo(path: str) -> bool:
    directory = path if os.path.isdir(path) else os.path.dirname(path)
    while directory and not os.path.isdir(directory):
        parent = os.path.dirname(directory)
        if parent == directory:
            break
        directory = parent
    result = subprocess.run(
        ["git", "-C", directory, "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
    )
    return result.returncode == 0


def paths_to_check(data: dict) -> list[str]:
    tool_name = data.get("tool_name", "")
    ti = data.get("tool_input", {})
    cwd = data.get("cwd", "")

    def resolve(path: str) -> str:
        if path and not os.path.isabs(path) and cwd:
            return os.path.join(cwd, path)
        return path

    if tool_name in ("Write", "Edit", "NotebookEdit"):
        path = ti.get("file_path") or ti.get("notebook_path") or ""
        return [resolve(path)] if path else []

    if tool_name == "Bash":
        try:
            parts = shlex.split(ti.get("command", ""))
        except ValueError:
            return []
        cmd = os.path.basename(parts[0]) if parts else ""
        args = [p for p in parts[1:] if not p.startswith("-")]
        # All path arguments are potentially affected for these destructive commands
        if cmd in ("rm", "rmdir", "mv", "shred", "truncate") and args:
            return [resolve(p) for p in args]

    return []


data = json.load(sys.stdin)
for path in paths_to_check(data):
    if not is_in_git_repo(path):
        print(f"Blocked: '{path}' is not inside a git repository.", file=sys.stderr)
        sys.exit(2)
