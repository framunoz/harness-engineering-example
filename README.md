# Harness Engineering Examples

This repository is a collection of reusable agent/development harness examples and templates.

## Current examples

- `minimal-harness/` — minimal starter harness with only core files and lightweight validation.
- `progressive-harness/` — fuller harness with additional workflow scaffolding and stricter process structure.

## Directory overview

- `README.md` — repository-level index and usage notes for available harness examples.
- `minimal-harness/` — minimal example/template.
  - `minimal-harness/README.md` — explains the minimal philosophy and usage.
  - `minimal-harness/init.sh` — lightweight validation script.
  - `minimal-harness/.agents/progress/*` — current state, feature list, and history.
- `progressive-harness/` — extended example/template.
  - `progressive-harness/README.md` — repository documentation for understanding this
    example; it is not a required template artifact to copy into consuming
    projects.
  - `progressive-harness/AGENTS.md` — workflow/rules template (includes intentional placeholders such as `[One-sentence project purpose]`).
  - `progressive-harness/ARCHITECTURE.md` — architecture template for consumers to fill in.
  - `progressive-harness/docs/README.md` — docs index template for human-readable project docs.
  - `progressive-harness/init.sh` — local verification script for the harness (run from inside `progressive-harness/`). Details are documented in `progressive-harness/README.md`.
  - `progressive-harness/.agents/progress/feature_list.json` — sample, replaceable feature list entry.
  - `progressive-harness/.agents/progress/CURRENT.md` — live mutable current state.
  - `progressive-harness/.agents/progress/HISTORY.md` — compact append-only session index.

## Try / verify the minimal harness

```bash
cd minimal-harness
./init.sh
```

## Try / verify the progressive harness

```bash
cd progressive-harness
./init.sh
```

In this repository's example, `progressive-harness/` has no `pyproject.toml`, so
Python project tooling is skipped with warnings. See `progressive-harness/README.md`
for the full policy.

## Template usage guidance

- Choose a starting point based on complexity:
  - `minimal-harness/` for simple projects and low process overhead.
  - `progressive-harness/` for projects needing richer workflow artifacts.
- Minimal harness (`minimal-harness/`):
  - Replace placeholders in `AGENTS.md` and `ARCHITECTURE.md`.
  - Replace sample feature content in `.agents/progress/feature_list.json`.
  - No docs folder is required by default.
- Progressive harness (`progressive-harness/`):
  - Replace placeholders in `AGENTS.md` and `ARCHITECTURE.md`.
  - Replace docs templates under `docs/`.
  - Replace sample feature content in `.agents/progress/feature_list.json`.
- Keep these files updated during execution:
  - `.agents/progress/feature_list.json`
  - `.agents/progress/CURRENT.md`
  - `.agents/progress/HISTORY.md`

For details about the progressive harness lifecycle, required artifacts, verification
phases, and Python tooling behavior, read `progressive-harness/README.md`.

## Adding future harness examples

- Add each new harness example as its own top-level folder.
- Update this root `README.md` to include the new example in the index.
