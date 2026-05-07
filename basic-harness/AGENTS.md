# AGENTS.md

[One-sentence project purpose]

## Startup Workflow

Before writing code:

1. **Confirm working directory** with `pwd`
2. **Read this file** completely
3. **Read ARCHITECTURE.md** for system map and hard rules
4. **Run `./init.sh`** to verify environment is healthy
5. **Read `.agents/harness/feature_list.json`** to see current feature state
6. **Optionally review recent commits** with `git log --oneline -5` (if no commits exist yet, continue)

If baseline verification is failing, repair that first before adding new scope.

## Working Rules

- **One feature at a time**: Pick exactly one unfinished feature from `.agents/harness/feature_list.json`
- **Verification required**: Don't claim done without running verification commands
- **Update artifacts**: Before ending session, update `.agents/harness/progress/PROGRESS.md` and `.agents/harness/feature_list.json`
- **Documentation check each iteration**: After each iteration, review whether documentation updates are required. If user-facing behavior, setup, architecture, operations, decisions, or testing expectations changed, update relevant files under `docs/` and keep `docs/README.md` current. If no docs update is needed, record that decision in `.agents/harness/progress/PROGRESS.md`.
- **Stay in scope**: Don't modify files unrelated to the current feature
- **Leave clean state**: Next session must be able to run `./init.sh` immediately

## Required Artifacts

- `AGENTS.md` — Agent workflow and hard rules
- `ARCHITECTURE.md` — Canonical template map and lifecycle
- `init.sh` — Standard startup and verification path
- `.agents/harness/feature_list.json` — Feature state tracker (source of truth)
- `.agents/harness/feature_list.schema.json` — Feature list schema used by `init.sh`
- `.agents/harness/progress/PROGRESS.md` — Session continuity log
- `session-handoff.md` — Optional, for larger sessions

## Definition of Done

A feature is done only when ALL of the following are true:

- [ ] Target behavior is implemented
- [ ] Required verification actually ran (tests / lint / type-check)
- [ ] Evidence recorded in `.agents/harness/feature_list.json` or `.agents/harness/progress/PROGRESS.md`
- [ ] Repository remains restartable from standard startup path

## End of Session

Before ending a session:

1. Update `.agents/harness/progress/PROGRESS.md` with current state
2. Update `.agents/harness/feature_list.json` with new feature status
3. Record any unresolved risks or blockers
4. Commit with descriptive message once work is in safe state
5. Confirm `docs/README.md` still reflects the current documentation index
6. Leave repo clean enough for next session to run `./init.sh` immediately

## Verification Commands

```bash
# Full verification (recommended)
./init.sh
```

## Escalation

If you encounter:
- **Architecture decisions**: Consult [ARCHITECTURE.md] or ask user
- **Unclear requirements**: Ask user and document assumptions in `.agents/harness/progress/PROGRESS.md`
- **Repeated test failures**: Update progress, flag for human review
- **Scope ambiguity**: Re-read `.agents/harness/feature_list.json` for definition of done
