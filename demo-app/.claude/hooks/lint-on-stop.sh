#!/usr/bin/env bash
# lint-on-stop — Stop-hook variant of lint-on-edit. Runs ruff against
# the whole project once, at end-of-turn, when the agent has signaled
# it's done.
#
# Why this variant exists: PostToolUse on lint can be twitchy during
# multi-step refactors. Claude adds an import on Edit #1 intending to
# use it on Edit #2 — ruff fires on Edit #1 complaining the import is
# unused, and the agent gets prematurely interrupted. Stop defers the
# check to end-of-turn where the file is in a complete state.
#
# Trade-off vs lint-on-edit.sh:
#   PostToolUse: immediate per-edit feedback; can fire on transient
#                invalid states the agent hasn't finished resolving.
#   Stop:        quieter during work; one check at end-of-turn.
#
# Caveat: Stop fires whenever Claude *finishes responding*, not only
# at task completion. Plain-text clarifying questions (Claude asks a
# question in markdown, no tool call) end a turn and trigger this hook.
# Tool-mediated questions (AskUserQuestion) do not. Usually a non-issue
# for lint (project state is project state), but worth knowing.
#
# Register in .claude/settings.json:
#   "Stop": [{
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/lint-on-stop.sh" }]
#   }]
#
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

# Infinite-loop guard. If a Stop hook keeps exiting 2, the harness will
# keep continuing the turn — and on a genuinely unfixable failure we'd
# loop forever. The harness sets `.stop_hook_active = true` on the
# event JSON when it has already triggered a continuation in this Stop
# chain. Exit 0 in that case so Claude can actually finish instead of
# looping.
# See https://code.claude.com/docs/en/hooks-guide#stop-hook-runs-forever.
event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "lint-on-stop" "$event"

if [[ "$(echo "$event" | jq -r '.stop_hook_active // false')" == "true" ]]; then
  echo "↷ lint-on-stop: stop_hook_active=true — letting Claude finish" >&2
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

if uv run ruff check . >&2; then
  echo "✓ ruff clean (project)" >&2
  exit 0
else
  # Exit 2: Stop blocks Claude from stopping and feeds stderr back so the
  # agent can see violations and fix them before ending the turn.
  # See https://code.claude.com/docs/en/hooks.
  exit 2
fi
