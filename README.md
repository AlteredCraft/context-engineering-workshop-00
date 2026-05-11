<a href="https://maven.com/altered-craft-learning"><img src="docs/ac-wm-light-bg.svg" alt="AlteredCraft" width="240"></a>

# Context Engineering for Claude Code

Workshop materials from **Context Engineering for Claude Code**, an [AlteredCraft](https://maven.com/altered-craft-learning) workshop.

> **Your agent is only as good as the context you give it.**

For developers already using Claude Code who want to go from ad-hoc prompting to a systematic context practice. Designing where each piece of knowledge lives and managing the context budget.

## Take the workshop

Live cohort sessions are run on Maven:

- **School:** [maven.com/altered-craft-learning](https://maven.com/altered-craft-learning)
- **This workshop:** [Context Engineering for Claude Code](https://maven.com/altered-craft-learning/context-engineering-for-claude-code)

## What's in this repo

- **[`docs/`](docs/) — Reference cards.** Four take-home reference cards (the Context Ladder, the Skill Spectrum, Agent Files, Hook Events). Browse them on the [Pages site](https://samkeen.github.io/context-engineering-workshop-00/).
- **[`demo-app/`](demo-app/) — The live-build demo, end state.** A small Flask RSS reader instrumented with a project `CLAUDE.md`, a folder `CLAUDE.md` for tests, a `spec-creator` skill, and a `lint-on-edit` hook. The artifact attendees see constructed across the three workshop segments.

## What attendees learn to do

1. Design a `CLAUDE.md` ecosystem strategy — project, folder, and user level, with team conventions separate from personal preferences.
2. Use folder-level `CLAUDE.md` files as the lazy-load primitive for scoped, place-anchored conventions — without bloating the project file.
3. Design a custom skill for a recurring workflow, using the *Anchored Interview* technique.
4. Configure a hook that enforces a guardrail automatically.

## Running the demo app

```bash
cd demo-app
uv sync
uv run flask --app app run
```

Then visit <http://localhost:5000>. See [`demo-app/README.md`](demo-app/README.md) for stack, layout, and tests.

---

© Altered Craft, LLC. Workshop content released for attendee reference.
