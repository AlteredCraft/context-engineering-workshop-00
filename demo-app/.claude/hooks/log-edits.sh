#!/usr/bin/env bash
# log-edits — the simplest hook in the deck. Echoes the file path of every
# edit to stderr. Useful as a smoke test that your hook setup is wired up.
#
# Register in .claude/settings.local.json:
#   "PostToolUse": [{
#     "matcher": "Edit",
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/log-edits.sh" }]
#   }]
event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "log-edits" "$event"

echo "[edit] $(echo "$event" | jq -r '.tool_input.file_path')" >&2
