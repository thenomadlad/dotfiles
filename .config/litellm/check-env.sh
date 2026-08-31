#!/bin/sh
missing=""
[ -z "$ANTHROPIC_API_KEY" ] && missing="$missing ANTHROPIC_API_KEY"
[ -z "$LITELLM_MASTER_KEY" ] && missing="$missing ANTHROPIC_API_KEY"

if [ -n "$missing" ]; then
  echo "litellm: missing env var(s):$missing" >&2
  echo "Hint: ~/.config/environment.d/ files are only read by the systemd user manager at its own startup -- editing them takes a fresh login or 'systemctl --user daemon-reexec' to take effect. Run 'systemctl --user show-environment | grep -E \"ANTHROPIC|LITELLM\"' to see what the manager currently has loaded." >&2
  exit 1
fi
exit 0
