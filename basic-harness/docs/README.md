# docs/README.md

This directory stores human-readable project documentation.

`docs/README.md` is the documentation index and must remain current whenever documents are added, removed, or materially changed.

## Purpose

- Provide a single entry point to project documentation.
- Help contributors find user-facing and operational guidance quickly.
- Keep documentation structure explicit and maintainable.

## Optional Documents (create when needed)

The following documents are examples of files that may be added to `docs/` if relevant to the consuming project:

- `PRODUCT.md` — Product goals, scope, and user-facing behavior.
- `SETUP.md` — Local development setup and environment requirements.
- `DECISIONS.md` — Architecture Decision Records (ADRs) or key technical decisions.
- `TESTING.md` — Testing strategy, commands, and expected quality gates.
- `OPERATIONS.md` — Runtime operations, runbooks, deployment, and incident guidance.
- `API.md` — Public API contracts, request/response formats, and versioning notes.
- `SECURITY.md` — Security controls, threat model notes, and disclosure process.
- `TROUBLESHOOTING.md` — Common issues and known fixes.

Only add documents that are needed; avoid placeholder files with no useful content.

## Maintenance Rules

- Keep this index accurate.
- When project changes affect behavior, setup, architecture, operations, decisions, or testing expectations, update relevant docs under `docs/`.
- If no documentation update is needed for a change, record that decision in `.agents/progress/CURRENT.md` or the active session log under `.agents/LOGS/sessions/`.
