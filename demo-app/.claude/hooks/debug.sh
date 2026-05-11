#!/usr/bin/env bash
# debug — diagnostic logging utility for hook scripts.
# Sourced from another hook to log the full event JSON to a file while
# you're authoring it. Lets you discover what fields are available on
# the event you're targeting without registering a separate hook.
#
# Usage from another hook script (after capturing the event from stdin):
#
#   event="$(cat)"
#
#   # Log the full event JSON to hook-debug.log. Comment out to disable.
#   source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
#   debug_log "lint-on-edit" "$event"
#
# Every hook script in this kit ships with that block enabled by default —
# `tail -f hook-debug.log` next to your editor and you can watch every
# event flow through. Comment out the two lines in any hook to silence it
# there. Truncate the log freely; nothing reads it back.
#
# Output: appends a timestamped, pretty-printed JSON dump of the event
# (tagged with the calling hook's name) to hook-debug.log at the project
# root.
#
# Sourcing note: `${CLAUDE_PROJECT_DIR}` is inherited from the caller's
# environment — the harness sets it before invoking your hook, and a
# sourced file runs in the same shell, so the env var is visible inside
# `debug_log` exactly as it is in the calling script.
#
# This file is *sourced*, not executed — no `set -euo pipefail` here so
# we don't change the calling script's shell options. No registration in
# settings.json: it's a library, not a hook.

debug_log() {
  local hook_name="${1:-unknown}"
  local event="${2:-}"
  local log="${CLAUDE_PROJECT_DIR:-.}/hook-debug.log"
  {
    echo "--- $(date -u '+%Y-%m-%dT%H:%M:%SZ') [${hook_name}] ---"
    echo "$event" | jq .
    echo
  } >> "$log"
}
