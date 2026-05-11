# Minimal Harness

`minimal-harness/` is a basic starter harness with low cognitive load.

> This README is repository-only visual/reference documentation.
> It is excluded from the CLI-installed harness payload.
> The installed minimal harness validated by `init.sh` does not require this file.

## Goal

Provide only the essentials an agent needs to begin and continue work:

- `AGENTS.md` for workflow rules
- `ARCHITECTURE.md` for architecture context
- `.agents/progress/CURRENT.md` for live session state
- `.agents/progress/feature_list.json` for feature tracking
- `init.sh` for quick baseline validation

## Structure

```text
minimal-harness/
├── AGENTS.md
├── ARCHITECTURE.md
├── README.md  (repository-only, excluded from CLI install)
├── init.sh
└── .agents/
    └── progress/
        ├── feature_list.json
        ├── CURRENT.md
        └── HISTORY.md
```

## Verification

Run from this directory:

```bash
./init.sh
```

The script validates required files, validates `feature_list.json` structure, and optionally runs a safe default test command when detectable.

## Minimal vs progressive harness

- `minimal-harness/` keeps only core startup and progress files.
- `progressive-harness/` adds richer structure (rules, templates, memory, and logs) for larger or more formal workflows.
