#!/usr/bin/env bash
# <hook-name> — <one-line description of what this hook does>
#
# Register in .claude/settings.json:
#   "<EventName>": [{
#     "matcher": "<ToolPattern>",
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/<hook-name>.sh" }]
#   }]
#
# Common events: PreToolUse | PostToolUse | Stop | UserPromptSubmit |
#                SessionStart | SessionEnd | InstructionsLoaded
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "<hook-name>" "$event"

# Extract whatever fields you need from the event JSON.
# file_path="$(echo "$event" | jq -r '.tool_input.file_path')"

# Do your check / action here.
# Exit 0 to allow / pass.
# Exit 2 to block (PreToolUse, Stop) or surface a failure that Claude
# should read and act on (PostToolUse — stderr is fed back as an error
# message). Note: exit 1 is treated as a non-blocking error and the
# action proceeds — use exit 2 when you want Claude to respond.
# See https://code.claude.com/docs/en/hooks.

exit 0
