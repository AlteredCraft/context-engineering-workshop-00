#!/usr/bin/env bash
# tests-on-stop — Stop hook that runs the test suite at end-of-turn.
# Blocks the agent from claiming "I'm done" if anything fails: exit 2
# forces another iteration where it must fix and re-try.
#
# Heavy by design. Only register this if your suite is fast (< ~10s)
# or you genuinely want the round-trip cost on every turn.
#
# Caveat (verified empirically against the docs): Stop fires whenever
# Claude *finishes responding*, not only at task completion. There are
# two clarification shapes and they behave differently:
#   - Tool-mediated (AskUserQuestion): does NOT end a turn, no Stop
#     fires — the tool blocks within an in-progress turn. Safe.
#   - Plain-text (Claude responds with a question in markdown, no
#     tool call — common when the prompt is ambiguous): ends a turn,
#     Stop fires before you've answered. Tests run, fail because the
#     work isn't done, exit 2 forces continuation, and Claude resumes
#     without your answer.
# The `stop_hook_active` guard below breaks any infinite loop, but on
# the plain-text path you'll still pay one extra turn. Modern Claude
# prefers AskUserQuestion, so the failure mode is rarer than it sounds
# — but watch for it on ambiguous prompts.
#
# Register in .claude/settings.json:
#   "Stop": [{
#     "hooks": [{ "type": "command",
#                 "command": "bash $CLAUDE_PROJECT_DIR/.claude/hooks/tests-on-stop.sh" }]
#   }]
# Strict mode: -e exit on any command failure; -u error on undefined vars;
# pipefail makes a pipeline fail if any stage fails (not just the last).
set -euo pipefail

# Infinite-loop guard. If a Stop hook keeps exiting 2, the harness will
# keep continuing the turn — and on a genuinely unfixable failure (flaky
# test, environment issue) we'd loop forever. The harness sets
# `.stop_hook_active = true` on the event JSON when it has already
# triggered a continuation in this Stop chain. Exit 0 in that case so
# Claude can actually finish instead of looping.
# See https://code.claude.com/docs/en/hooks-guide#stop-hook-runs-forever.
event="$(cat)"

# Log the full event JSON to hook-debug.log. Comment out to disable.
source "${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/debug.sh"
debug_log "tests-on-stop" "$event"

if [[ "$(echo "$event" | jq -r '.stop_hook_active // false')" == "true" ]]; then
  echo "↷ tests-on-stop: stop_hook_active=true — letting Claude finish" >&2
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

if uv run pytest -q >&2; then
  echo "✓ tests pass" >&2
  exit 0
else
  echo "✗ tests-on-stop: pytest failed; not done yet" >&2
  # Exit 2: Stop blocks Claude from stopping and forces continuation
  # (it has to fix and try again). Exit 1 is non-blocking — Claude
  # would stop anyway. See https://code.claude.com/docs/en/hooks.
  exit 2
fi
