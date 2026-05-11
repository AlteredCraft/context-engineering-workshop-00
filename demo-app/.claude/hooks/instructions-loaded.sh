#!/usr/bin/env bash
# instructions-loaded — observability hook that logs every CLAUDE.md load
# event with its path, memory_type, and load_reason. Closes the loop for
# context engineering: confirms what the agent actually loaded vs. what
# /context displays.
#
# Output: appends one line per event to instructions-loaded.log at the
# project root. Tails like a flight recorder; never blocks.
#
# Register in .claude/settings.json (or .claude/settings.local.json for
# personal use):
#   "InstructionsLoaded": [{
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/instructions-loaded.sh" }]
#   }]
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "instructions-loaded" "$event"

echo "$event" | jq -r '
  ({
    "User":    "👤",
    "Project": "📁",
    "Local":   "📍",
    "Plugin":  "🔌"
  }[.memory_type] // "📄") as $emoji
  | "\($emoji) \(.memory_type) \(.file_path) \(.load_reason)"
' >> "${CLAUDE_PROJECT_DIR:-.}/instructions-loaded.log"
