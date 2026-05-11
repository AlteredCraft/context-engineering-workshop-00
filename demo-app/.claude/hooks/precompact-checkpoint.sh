#!/usr/bin/env bash
# precompact-checkpoint — PreCompact hook that blocks auto-compact and
# nudges the user to inspect /context first.
#
# Why this exists: 01-agent-files slide 9 frames /compact as a *signal*
# that context grew unchecked — the better fix is upstream (move heavy
# work into a skill, repeating reminders into a hook, unrelated tasks
# behind /clear, or trim CLAUDE.md). This hook makes that discipline
# deterministic: when auto-compact is about to fire, it stops the harness
# and asks the user to consider /context first.
#
# Why matcher "auto" only: manual /compact is a deliberate act — the user
# already chose. Auto-compact happens without warning, and that's the
# moment a "stop and think" prompt is most useful. Manual /compact still
# proceeds untouched.
#
# Register in .claude/settings.json:
#   "PreCompact": [{
#     "matcher": "auto",
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/precompact-checkpoint.sh" }]
#   }]
#
# Flip to advisory (non-blocking) by removing the "decision": "block"
# line from the JSON output below — the reason text will still print,
# but compaction will proceed.
#
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "precompact-checkpoint" "$event"

# Block compaction and surface the reminder. The "reason" field is shown
# back to the user. Per the hooks docs, JSON on stdout with
# decision:"block" prevents the action; we exit 0 so the JSON parses.
# See https://code.claude.com/docs/en/hooks#precompact.
cat <<'JSON'
{
  "decision": "block",
  "reason": "Auto-compact intercepted. Run /context first to see what's actually loading — compaction is a signal that context grew unchecked, and the better fix is usually upstream: move heavy work into a skill (forks context), repeating reminders into a hook (zero context), unrelated tasks behind /clear, or trim CLAUDE.md. If you've checked and still want to compact, type /compact manually and it will proceed."
}
JSON
