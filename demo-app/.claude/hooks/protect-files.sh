#!/usr/bin/env bash
# protect-files — PreToolUse blocker that rejects edits to off-limits paths.
# The canonical "block dangerous edits" pattern from the docs. Demonstrates
# how to use exit 2 on PreToolUse to *prevent* an action rather than flag it
# after.
#
# Edit the PROTECTED array below to your needs (uses bash glob patterns).
#
# Register in .claude/settings.json:
#   "PreToolUse": [{
#     "matcher": "Edit|Write|MultiEdit",
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/protect-files.sh" }]
#   }]
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

PROTECTED=(
  "*.env"
  "*credentials*"
  "*secrets*"
)

event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "protect-files" "$event"

file_path="$(echo "$event" | jq -r '.tool_input.file_path')"

for pattern in "${PROTECTED[@]}"; do
  if [[ "$file_path" == $pattern ]]; then
    echo "✗ protect-files: refusing to edit $file_path (matches $pattern)" >&2
    # Exit 2: PreToolUse blocks the tool call and feeds stderr to Claude.
    # Exit 1 is a non-blocking error — the edit would proceed.
    # See https://code.claude.com/docs/en/hooks.
    exit 2
  fi
done

exit 0
