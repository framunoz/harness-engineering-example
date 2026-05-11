# Startup Rules

## Required startup sequence

1. Confirm working directory with `pwd`.
2. Read `AGENTS.md` for routing.
3. Read `ARCHITECTURE.md` for boundaries and system map.
4. Read `.agents/progress/CURRENT.md` for live state.
5. Read `.agents/progress/feature_list.json` for feature status.
6. Run `./init.sh` before implementation work.

## Read policy

- Always read on startup: `AGENTS.md`, `ARCHITECTURE.md`, `.agents/progress/CURRENT.md`, `.agents/progress/feature_list.json`.
- Read on demand: `.agents/progress/HISTORY.md`, `.agents/LOGS/sessions/*.md`, `.agents/MEMORY/*.md`, and `docs/` files relevant to current scope.

If startup validation fails, fix baseline issues first.
