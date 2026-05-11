# Harness Engineering Examples

This repository is a collection of reusable agent/development harness examples and templates.

## Current examples

- `basic-harness/` — basic harness template intended to be copied and adapted by consuming projects.
  See `basic-harness/README.md` for the detailed explanation of its flow,
  verification phases, and adaptation policy.

## Directory overview

- `README.md` — repository-level index and usage notes for available harness examples.
- `basic-harness/` — the current example/template.
  - `basic-harness/README.md` — repository documentation for understanding this
    example; it is not a required template artifact to copy into consuming
    projects.
  - `basic-harness/AGENTS.md` — workflow/rules template (includes intentional placeholders such as `[One-sentence project purpose]`).
  - `basic-harness/ARCHITECTURE.md` — architecture template for consumers to fill in.
  - `basic-harness/docs/README.md` — docs index template for human-readable project docs.
  - `basic-harness/init.sh` — local verification script for the harness (run from inside `basic-harness/`). Details are documented in `basic-harness/README.md`.
  - `basic-harness/.agents/progress/feature_list.json` — sample, replaceable feature list entry.
  - `basic-harness/.agents/progress/CURRENT.md` — live mutable current state.
  - `basic-harness/.agents/progress/HISTORY.md` — compact append-only session index.

## Try / verify the basic harness

```bash
cd basic-harness
./init.sh
```

In this repository's example, `basic-harness/` has no `pyproject.toml`, so
Python project tooling is skipped with warnings. See `basic-harness/README.md`
for the full policy.

## Template usage guidance

- Copy `basic-harness/` into your project, or use it as a starting point while bootstrapping.
- Replace intentional placeholders in:
  - `AGENTS.md`
  - `ARCHITECTURE.md`
  - docs files (for example under `docs/`)
  - sample feature content in `.agents/progress/feature_list.json`
- Keep these files updated during execution:
  - `.agents/progress/feature_list.json`
  - `.agents/progress/CURRENT.md`
  - `.agents/progress/HISTORY.md`

For details about the basic harness lifecycle, required artifacts, verification
phases, and Python tooling behavior, read `basic-harness/README.md`.

## Adding future harness examples

- Add each new harness example as its own top-level folder.
- Update this root `README.md` to include the new example in the index.
