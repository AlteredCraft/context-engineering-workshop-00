---
name:feature-spec-creator
description: Generates a feature spec for an existing codebase via an interview workflow. Use when the user wants to write, draft, or scope a feature spec for an existing codebase.
---

<!-- 
Add an interview workflow to the feature spec creator.
-->

# Feature Spec Generator

Interview the user to produce a feature spec for an existing codebase. The output is a single markdown file the user can hand to a developer to plan the work.

## Workflow

### 1. Confirm the feature in one sentence

Before reading any code, paraphrase the user's ask back to them and confirm. If their description is vague, ask a single clarifying question to land on a concrete feature. Scanning the wrong area is wasted work.

### 2. Lightweight code scan

Do *just enough* exploration to ground the interview. Not a full architectural review.

- Locate the area of the codebase the feature touches (Glob/Grep for likely module names).
- Read 2–4 of the most relevant files end-to-end.
- Skim adjacent files (tests, configs, types).
- Note: existing similar features, the data model, integration points.

After the scan, briefly tell the user what you found in one paragraph. Give them a chance to redirect.

### 3. Interview

Ask 2–3 clarifying questions tailored to what's ambiguous given the codebase. Wait for answers. Cover:

- What changes for the user (happy path, key edge cases)
- What's in scope and what's out
- Which existing pattern this builds on

### 4. Write the spec

Emit a structured spec covering:

- **Motivation** — why now, what problem
- **User-facing behavior** — happy path, edge cases
- **Scope** — in / out (be explicit about out)
- **Affected code** — files and integration points
- **Open questions** — unknowns the team needs to decide

### 5. Stop

Do not continue editing files. Implementation is a separate task.
