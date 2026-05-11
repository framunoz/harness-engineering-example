# AGENTS.md

Minimal harness operating guide.

## Startup sequence (always)

Before starting implementation:

1. Confirm current directory with `pwd`.
2. Read `ARCHITECTURE.md`.
3. Read `.agents/progress/CURRENT.md`.
4. Read `.agents/progress/feature_list.json`.
5. Run `./init.sh`.

If startup checks fail, fix the baseline first.

## Working rules

- Work on one feature at a time.
- Keep at most one feature in `in_progress` status.
- Update `.agents/progress/CURRENT.md` during work so handoff state stays accurate.

## Done criteria

Before marking a feature `done`:

- Behavior is implemented.
- Verification has been executed.
- Evidence and status are updated in `.agents/progress/feature_list.json`.
- Current state and handoff notes are updated in `.agents/progress/CURRENT.md`.

## End of session

At session end:

1. Update `.agents/progress/feature_list.json`.
2. Update `.agents/progress/CURRENT.md`.
3. Optionally append a compact entry to `.agents/progress/HISTORY.md`.
