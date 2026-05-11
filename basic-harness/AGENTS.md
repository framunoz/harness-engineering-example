# AGENTS.md

This file is a router for progressive-disclosure workflow rules.

## Startup (always)

Before writing or changing code:

1. Confirm the working directory with `pwd`.
2. Read `ARCHITECTURE.md`.
3. Read `.agents/progress/CURRENT.md`.
4. Read `.agents/progress/feature_list.json`.
5. Run `./init.sh`.

If startup checks fail, fix that baseline first.

For detailed startup procedure and read policy, treat `.agents/rules/00-startup.md` as the canonical source.

## Rules by phase

- Startup: `.agents/rules/00-startup.md`
- Working: `.agents/rules/01-working.md`
- Done criteria: `.agents/rules/02-done.md`
- End of session: `.agents/rules/03-end-of-session.md`
- Escalation: `.agents/rules/04-escalation.md`

## Anti-telephone-game rule

When specialists or subagents contribute, persist their outputs under:

- `.agents/LOGS/agents/<agent-name>/...`

In chat responses, reference stored artifact paths plus a brief summary. Do not rely on memory-only summaries.
