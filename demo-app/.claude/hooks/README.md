# `.claude/hooks/`

Hook scripts referenced by the Hooks segment of the workshop. Each script is self-contained: shebang, set-strict, registration snippet in the header comment, single responsibility.

## What's here

| Script | Event | Role |
|---|---|---|
| `lint-on-edit.sh` | PostToolUse | The live demo. Runs ruff on edited Python files; surfaces violations back to Claude. **Active in `settings.json`.** |
| `lint-on-stop.sh` | Stop | End-of-turn variant of `lint-on-edit`. Runs ruff against the whole project once when the agent finishes. Recommended over PostToolUse if you find lint-on-edit fires on transient mid-sequence states. Take-home; not registered. |
| `instructions-loaded.sh` | InstructionsLoaded | Observability. Logs every `CLAUDE.md` load to `instructions-loaded.log`. Active via `settings.local.json` (inline registration). |
| `debug.sh` | — *(library)* | Sourceable logging utility. Every other hook in this kit sources it and calls `debug_log "<name>" "$event"` so the full event JSON streams into `hook-debug.log` by default — `tail -f` it while authoring. Not registered as a hook itself; comment the two lines in any caller to silence. |
| `log-edits.sh` | PostToolUse | The 3-line "simplest hook" from the deck. Echoes edited file paths to stderr. Take-home; not registered. |
| `precompact-checkpoint.sh` | PreCompact (auto) | Blocks auto-compact and surfaces a reminder to run `/context` first — turns `01-agent-files` slide 9's "compaction is a signal" into a deterministic checkpoint. **Active in `settings.json`** with matcher `"auto"`; manual `/compact` still proceeds. Flip to advisory by removing `"decision": "block"` from the JSON output. |
| `protect-files.sh` | PreToolUse | Canonical blocker. Rejects edits to paths matching `PROTECTED` patterns. Take-home; not registered. |
| `tests-on-stop.sh` | Stop | Runs `uv run pytest` at end-of-turn; blocks "I'm done" claims on failure. Take-home; not registered (heavy). |
| `hook-template.sh` | — | Commented scaffold. Copy, rename, fill in. |

## Active hooks

`.claude/settings.json` registers two hooks:
- **`lint-on-edit`** (PostToolUse on `Edit|Write|MultiEdit`) — the live demo from slide 9 of the Hooks deck.
- **`precompact-checkpoint`** (PreCompact, matcher `"auto"`) — the discipline guardrail tying back to slide 9 of the Agent Files deck. Blocks the surprise kind of compaction; manual `/compact` is untouched.

`.claude/settings.local.json` registers **`InstructionsLoaded`** as the persistent observability surface — useful while authoring and during the workshop.

The other scripts ship can also be activated. Each header comment includes the registration snippet to drop into your own `settings.json`.

## Conventions used in every script

- Output to **stderr** (`>&2`) so Claude reads it back.
- **Exit 2 to block / surface failure**, not exit 1. Per the [hooks docs](https://code.claude.com/docs/en/hooks), exit 1 is treated as a non-blocking error and the action proceeds anyway — only exit 2 blocks (PreToolUse, Stop, UserPromptSubmit) or feeds stderr to Claude as an actionable error message (PostToolUse).
- **Visible green path** — print a one-line confirmation on success so you can tell the hook ran. Hooks firing silently are worse than not firing at all.
- Read the event JSON from **stdin** via `cat` then extract fields with `jq`. Every script in this kit then sources `debug.sh` and calls `debug_log "<hook-name>" "$event"` — `tail -f hook-debug.log` to see exactly what the harness sent. Comment those two lines out in a script to silence it there.
- **Pick the right event for the check.** A check that's only meaningful once a turn is complete (multi-file refactor, multi-edit implementation) belongs on **Stop**, not PostToolUse — even if the cost is delayed feedback. Compare `lint-on-edit.sh` vs `lint-on-stop.sh` for a worked example. Hooks are iterative: pick an event, ship it, watch for noise, move it.

## Things worth knowing (from the [hooks reference](https://code.claude.com/docs/en/hooks.md))

- **Stop ≠ task-complete.** Stop fires whenever Claude finishes responding. Two shapes verified empirically: tool-mediated clarifications (`AskUserQuestion`) **do not** end a turn — no Stop fires. Plain-text clarifying questions (Claude responds in markdown with a question, no tool) **do** end a turn — Stop fires. For `tests-on-stop`, that means an ambiguous prompt can cost one extra turn before the `stop_hook_active` guard kicks in. Modern Claude prefers `AskUserQuestion`, so this is rarer than it sounds.
- **Undocumented Stop field:** the Stop event payload includes `last_assistant_message` (the text of Claude's just-finished response). Not listed in the [common input fields](https://code.claude.com/docs/en/hooks.md), but present in practice. Use the output of debug.sh to validate hook payloads.
- **Hooks for one event run in parallel.** If two hooks both return `updatedInput`, the last to finish wins. Avoid having multiple hooks modify the same input.
- **`/hooks`** — type it inside Claude Code for a read-only browser of every registered hook. First stop when debugging "is my hook registered?"
- **Settings resolution order:** managed → `~/.claude/settings.json` → `.claude/settings.json` → `.claude/settings.local.json` → plugin → component. Hooks from all layers fire; ordering only matters when they conflict on `updatedInput`.
