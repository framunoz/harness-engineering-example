"""Typer CLI entry point for harness template installation."""

from pathlib import Path

import typer
from rich.console import Console

from harness_cli import __version__
from harness_cli.installer import install_template, list_templates

app = typer.Typer(help="Install harness templates into a project directory.")
console = Console()


@app.command("list")
def list_command() -> None:
    """List available harness templates."""
    for name in list_templates():
        console.print(f"- {name}")


@app.command("version")
def version_command() -> None:
    """Print the CLI version."""
    console.print(__version__)


@app.command("install")
def install_command(
    template: str = typer.Argument(..., help="Template name: minimal or progressive."),
    target: Path = typer.Argument(Path("."), help="Target directory."),
    dry_run: bool = typer.Option(False, "--dry-run", help="Show plan only."),
    force: bool = typer.Option(False, "--force", help="Overwrite conflicting files."),
    backup: bool = typer.Option(
        False,
        "--backup",
        help="Back up overwritten files under .harness-backup/<timestamp>/.",
    ),
) -> None:
    """Install a harness template into the current or target directory."""
    if backup and not force:
        raise typer.BadParameter("--backup requires --force.")

    try:
        result = install_template(
            template,
            target,
            dry_run=dry_run,
            force=force,
            backup=backup,
        )
    except ValueError as exc:
        raise typer.BadParameter(str(exc)) from exc
    except RuntimeError as exc:
        console.print(f"[red]{exc}[/red]")
        raise typer.Exit(code=1) from exc

    prefix = "Would" if dry_run else "Did"
    for path in result.copied:
        console.print(f"{prefix} copy: {path}")
    for path in result.overwritten:
        console.print(f"{prefix} overwrite: {path}")
    for path in result.skipped:
        console.print(f"Skip unchanged: {path}")
    for path in result.conflicts:
        console.print(f"Conflict: {path}")
    for path in result.backups:
        console.print(f"Backup written: {path}")

    if result.conflicts:
        console.print(
            "[yellow]Conflicts found in dry-run. Re-run with --force to overwrite.[/yellow]"
        )
    else:
        console.print("[green]Done.[/green]")
