# Definition of Done

Work is done only when all are true:

1. Target behavior is implemented and integrated.
2. Verification commands ran and results are recorded.
3. Evidence is captured in feature metadata and/or session logs.
4. `.agents/progress/CURRENT.md` reflects final live state for handoff.
5. `.agents/progress/HISTORY.md` has an append-only entry for the session.
6. Supporting logs exist under `.agents/LOGS/sessions/` and specialist logs (if any) under `.agents/LOGS/agents/<agent-name>/`.
7. `./init.sh` remains runnable for the next session.
