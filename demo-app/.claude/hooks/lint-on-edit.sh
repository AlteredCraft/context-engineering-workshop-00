#!/usr/bin/env bash
# lint-on-edit — PostToolUse hook that runs ruff on edited Python files.
# Surfaces violations back into the conversation via stderr; exits 2 on
# failure so Claude reads the complaint and corrects.
#
# Trade-off: PostToolUse fires on every Edit, including transient
# mid-sequence states (e.g., an import lands one edit before the line
# that uses it — ruff complains "unused import" prematurely). If that
# becomes noisy in real use, see lint-on-stop.sh for the end-of-turn
# variant.
#
# Register in .claude/settings.json:
#   "PostToolUse": [{
#     "matcher": "Edit|Write|MultiEdit",
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/lint-on-edit.sh" }]
#   }]
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "lint-on-edit" "$event"

file_path="$(echo "$event" | jq -r '.tool_input.file_path')"

# No-op on non-Python files
if [[ "$file_path" != *.py ]]; then
  exit 0
fi

# Run ruff against the edited file
if uv run ruff check "$file_path" >&2; then
  echo "✓ ruff clean: $file_path" >&2
  exit 0
else
  # Exit 2: PostToolUse can't block, but stderr is fed back to Claude as an
  # error message it can read and act on. Exit 1 would show as a generic
  # "hook error" notice (first line only) and Claude would not be prompted
  # to respond. See https://code.claude.com/docs/en/hooks.
  exit 2
fi
