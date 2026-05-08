# Basic Harness

This README documents the `basic-harness/` example in this repository. It is
repository documentation, not part of the harness template that a consuming
project is expected to copy verbatim.

The goal of this harness is to give an agent a small, repeatable operating
environment: startup rules, architecture context, feature state, progress notes,
and a single verification command.

## What belongs to the template

These files are the core template artifacts intended to be copied or adapted by
a consuming project:

- `AGENTS.md` — agent workflow, startup sequence, working rules, and definition
  of done.
- `ARCHITECTURE.md` — architecture map template that the consuming project must
  fill in.
- `init.sh` — standard startup and verification script.
- `.agents/harness/feature_list.json` — source of truth for feature state.
- `.agents/harness/feature_list.schema.json` — schema used by `init.sh` to
  validate the feature list.
- `.agents/harness/progress/PROGRESS.md` — session continuity and progress log.
- `docs/README.md` — documentation index template for the consuming project.

This file, `basic-harness/README.md`, explains the example for this repository
and should not be treated as a required copied artifact.

## Startup flow

The intended agent flow is defined in `AGENTS.md`:

1. Confirm the working directory.
2. Read `AGENTS.md`.
3. Read `ARCHITECTURE.md`.
4. Run `./init.sh`.
5. Read `.agents/harness/feature_list.json`.
6. Optionally review recent commits.

The important principle is that `./init.sh` is the restartability check. A new
session should be able to run it before doing work, and a completed session
should leave the project in a state where the next session can run it again.

## `init.sh` verification phases

`init.sh` currently runs these phases:

1. **Environment** — detects whether `pyproject.toml` exists and, when it does,
   verifies `uv`, runs `uv sync`, activates `.venv`, and checks Python >= 3.9.
2. **Harness base files** — verifies that all required harness files exist. If
   all are present, it prints a single success message; if any are missing, it
   lists each missing file explicitly.
3. **Feature list validation** — validates
   `.agents/harness/feature_list.json` against
   `.agents/harness/feature_list.schema.json` and ensures at most one feature is
   `in_progress`.
4. **Formatting** — runs Black when the project has `pyproject.toml`.
5. **Linting** — runs Ruff when the project has `pyproject.toml`.
6. **Type checking** — runs Pyrefly when the project has `pyproject.toml`.
7. **Tests** — runs pytest when `tests/` and `pyproject.toml` both exist.
8. **Summary** — reports whether the environment is ready.

## Python project detection

`pyproject.toml` is the opt-in signal for Python project tooling.

When `pyproject.toml` exists, `init.sh` enables Python quality gates:

- `uv sync --all-groups --all-extras`
- virtual environment activation through `.venv/bin/activate`
- Python version validation
- Black formatting
- Ruff linting
- Pyrefly type checking
- pytest execution, when `tests/` exists

When `pyproject.toml` does not exist, those project-level Python phases are
skipped with warnings. The script still tries to use system `python3` or
`python` for harness metadata validation, because validating the feature list is
useful even when the copied project is not a Python project.

This keeps the harness usable as a generic starting point while still providing
strong defaults for Python projects.

## Quality commands

The Python quality commands are centralized near the top of `init.sh`:

```bash
FORMAT_CMD=(uv run black --preview --unstable .)
LINT_CMD=(uv run ruff check --output-format grouped .)
TYPECHECK_CMD=(uv run pyrefly check --output-format min-text)
```

The `.` path is intentionally easy to change. Each project can narrow or expand
the target paths depending on its layout.

Formatting is intentionally mutating: Black is allowed to rewrite files so that
agents do not spend tokens manually fixing formatting. The script shows Black's
normal output and then reports which files Black reformatted.

Linting and type checking are non-mutating gates. If either fails, `init.sh`
marks the environment as not ready but continues running later phases so the
operator can see all available failures.

## Feature tracking model

The harness uses `.agents/harness/feature_list.json` as the current feature
state. The schema enforces structure, and `init.sh` adds one workflow rule: at
most one feature can be `in_progress` at a time.

`.agents/harness/progress/PROGRESS.md` complements the feature list with
session-level notes: what changed, what was verified, what remains risky, and
what the next session should know.

## Adapting the harness

When copying this harness into a real project:

1. Replace placeholders in `AGENTS.md` and `ARCHITECTURE.md`.
2. Replace sample feature data in `.agents/harness/feature_list.json`.
3. Decide whether the project uses Python tooling. If it does, add a
   `pyproject.toml` with the required dev tools.
4. Adjust quality command paths in `init.sh` if `.` is too broad or too narrow.
5. Keep `docs/README.md`, the feature list, and progress log updated as work
   evolves.

## Local verification

From this repository:

```bash
cd basic-harness
./init.sh
```

In this example repository, `basic-harness/` currently has no `pyproject.toml`,
so Python project quality gates are skipped with warnings. That is expected.
