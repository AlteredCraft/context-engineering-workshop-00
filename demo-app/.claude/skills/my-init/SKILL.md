---
name: my-init
description: Initialize or improve CLAUDE.md the way this project prefers — inline README via `@README.md` to avoid drift, and split ephemeral code observations into a sibling INIT_OBSERVATIONS.md so CLAUDE.md stays focused on durable project conventions.
disable-model-invocation: true
---

# my-init

Run the standard `/init` flow to produce (or improve) `CLAUDE.md`, then apply the project-specific rules below.

## Project-specific rules for CLAUDE.md

1. **Inline the README, don't duplicate it.**
   - Add a `@README.md` reference near the top of `CLAUDE.md`. The `@README.md` syntax inlines README's full content into Claude's context automatically.
   - Because README is inlined, when working on `CLAUDE.md`, first read README.md, then ensure you do NOT copy any of its contents into `CLAUDE.md`. Instead, only add to `CLAUDE.md` what is NOT already in README. This avoids duplication and drift between the two files.
   - If you change README, you do not need to mirror the change into CLAUDE.md.

2. **Relegate ephemeral observations to `INIT_OBSERVATIONS.md`.**
   - During `/init`, you will naturally surface one-off findings: noticed tech debt, "this file looks unused", inconsistencies, refactor ideas, TODOs you spotted, architectural questions. These are observations, not conventions.
   - Write those to a sibling `INIT_OBSERVATIONS.md` at the repo root (create it if missing, append if present). Date each batch with today's date.
   - Keep `CLAUDE.md` focused on durable project conventions — the patterns a future Claude needs to follow (architecture seams, non-obvious constraints, house rules on testing/style). If a line would go stale in a month, it belongs in `INIT_OBSERVATIONS.md`, not `CLAUDE.md`.

## Process

1. Follow the normal `/init` analysis: read existing `CLAUDE.md` (if present), scan the codebase, identify durable conventions.
2. Draft `CLAUDE.md` with:
   - The standard header ("# CLAUDE.md" + the "This file provides guidance…" line).
   - Any project-specific top-of-file directives already present (e.g., the `date` command).
   - A `@README.md` line to inline the README.
   - Sections for **Commands**, **Architecture notes**, **Testing**, **Code style** — but only entries that are NOT already covered by README.
3. Separately, write `INIT_OBSERVATIONS.md` for anything ephemeral or observation-shaped that surfaced during the scan. Prefix the batch with today's date.
4. If `CLAUDE.md` already exists, suggest edits rather than overwriting, same as the standard `/init`.
