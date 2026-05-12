---
name:feature-spec-creator
description: >-
  Generates a feature spec for an existing codebase via an interview workflow. Use when the user
  wants to write, draft, or scope a feature spec — phrases like "write a feature spec",
  "spec out this feature", "draft a spec for X", "I want to add X to this codebase",
  "let's plan a new feature", or "scope out this feature". Do NOT use for bug fixes,
  pure refactors with no behavior change, or greenfield projects with no existing code.
---

<!-- 
- More rubust interview workflow with goal of common understanding, Collaborative partner.
- Use of sub agents
- Use of AskUserQuestion
- addition of references/spec-template.md
-->

# Feature Spec Generator

Interview the user to produce a focused feature spec for an existing codebase. The interview is the value — the markdown is just the artifact. The skill's job is to surface scope creep, integration headaches, and contradictions between what the user describes and what the code actually does, *before* code gets written.

## Workflow

### 1. Confirm the feature in one sentence

Before reading any code, paraphrase the user's ask back. If vague, ask one clarifying question to land on a concrete feature.

### 2. Lightweight code scan

Do just enough exploration to ground the interview:

- Glob/Grep for likely module names; read 2–4 most-relevant files end-to-end; skim adjacent tests/configs.
- Note: similar features, data model, integration points, tech-debt in the area.
- **For large or unfamiliar codebases**, spawn an Explore subagent to scan in parallel rather than serially eating context. Tell it: "Find code relevant to <feature>. Identify (a) where it would naturally live, (b) similar existing features, (c) the data model, (d) integration points. Report under 300 words."

After the scan, briefly summarize what you found — one paragraph — and let the user redirect if you're looking at the wrong area.

### 3. Adaptive interview using `AskUserQuestion`

Drive the interview with **`AskUserQuestion`**, one question at a time. Adapt order and depth to what's already obvious from the code and from prior answers — do not march through a fixed checklist.

**Coverage areas** (cover all, but order/count is up to you):

- **Motivation** — why now, what problem, who is asking
- **User-facing behavior** — happy path, key edge cases, entry points
- **Scope boundaries** — explicitly *what is out of scope* (highest-leverage area)
- **Affected systems** — modules, data stores, external APIs, configs
- **Risks and unknowns** — performance, security, migrations, observability gaps

**How to use AskUserQuestion:**

- One question per turn — do not batch.
- Always offer 2–4 suggested answers PLUS an `"Other (I'll specify)"` option. Suggested answers should be code-grounded guesses.
- Followups are cheap — use them whenever an answer is vague or contradicts the code.

### 4. Surface blockers and contradictions live

Whenever an answer contradicts the code, **say so immediately** — don't save it for the spec. Frame as a question, not an assertion: *"I noticed comments don't have an `updated_at` column — is adding edit support part of this feature, or am I looking at the wrong area?"*

If a blocker is severe enough to change feasibility, pause the interview and ask how to proceed.

### 5. Ask where to save

Use `AskUserQuestion` with sensible suggestions based on the repo (e.g., `specs/<slug>.md`, `docs/specs/<slug>.md`, alongside affected code, or "Other"). Propose a filename slug; let the user edit it. **Do not silently pick a path.**

### 6. Write the spec

Use the template in `references/spec-template.md` verbatim. Fill in based on the interview. Reference real code paths (`src/reports/renderer.py:ReportRenderer`, not "the rendering layer"). Quote the user's framing for motivation when it's good. Keep open questions honest — don't invent answers.

### 7. Stop

Suggest next steps in chat ("Want me to draft an implementation plan from this?"). Do not create artifacts beyond the spec. The skill produces one file.

## Reference files

- [`references/spec-template.md`](references/spec-template.md) — the exact template structure.
