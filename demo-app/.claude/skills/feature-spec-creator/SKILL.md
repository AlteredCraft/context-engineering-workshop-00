---
name: feature-spec-creator
description: Generates a feature spec for an existing codebase via an interview workflow. Use when the user wants to write, draft, or scope a feature spec — phrases like "write a feature spec", "spec out this feature", "draft a spec for X", "I want to add X to this codebase", "let's plan a new feature", or "scope out this feature". Do NOT use for bug fixes, pure refactors with no behavior change, or greenfield projects with no existing code.
argument-hint: [Description of the feature to spec out.]
---

# Feature Spec Generator

Interview the user to produce a focused feature spec for an existing codebase. The output is a single markdown file the user can hand to a developer (or future-Claude) and have enough context to plan the work without re-asking the same questions.

## Why this skill exists

A good spec is the cheapest place to surface scope creep, integration headaches, and contradictions between what the user describes and what the code actually does. Catching those at spec time costs minutes; catching them mid-implementation costs hours. The interview is the value — the markdown is just the artifact. The skill's job is to make that surfacing happen *before* code gets written.

## Workflow

The sequence matters. Do not jump ahead.

### 1. Confirm the feature in one sentence

Before reading any code, ask the user what feature they want to spec, in one sentence. If they already said it clearly in the prompt, just paraphrase it back and ask "is that right?" — don't make them repeat themselves.

If their description is vague (e.g., "I want to improve the dashboard"), ask a single clarifying question to get to a concrete feature before scanning code. Scanning the wrong area is wasted work.

### 2. Lightweight code scan to seed context

Do *just enough* exploration to ground the interview. The goal is not to understand everything — it is to know enough to ask good questions and recognize when an answer contradicts the code.

Aim for a quick scan, not a full architectural review. Specifically:

- Locate the area of the codebase the feature touches (Glob/Grep for likely module names, route handlers, models, components).
- Read 2–4 of the most relevant files end-to-end.
- Skim adjacent files (tests, configs, types) to spot patterns and constraints.
- Note: existing similar features, the data model around the affected area, integration points (APIs, queues, DB tables), and any obvious tech-debt or workarounds in the area.

If the codebase is large or unfamiliar, spawn an Explore subagent to do this scan in parallel rather than serially eating context. Tell it: "Find code relevant to <feature>. Identify (a) where this would naturally live, (b) similar existing features, (c) the data model around it, (d) integration points. Report under 300 words." Don't ask it to design the feature.

After the scan, briefly tell the user what you found — *one paragraph max*. This both shows you did the homework and gives them a chance to redirect ("no, that's the old version, we use the v2 module").

### 3. Adaptive interview

Drive the interview with **`AskUserQuestion`**, one question at a time. The interview is adaptive: pace and ordering should respond to what's already obvious from the code and from prior answers. Do not march through a fixed checklist — that wastes the user's time on questions whose answers you already have.

**Coverage targets** (these are areas that must be covered before the spec is written, but the *order* and *number of questions* per area is up to you):

- **Motivation** — why now, what problem this solves, who is asking, what happens if it doesn't ship.
- **User-facing behavior** — what changes for the end user; entry points; the happy path; the most important edge cases.
- **Scope boundaries** — explicitly *what is out of scope*. This is the highest-leverage area; ask at least one out-of-scope question even if the user thinks scope is obvious.
- **Affected systems** — which modules, services, data stores, external APIs, configs are touched.
- **Risks and unknowns** — performance, security, data migrations, backwards compatibility, observability gaps, things the user is unsure about.

**How to use AskUserQuestion in this skill:**

- One question per turn. Do not batch a 5-question form — the interview needs to adapt to each answer.
- Always offer 2–4 suggested answers PLUS an `"Other (I'll specify)"` option. The user must never feel forced into a preset choice. Suggested answers should be plausible, code-grounded guesses (e.g., if you saw a `notifications/` module, suggest "Yes, extend the existing notifications module" as one option).
- If the user picks the "Other" option, follow up with a free-form question to get their actual answer.
- After each answer, decide: do I have enough to move on, or do I need a followup? Followups are cheap and high-value — use them whenever an answer raises a new question or contradicts the code.

**Examples of good interview behavior:**

> User: "I want to add CSV export to the reports page."
> *(After scanning: there's already a `download_pdf` button on the reports page using a `ReportRenderer` class.)*
> Good question: "I see there's already a PDF download button using `ReportRenderer`. Should CSV export use the same renderer pipeline, or be a separate path? [Same pipeline / Separate path / Other]"
> Bad question: "What format should the CSV be in?" *(This skips the more important architectural question.)*

> User: "Yes, extend the existing notifications module."
> *(But the existing notifications module only handles email, and the user previously said they wanted Slack notifications.)*
> Good followup: "The existing notifications module only sends email — Slack support isn't there yet. Do you want this feature to also add Slack as a new channel, or assume that's out of scope and email-only for now?"

### 4. Surface blockers and contradictions as you go

This is a core part of the skill's value. Whenever you spot a conflict between the code and what the user describes, **say so immediately** — don't save it for the spec. The user may not realize the contradiction exists.

Common blockers worth flagging:

- The user described a behavior that contradicts existing code (e.g., "users can edit comments" but the model has no `updated_at` and comments are immutable in the schema).
- The feature requires data the system doesn't currently capture.
- The feature would conflict with another in-progress change you can see in the code (TODOs, feature flags, partially-built scaffolding).
- The proposed scope is large enough that it should probably be split into multiple specs.
- A claimed integration point doesn't exist or works differently than described.

Flag these as questions, not assertions. "I noticed comments don't have an `updated_at` column and the API doesn't expose an edit endpoint — is adding edit support part of this feature, or am I looking at the wrong area?" lets the user correct you if you're wrong about the code.

If a blocker is severe enough that it changes whether the feature is feasible at all, pause the interview and ask the user how they want to proceed before continuing.

### 5. Wrap up the interview

When you have enough to write the spec, say so explicitly: "I think I have enough — let me draft the spec. I'll flag anything I'm still unsure about in the Open Questions section." Don't drag the interview out chasing 100% certainty; unknowns belong in the Open Questions section, not in more questions.

### 6. Ask where to save

Before writing the file, ask the user where to save it. Use AskUserQuestion with a few sensible suggestions based on what you saw in the repo (e.g., `specs/<feature-slug>.md`, `docs/specs/<feature-slug>.md`, alongside the affected code, or "Other"). Propose a filename slug derived from the feature, and let them edit it.

Do **not** silently pick a path.

### 7. Write the spec

Use the template in [`references/spec-template.md`](references/spec-template.md) verbatim — same sections, same order. Read it now if you haven't.

Fill it in based on the interview. A few rules:

- **Be concrete.** "The user clicks Export and gets a CSV" beats "the system supports data export."
- **Reference real code paths** when you have them — `src/reports/renderer.py:ReportRenderer` is more useful than "the report rendering layer."
- **Quote the user's own framing** for motivation when it captures the why well. Don't paraphrase good quotes into mush.
- **Keep Open Questions honest.** If you're not sure about something, write it down. The spec is more valuable with an explicit unknowns list than with confident-sounding answers you made up.
- **Out-of-scope deserves its own bullet list,** not a sentence buried in a paragraph. Future readers will scan for it.

After writing, briefly summarize what's in the spec (2–3 sentences) and where it lives. Don't recap the entire interview.

### 8. Suggest next steps and stop

End with a short list of suggested next steps in chat — *do not* create them as artifacts. Examples:

- "Want me to draft an implementation plan from this spec?"
- "Want me to create a task folder under `__TASKS/`?"
- "Should we walk through the open questions one more time?"

Then stop. The skill produces the spec only.

## Behavior to avoid

- **Don't skip the code scan.** Even a 5-minute scan changes the questions you ask. A spec written without code grounding is just a wishlist.
- **Don't batch interview questions into a single megaprompt.** Adaptivity is the value. One question, get the answer, decide what to ask next.
- **Don't fill in details the user didn't give you.** If they didn't say how errors should be handled, write "Open Question: error-handling behavior is unspecified" — don't invent a "graceful fallback to cached results" they never asked for.
- **Don't refuse to call out a contradiction because it might be awkward.** Surfacing them is the job. Frame as a question if uncertain ("am I looking at the right code?"), but don't paper over them.
- **Don't write more than one file.** The output is a single spec markdown. No task folders, no plans, no diagrams unless the user asks.

## When to refuse / redirect

If the request is for one of these, redirect rather than spec:

- **Bug fix** → "A spec is overkill for a bug fix. Want me to just investigate the bug and propose a fix?"
- **Pure refactor with no behavior change** → "Specs are for new behavior. For a refactor, an architecture sketch or migration plan fits better — want me to do that instead?"
- **Greenfield project with no code yet** → "This skill assumes an existing codebase to scan. For a greenfield project, you probably want a product brief or architecture doc first — want help with that?"

If the user pushes back ("no, I really want a spec for this refactor"), defer to them and proceed.

## Reference files

- [`references/spec-template.md`](references/spec-template.md) — the exact template structure to use when writing the spec.
