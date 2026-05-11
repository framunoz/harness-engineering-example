"""Install bundled harness templates into a target directory."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
import filecmp
from pathlib import Path
import shutil

from importlib.resources import files


TemplateName = str

TEMPLATE_FILES: dict[str, list[str]] = {
    "minimal": [
        "AGENTS.md",
        "ARCHITECTURE.md",
        "init.sh",
        ".agents/progress/CURRENT.md",
        ".agents/progress/HISTORY.md",
        ".agents/progress/feature_list.json",
    ],
    "progressive": [
        "AGENTS.md",
        "ARCHITECTURE.md",
        "init.sh",
        "docs/README.md",
        ".agents/progress/CURRENT.md",
        ".agents/progress/HISTORY.md",
        ".agents/progress/feature_list.json",
        ".agents/progress/feature_list.schema.json",
        ".agents/rules/00-startup.md",
        ".agents/rules/01-working.md",
        ".agents/rules/02-done.md",
        ".agents/rules/03-end-of-session.md",
        ".agents/rules/04-escalation.md",
        ".agents/templates/agent-log.md",
        ".agents/templates/current.md",
        ".agents/templates/decision.md",
        ".agents/templates/handoff.md",
        ".agents/templates/history-entry.md",
        ".agents/templates/pattern.md",
        ".agents/templates/session-log.md",
        ".agents/templates/user.md",
        ".agents/MEMORY/DECISIONS.md",
        ".agents/MEMORY/PATTERNS.md",
        ".agents/MEMORY/USER.md",
        ".agents/LOGS/sessions/.gitkeep",
        ".agents/LOGS/agents/.gitkeep",
    ],
}


@dataclass
class InstallResult:
    """Holds installation planning/execution results for CLI rendering."""

    copied: list[Path]
    overwritten: list[Path]
    skipped: list[Path]
    conflicts: list[Path]
    backups: list[Path]


def list_templates() -> list[str]:
    """Return available template names."""
    return ["minimal", "progressive"]


def _existing_non_symlink_parents(path: Path, stop_at: Path) -> list[Path]:
    """Return existing parent paths between ``path`` and ``stop_at`` (exclusive)."""
    parents: list[Path] = []
    current = path.parent
    while current != stop_at and current != current.parent:
        if current.exists() or current.is_symlink():
            parents.append(current)
        current = current.parent
    return parents


def _resolve_source_root(template: str) -> Path:
    """Resolve packaged template path with a repo fallback for editable installs."""
    source_root = Path(str(files("harness_cli") / "templates" / template))
    if source_root.exists():
        return source_root
    repo_root = Path(__file__).resolve().parents[2]
    source_root = repo_root / f"{template}-harness"
    if source_root.exists():
        return source_root
    raise RuntimeError(f"Template source not found for: {template}")


def install_template(
    template: TemplateName,
    target: Path,
    *,
    dry_run: bool = False,
    force: bool = False,
    backup: bool = False,
) -> InstallResult:
    """Install a bundled template into ``target``.

    Args:
        template: Template name, either ``minimal`` or ``progressive``.
        target: Destination directory for copied files.
        dry_run: If true, only computes actions.
        force: If true, overwrite conflicting files.
        backup: If true, back up overwritten files under ``.harness-backup``.

    Raises:
        ValueError: If template name is invalid.
        RuntimeError: If conflicts are found without ``force``.
    """
    if template not in list_templates():
        raise ValueError(f"Unknown template: {template}")

    source_root = _resolve_source_root(template)

    if not dry_run:
        target.mkdir(parents=True, exist_ok=True)
    backup_root = target / ".harness-backup" / datetime.now().strftime("%Y%m%d-%H%M%S")

    copied: list[Path] = []
    overwritten: list[Path] = []
    skipped: list[Path] = []
    conflicts: list[Path] = []
    backups: list[Path] = []

    plan: list[tuple[Path, Path, str]] = []
    unsafe_paths: list[Path] = []
    for rel_str in TEMPLATE_FILES[template]:
        rel = Path(rel_str)
        src = source_root / rel
        dst = target / rel

        for parent in _existing_non_symlink_parents(dst, target):
            if parent.is_symlink() or not parent.is_dir():
                unsafe_paths.append(parent.relative_to(target))

        if dst.is_symlink():
            unsafe_paths.append(rel)
            continue

        if dst.exists() and not dst.is_file():
            unsafe_paths.append(rel)
            continue

        if not dst.exists():
            plan.append((src, dst, "copy"))
            continue
        if filecmp.cmp(src, dst, shallow=False):
            plan.append((src, dst, "skip"))
        else:
            plan.append((src, dst, "overwrite" if force else "conflict"))

    if unsafe_paths:
        unique = sorted({str(path) for path in unsafe_paths})
        paths = "\n - ".join(unique)
        raise RuntimeError(
            "Unsafe destination paths detected. Installer only writes regular files and "
            "requires directory parents.\n - "
            f"{paths}"
        )

    for _, dst, action in plan:
        rel_dst = dst.relative_to(target)
        if action == "skip":
            skipped.append(rel_dst)
        elif action == "conflict":
            conflicts.append(rel_dst)

    if conflicts:
        if dry_run:
            return InstallResult(
                copied=[dst.relative_to(target) for _, dst, action in plan if action == "copy"],
                overwritten=[
                    dst.relative_to(target) for _, dst, action in plan if action == "overwrite"
                ],
                skipped=skipped,
                conflicts=conflicts,
                backups=backups,
            )
        conflict_paths = "\n - ".join(str(path) for path in conflicts)
        raise RuntimeError(
            "Conflicts detected. Re-run with --force to overwrite conflicting files:\n - "
            f"{conflict_paths}"
        )

    for src, dst, action in plan:
        rel_dst = dst.relative_to(target)
        if action == "skip":
            continue
        if dry_run:
            if action == "overwrite":
                overwritten.append(rel_dst)
            else:
                copied.append(rel_dst)
            continue

        dst.parent.mkdir(parents=True, exist_ok=True)
        if action == "overwrite":
            if backup:
                backup_file = backup_root / rel_dst
                backup_file.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(dst, backup_file)
                backups.append(backup_file.relative_to(target))
            overwritten.append(rel_dst)
        else:
            copied.append(rel_dst)

        shutil.copy2(src, dst)
        if src.name == "init.sh":
            dst.chmod(dst.stat().st_mode | 0o111)

    return InstallResult(
        copied=copied,
        overwritten=overwritten,
        skipped=skipped,
        conflicts=conflicts,
        backups=backups,
    )
