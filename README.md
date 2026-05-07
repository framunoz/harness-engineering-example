# Harness Engineering Examples

This repository is a collection of reusable agent/development harness examples and templates.

## Current examples

- `basic-harness/` — basic Python harness template intended to be copied and adapted by consuming projects.

## Directory overview

- `README.md` — repository-level index and usage notes for available harness examples.
- `basic-harness/` — the current example/template.
  - `basic-harness/AGENTS.md` — workflow/rules template (includes intentional placeholders such as `[One-sentence project purpose]`).
  - `basic-harness/ARCHITECTURE.md` — architecture template for consumers to fill in.
  - `basic-harness/docs/README.md` — docs index template for human-readable project docs.
  - `basic-harness/init.sh` — local verification script for the harness (run from inside `basic-harness/`).
  - `basic-harness/.agents/harness/feature_list.json` — sample, replaceable feature list entry.
  - `basic-harness/.agents/harness/progress/PROGRESS.md` — progress tracking template.

## Try / verify the basic harness

```bash
cd basic-harness
./init.sh
```

In the basic template, a missing `tests/` directory is currently treated as a non-blocking warning.

## Template usage guidance

- Copy `basic-harness/` into your project, or use it as a starting point while bootstrapping.
- Replace intentional placeholders in:
  - `AGENTS.md`
  - `ARCHITECTURE.md`
  - docs files (for example under `docs/`)
  - sample feature content in `.agents/harness/feature_list.json`
- Keep these files updated during execution:
  - `.agents/harness/feature_list.json`
  - `.agents/harness/progress/PROGRESS.md`

## Adding future harness examples

- Add each new harness example as its own top-level folder.
- Update this root `README.md` to include the new example in the index.
