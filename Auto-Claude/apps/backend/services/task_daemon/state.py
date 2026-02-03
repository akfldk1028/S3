"""
Task Daemon State - State Persistence
=====================================

Handles saving and loading daemon state.

Module maintainability:
- Single responsibility: state persistence
- Atomic file writes
- Recovery count tracking
"""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
from typing import TYPE_CHECKING

from .types import DaemonState, DaemonConfig

if TYPE_CHECKING:
    from logging import Logger


class StateManager:
    """
    Manages daemon state persistence.

    Features:
    - Atomic file writes
    - Recovery count tracking
    - Task completion tracking
    - Error tracking
    """

    def __init__(
        self,
        specs_dir: Path,
        state_file_name: str = DaemonConfig.STATE_FILE_NAME,
        logger: Logger | None = None,
    ):
        """
        Initialize state manager.

        Args:
            specs_dir: Specs directory (.auto-claude/specs/)
            state_file_name: Name of state file
            logger: Logger instance
        """
        self.specs_dir = specs_dir
        self.state_file_name = state_file_name
        self._logger = logger
        self._state = DaemonState()

    def _log(self, level: str, message: str) -> None:
        """Log a message."""
        if self._logger:
            getattr(self._logger, level)(message)

    @property
    def state(self) -> DaemonState:
        """Get current state."""
        return self._state

    def _get_state_file_path(self) -> Path:
        """Get path to state file."""
        return self.specs_dir / self.state_file_name

    def load(self) -> DaemonState:
        """Load state from file."""
        state_file = self._get_state_file_path()

        if not state_file.exists():
            self._state = DaemonState()
            return self._state

        try:
            with open(state_file, encoding="utf-8") as f:
                data = json.load(f)
            self._state = DaemonState.from_dict(data)
            self._log("info", f"State restored: {len(self._state.completed_tasks)} completed tasks")
        except (OSError, json.JSONDecodeError) as e:
            self._log("warning", f"Failed to load state: {e}")
            self._state = DaemonState()

        return self._state

    def save(self) -> bool:
        """Save state to file (atomic write)."""
        state_file = self._get_state_file_path()

        try:
            self._state.last_updated = datetime.now(timezone.utc).isoformat()
            temp_path = state_file.with_suffix(".tmp")

            with open(temp_path, "w", encoding="utf-8") as f:
                json.dump(self._state.to_dict(), f, indent=2)

            temp_path.replace(state_file)
            return True
        except Exception as e:
            self._log("warning", f"Failed to save state: {e}")
            return False

    # -------------------------------------------------------------------------
    # Recovery count management
    # -------------------------------------------------------------------------

    def get_recovery_count(self, spec_id: str) -> int:
        """Get recovery count for a spec."""
        return self._state.recovery_counts.get(spec_id, 0)

    def increment_recovery_count(self, spec_id: str) -> int:
        """Increment and return new recovery count."""
        count = self._state.recovery_counts.get(spec_id, 0) + 1
        self._state.recovery_counts[spec_id] = count
        self.save()
        return count

    def reset_recovery_count(self, spec_id: str) -> None:
        """Reset recovery count for a spec."""
        self._state.recovery_counts.pop(spec_id, None)
        self._state.error_counts.pop(spec_id, None)
        self._state.last_errors.pop(spec_id, None)
        self.save()

    # -------------------------------------------------------------------------
    # Error tracking
    # -------------------------------------------------------------------------

    def record_error(self, spec_id: str, error: str) -> None:
        """Record an error for a spec."""
        self._state.error_counts[spec_id] = (
            self._state.error_counts.get(spec_id, 0) + 1
        )
        self._state.last_errors[spec_id] = error
        self.save()

    def get_last_error(self, spec_id: str) -> str | None:
        """Get last error for a spec."""
        return self._state.last_errors.get(spec_id)

    # -------------------------------------------------------------------------
    # Task completion tracking
    # -------------------------------------------------------------------------

    def mark_completed(self, spec_id: str) -> None:
        """Mark a task as completed."""
        if spec_id not in self._state.completed_tasks:
            self._state.completed_tasks.append(spec_id)
            self.save()

    def is_completed(self, spec_id: str) -> bool:
        """Check if a task is completed."""
        return spec_id in self._state.completed_tasks

    def are_dependencies_met(self, depends_on: list[str]) -> bool:
        """Check if all dependencies are completed."""
        return all(self.is_completed(dep) for dep in depends_on)

    # -------------------------------------------------------------------------
    # Task hierarchy
    # -------------------------------------------------------------------------

    def add_child_task(self, parent_id: str, child_id: str) -> None:
        """Record parent-child relationship."""
        if parent_id not in self._state.task_hierarchy:
            self._state.task_hierarchy[parent_id] = []
        if child_id not in self._state.task_hierarchy[parent_id]:
            self._state.task_hierarchy[parent_id].append(child_id)
            self.save()

    def get_child_tasks(self, parent_id: str) -> list[str]:
        """Get child tasks for a parent."""
        return self._state.task_hierarchy.get(parent_id, [])

    # -------------------------------------------------------------------------
    # Startup tracking
    # -------------------------------------------------------------------------

    def set_started_at(self) -> None:
        """Record daemon start time."""
        self._state.started_at = datetime.now(timezone.utc).isoformat()
        self.save()

    def get_started_at(self) -> str | None:
        """Get daemon start time."""
        return self._state.started_at
