"""
Task Daemon Executor - Task Execution Logic
============================================

Handles building and running task commands.

Module maintainability:
- Separated from daemon orchestration
- Easy to add new execution backends
- Claude CLI and run.py support
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path
from typing import TYPE_CHECKING

from .types import (
    ExecutionMode,
    PLAN_MODE_TASK_TYPES,
)

if TYPE_CHECKING:
    from logging import Logger


class TaskExecutor:
    """
    Builds and executes task commands.

    Supports:
    - Auto-Claude run.py (default)
    - Claude CLI with plan mode
    - Claude CLI with headless mode
    """

    def __init__(
        self,
        project_dir: Path,
        specs_dir: Path,
        auto_claude_dir: Path | None,
        *,
        use_claude_cli: bool = False,
        claude_cli_path: str | None = None,
        headless_mode: bool = True,
        logger: Logger | None = None,
    ):
        """
        Initialize executor.

        Args:
            project_dir: Project directory
            specs_dir: Specs directory (.auto-claude/specs/)
            auto_claude_dir: Auto-Claude backend directory
            use_claude_cli: Use Claude CLI instead of run.py
            claude_cli_path: Custom Claude CLI path
            headless_mode: Enable headless mode for non-plan tasks
            logger: Logger instance
        """
        self.project_dir = project_dir
        self.specs_dir = specs_dir
        self.auto_claude_dir = auto_claude_dir
        self.use_claude_cli = use_claude_cli
        self.claude_cli_path = claude_cli_path or self._find_claude_cli()
        self.headless_mode = headless_mode
        self._logger = logger

    def _log(self, level: str, message: str) -> None:
        """Log a message."""
        if self._logger:
            getattr(self._logger, level)(message)

    def _find_claude_cli(self) -> str | None:
        """Find the Claude CLI executable."""
        candidates = ["claude", "claude.exe"]

        for name in candidates:
            path = shutil.which(name)
            if path:
                return path

        # Windows-specific locations
        if sys.platform == "win32":
            home = Path.home()
            win_paths = [
                home / ".local" / "bin" / "claude.exe",
                home / "AppData" / "Local" / "Programs" / "claude" / "claude.exe",
            ]
            for path in win_paths:
                if path.exists():
                    return str(path)

        return None

    def get_execution_mode(self, task_type: str) -> str:
        """
        Determine execution mode based on task type.

        Plan Mode: design, architecture, planning, research, review
        Headless Mode: impl, frontend, backend, database, api, test, etc.
        """
        if task_type in PLAN_MODE_TASK_TYPES:
            return ExecutionMode.PLAN

        if self.headless_mode:
            return ExecutionMode.HEADLESS

        return ExecutionMode.STANDARD

    def build_command(
        self,
        spec_id: str,
        work_dir: Path,
        execution_mode: str,
    ) -> tuple[list[str] | None, Path]:
        """
        Build the command to run a task.

        Args:
            spec_id: Spec ID
            work_dir: Working directory
            execution_mode: Execution mode (plan, headless, standard)

        Returns:
            Tuple of (command list, working directory for subprocess)
        """
        # For plan mode, prefer Claude CLI
        if execution_mode == ExecutionMode.PLAN and self.claude_cli_path:
            cmd = self._build_claude_cli_command(spec_id, work_dir, execution_mode)
            return cmd, work_dir

        # For explicit Claude CLI mode
        if self.use_claude_cli and self.claude_cli_path:
            cmd = self._build_claude_cli_command(spec_id, work_dir, execution_mode)
            return cmd, work_dir

        # Default: Use run.py
        cmd = self._build_run_py_command(spec_id, work_dir, execution_mode)
        return cmd, self.auto_claude_dir

    def _build_run_py_command(
        self,
        spec_id: str,
        work_dir: Path,
        execution_mode: str,
    ) -> list[str] | None:
        """Build command using Auto-Claude's run.py."""
        if not self.auto_claude_dir:
            return None

        run_script = self.auto_claude_dir / "run.py"
        if not run_script.exists():
            return None

        cmd = [
            sys.executable,
            str(run_script),
            "--spec", spec_id,
            "--project-dir", str(work_dir),
            "--auto-continue",
        ]

        return cmd

    def _build_claude_cli_command(
        self,
        spec_id: str,
        work_dir: Path,
        execution_mode: str,
    ) -> list[str] | None:
        """
        Build command using Claude CLI directly.

        Claude CLI flags:
        - --permission-mode plan: Read-only exploration
        - --dangerously-skip-permissions: Skip all prompts
        - -p "prompt": Headless mode with prompt
        - --output-format stream-json: Streaming JSON output
        """
        if not self.claude_cli_path:
            return None

        spec_dir = self.specs_dir / spec_id
        spec_path = spec_dir / "spec.md"
        requirements_path = spec_dir / "requirements.json"
        plan_path = spec_dir / "implementation_plan.json"

        cmd = [self.claude_cli_path]

        # Add execution mode flags
        if execution_mode == ExecutionMode.PLAN:
            cmd.extend(["--permission-mode", "plan"])
        elif execution_mode == ExecutionMode.HEADLESS:
            cmd.append("--dangerously-skip-permissions")

        # Build prompt
        prompt = self._build_prompt(spec_id, spec_path, requirements_path, plan_path)
        if not prompt:
            return None

        cmd.extend(["-p", prompt])
        cmd.extend(["--output-format", "stream-json"])

        return cmd

    def _build_prompt(
        self,
        spec_id: str,
        spec_path: Path,
        requirements_path: Path,
        plan_path: Path,
    ) -> str | None:
        """Build prompt from spec files."""
        prompt_parts = []

        # Try spec.md
        if spec_path.exists():
            try:
                prompt_parts.append(spec_path.read_text(encoding="utf-8"))
            except Exception:
                pass

        # Try requirements.json
        if requirements_path.exists():
            try:
                requirements = json.loads(requirements_path.read_text(encoding="utf-8"))
                task = requirements.get("task", "")
                if task and task not in str(prompt_parts):
                    prompt_parts.insert(0, f"Task: {task}\n")
            except Exception:
                pass

        # Default prompt if nothing found
        if not prompt_parts:
            prompt_parts.append(f"Implement task: {spec_id}")

        # Add subtask context
        if plan_path.exists():
            try:
                plan = json.loads(plan_path.read_text(encoding="utf-8"))
                subtasks = plan.get("subtasks", [])
                if subtasks:
                    prompt_parts.append(f"\n\nSubtasks to complete: {len(subtasks)}")

                task_type = plan.get("taskType", plan.get("task_type", ""))
                if task_type in ("design", "architecture"):
                    prompt_parts.append(
                        "\n\nAs a Design Agent, analyze the project and use "
                        "create_batch_child_specs tool to create implementation tasks."
                    )
            except Exception:
                pass

        return "\n".join(prompt_parts)

    def spawn_process(
        self,
        cmd: list[str],
        cwd: Path,
    ) -> subprocess.Popen:
        """
        Spawn a subprocess for task execution.

        Args:
            cmd: Command to run
            cwd: Working directory

        Returns:
            Popen object
        """
        return subprocess.Popen(
            cmd,
            cwd=str(cwd),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            stdin=subprocess.DEVNULL,
        )


def find_auto_claude_backend(project_dir: Path) -> Path | None:
    """Find the Auto-Claude backend directory."""
    # Check relative to current file first
    current_file_backend = Path(__file__).parent.parent.parent
    if (current_file_backend / "run.py").exists():
        return current_file_backend.resolve()

    # Check relative to project directory
    candidates = [
        project_dir / "Auto-Claude" / "apps" / "backend",
        project_dir.parent / "Auto-Claude" / "apps" / "backend",
        project_dir.parent.parent / "Auto-Claude" / "apps" / "backend",
    ]

    for candidate in candidates:
        if (candidate / "run.py").exists():
            return candidate.resolve()

    return None
