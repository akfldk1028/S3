#!/usr/bin/env python3
"""
Task Daemon - 24/7 Headless Task Manager for Large-Scale Projects
=================================================================

UI 없이 24/7 백그라운드에서 task를 관리하는 데몬 서비스.
거대한 프로젝트의 설계부터 구현까지 전체 자동화 지원.

Features:
- specs 폴더 watching (implementation_plan.json 변경 감지)
- **병렬 Task 실행** (max_concurrent_tasks 설정)
- **Task 의존성 관리** (depends_on 필드)
- **계층적 Task 지원** (parent_task가 child tasks 자동 생성)
- **우선순위 큐** (priority 필드)
- Stuck task 자동 감지 및 복구 (10분 timeout)
- Daemon 재시작 시 상태 복원
- **Git Worktree 격리** (병렬 실행 시 파일 충돌 방지)
- **Claude CLI Headless 모드** (--dangerously-skip-permissions)
- **Plan 모드 지원** (설계 task는 plan 모드로 실행)

Large Project Workflow:
    1. 설계 Task 생성 (type: "design", priority: 1)
       → Plan 모드로 실행, 아키텍처 분석 및 하위 모듈 정의
    2. 설계 Task가 하위 모듈 Task들 자동 생성
    3. 하위 Task들 병렬 실행 (Git Worktree로 격리)
    4. 모든 Task 완료 시 통합 Task 실행

Claude CLI Integration:
    - Plan mode: 설계/아키텍처 task에서 사용 (read-only 탐색)
    - Headless mode: 24/7 무인 운영 지원
    - Parallel sessions: Git worktree로 완전 격리된 병렬 실행
    - Fan-out pattern: 대규모 프로젝트의 배치 작업 분산

Usage:
    from services.task_daemon import TaskDaemon

    daemon = TaskDaemon(
        project_dir=Path("C:/DK/S3/S3/my-large-project"),
        max_concurrent_tasks=4,  # 병렬 실행 수
        use_worktrees=True,      # Git worktree 격리
        headless_mode=True,      # 무인 운영 모드
    )
    daemon.start()
"""

from __future__ import annotations

import json
import logging
import os
import shutil
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import TYPE_CHECKING, Callable

# Add parent to path for imports
_PARENT_DIR = Path(__file__).parent.parent
if str(_PARENT_DIR) not in sys.path:
    sys.path.insert(0, str(_PARENT_DIR))

# Try to import watchdog for file system watching
try:
    from watchdog.events import FileSystemEvent, FileSystemEventHandler
    from watchdog.observers import Observer

    HAS_WATCHDOG = True
except ImportError:
    HAS_WATCHDOG = False
    Observer = None  # type: ignore
    FileSystemEventHandler = object  # type: ignore
    FileSystemEvent = None  # type: ignore

if TYPE_CHECKING:
    from watchdog.observers import Observer as ObserverType


# =============================================================================
# CONSTANTS & ENUMS
# =============================================================================


class TaskType(str, Enum):
    """Task types for large project orchestration."""
    DESIGN = "design"           # 프로젝트/모듈 설계 → Plan 모드 사용
    ARCHITECTURE = "architecture"  # 아키텍처 설계 → Plan 모드 사용
    IMPLEMENTATION = "impl"     # 구현 → Headless 모드
    TEST = "test"               # 테스트
    INTEGRATION = "integration" # 통합
    DEFAULT = "default"         # 기본


class ExecutionMode(str, Enum):
    """Execution modes for Claude CLI integration."""
    PLAN = "plan"               # Plan mode (read-only exploration)
    HEADLESS = "headless"       # Headless mode (skip permissions)
    STANDARD = "standard"       # Standard interactive mode


class TaskPriority(int, Enum):
    """Task priority levels (lower = higher priority)."""
    CRITICAL = 0    # 최우선 (설계, 아키텍처)
    HIGH = 1        # 높음 (핵심 모듈)
    NORMAL = 2      # 보통 (일반 구현)
    LOW = 3         # 낮음 (문서, 정리)


# Task statuses that should trigger auto-start
QUEUE_STATUSES = frozenset({"queue", "backlog", "queued"})

# Task statuses that indicate task is already running or completed
RUNNING_STATUSES = frozenset({"in_progress", "ai_review", "human_review"})
COMPLETED_STATUSES = frozenset({"done", "completed", "merged", "pr_created"})
ERROR_STATUSES = frozenset({"error", "failed", "stuck"})

# All statuses that should NOT trigger auto-start
NO_START_STATUSES = RUNNING_STATUSES | COMPLETED_STATUSES | ERROR_STATUSES


# =============================================================================
# DATA CLASSES
# =============================================================================


@dataclass
class TaskState:
    """State tracking for a single task."""

    spec_id: str
    spec_dir: Path
    process: subprocess.Popen | None = None
    pid: int | None = None
    started_at: datetime | None = None
    last_update: datetime | None = None
    status: str = "unknown"
    error_count: int = 0
    recovery_count: int = 0
    last_error: str | None = None

    # Large project support
    task_type: str = "default"
    priority: int = TaskPriority.NORMAL
    depends_on: list[str] = field(default_factory=list)
    parent_task: str | None = None
    child_tasks: list[str] = field(default_factory=list)

    # Worktree and execution mode support
    worktree_path: Path | None = None
    execution_mode: str = "standard"

    def is_running(self) -> bool:
        """Check if task process is still running."""
        if self.process is None:
            return False
        return self.process.poll() is None

    def to_dict(self) -> dict:
        """Convert to dictionary for logging/status."""
        return {
            "spec_id": self.spec_id,
            "spec_dir": str(self.spec_dir),
            "pid": self.pid,
            "status": self.status,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "last_update": self.last_update.isoformat() if self.last_update else None,
            "error_count": self.error_count,
            "recovery_count": self.recovery_count,
            "last_error": self.last_error,
            "is_running": self.is_running(),
            "task_type": self.task_type,
            "priority": self.priority,
            "depends_on": self.depends_on,
            "parent_task": self.parent_task,
            "child_tasks": self.child_tasks,
            "worktree_path": str(self.worktree_path) if self.worktree_path else None,
            "execution_mode": self.execution_mode,
        }


@dataclass
class QueuedTask:
    """Task waiting in queue with priority."""
    spec_id: str
    spec_dir: Path
    priority: int = TaskPriority.NORMAL
    task_type: str = "default"
    depends_on: list[str] = field(default_factory=list)
    parent_task: str | None = None
    queued_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def __lt__(self, other: QueuedTask) -> bool:
        """For priority queue sorting (lower priority value = higher priority)."""
        if self.priority != other.priority:
            return self.priority < other.priority
        return self.queued_at < other.queued_at


@dataclass
class DaemonState:
    """Persistent daemon state for recovery across restarts."""

    recovery_counts: dict[str, int] = field(default_factory=dict)
    error_counts: dict[str, int] = field(default_factory=dict)
    last_errors: dict[str, str] = field(default_factory=dict)
    completed_tasks: list[str] = field(default_factory=list)  # For dependency tracking
    task_hierarchy: dict[str, list[str]] = field(default_factory=dict)  # parent -> children
    started_at: str | None = None
    last_updated: str | None = None

    def to_dict(self) -> dict:
        """Convert to dictionary for serialization."""
        return {
            "recovery_counts": self.recovery_counts,
            "error_counts": self.error_counts,
            "last_errors": self.last_errors,
            "completed_tasks": self.completed_tasks,
            "task_hierarchy": self.task_hierarchy,
            "started_at": self.started_at,
            "last_updated": self.last_updated,
        }

    @classmethod
    def from_dict(cls, data: dict) -> DaemonState:
        """Create from dictionary."""
        return cls(
            recovery_counts=data.get("recovery_counts", {}),
            error_counts=data.get("error_counts", {}),
            last_errors=data.get("last_errors", {}),
            completed_tasks=data.get("completed_tasks", []),
            task_hierarchy=data.get("task_hierarchy", {}),
            started_at=data.get("started_at"),
            last_updated=data.get("last_updated"),
        )


# =============================================================================
# EVENT HANDLER
# =============================================================================


class SpecsEventHandler(FileSystemEventHandler):
    """Watchdog event handler for specs folder changes with debouncing."""

    DEBOUNCE_SECONDS = 2.0

    def __init__(self, callback: Callable[[str, Path], None]):
        super().__init__()
        self.callback = callback
        self._last_events: dict[str, float] = {}
        self._lock = threading.Lock()

    def _should_process(self, spec_id: str) -> bool:
        """Check if event should be processed (debouncing)."""
        now = time.time()
        with self._lock:
            last_time = self._last_events.get(spec_id, 0)
            if now - last_time < self.DEBOUNCE_SECONDS:
                return False
            self._last_events[spec_id] = now
            return True

    def on_modified(self, event: FileSystemEvent) -> None:
        if event.is_directory:
            return
        if not event.src_path.endswith("implementation_plan.json"):
            return
        spec_dir = Path(event.src_path).parent
        spec_id = spec_dir.name
        if self._should_process(spec_id):
            self.callback(spec_id, spec_dir)

    def on_created(self, event: FileSystemEvent) -> None:
        if event.is_directory:
            return
        if not event.src_path.endswith("implementation_plan.json"):
            return
        spec_dir = Path(event.src_path).parent
        spec_id = spec_dir.name
        if self._should_process(spec_id):
            self.callback(spec_id, spec_dir)


# =============================================================================
# TASK DAEMON
# =============================================================================


class TaskDaemon:
    """
    24/7 Task Daemon - Headless background task manager for large-scale projects.

    Supports:
    - **Parallel execution**: Run multiple tasks concurrently
    - **Task dependencies**: Task B waits for Task A to complete
    - **Priority queue**: Critical tasks run first
    - **Hierarchical tasks**: Design task creates implementation tasks
    - **Auto recovery**: Stuck tasks are automatically recovered
    """

    # Configuration defaults
    STUCK_TIMEOUT_SECONDS = 600
    CHECK_INTERVAL_SECONDS = 30  # More frequent for better responsiveness
    MAX_RECOVERY_ATTEMPTS = 3
    MAX_CONCURRENT_TASKS = 1  # Default: sequential
    STATE_FILE_NAME = ".daemon_state.json"
    WORKTREE_DIR_NAME = ".worktrees"

    def __init__(
        self,
        project_dir: Path,
        *,
        stuck_timeout: int | None = None,
        check_interval: int | None = None,
        max_recovery: int | None = None,
        max_concurrent_tasks: int | None = None,
        use_worktrees: bool = False,
        headless_mode: bool = True,
        use_claude_cli: bool = False,
        claude_cli_path: str | None = None,
        log_file: Path | None = None,
        on_task_start: Callable[[str], None] | None = None,
        on_task_complete: Callable[[str, bool], None] | None = None,
        on_task_stuck: Callable[[str], None] | None = None,
        on_task_recovered: Callable[[str, int], None] | None = None,
        on_all_tasks_complete: Callable[[], None] | None = None,
    ):
        """
        Initialize Task Daemon.

        Args:
            project_dir: Project directory containing .auto-claude/specs/
            stuck_timeout: Seconds before a task is considered stuck (default: 600)
            check_interval: Seconds between checks (default: 30)
            max_recovery: Maximum recovery attempts per task (default: 3)
            max_concurrent_tasks: Maximum parallel tasks (default: 1)
            use_worktrees: Use git worktrees for parallel isolation (default: False)
            headless_mode: Run in headless mode for 24/7 operation (default: True)
            use_claude_cli: Use Claude CLI directly instead of run.py (default: False)
            claude_cli_path: Custom path to claude CLI executable
            log_file: Optional log file path
            on_task_start: Callback when task starts
            on_task_complete: Callback when task completes (spec_id, success)
            on_task_stuck: Callback when task is permanently stuck
            on_task_recovered: Callback when task is recovered (spec_id, attempt)
            on_all_tasks_complete: Callback when all queued tasks are done
        """
        self.project_dir = Path(project_dir).resolve()
        self.specs_dir = self.project_dir / ".auto-claude" / "specs"
        self.worktrees_dir = self.project_dir / self.WORKTREE_DIR_NAME
        self.auto_claude_dir = self._find_auto_claude_backend()

        # Configuration
        self.stuck_timeout = stuck_timeout or self.STUCK_TIMEOUT_SECONDS
        self.check_interval = check_interval or self.CHECK_INTERVAL_SECONDS
        self.max_recovery = max_recovery or self.MAX_RECOVERY_ATTEMPTS
        self.max_concurrent_tasks = max_concurrent_tasks or self.MAX_CONCURRENT_TASKS

        # Claude CLI integration
        self.use_worktrees = use_worktrees
        self.headless_mode = headless_mode
        self.use_claude_cli = use_claude_cli
        self.claude_cli_path = claude_cli_path or self._find_claude_cli()

        # Callbacks
        self._on_task_start = on_task_start
        self._on_task_complete = on_task_complete
        self._on_task_stuck = on_task_stuck
        self._on_task_recovered = on_task_recovered
        self._on_all_tasks_complete = on_all_tasks_complete

        # State
        self.running_tasks: dict[str, TaskState] = {}
        self.task_queue: list[QueuedTask] = []  # Priority queue
        self._daemon_state = DaemonState()
        self._observer: ObserverType | None = None
        self._checker_thread: threading.Thread | None = None
        self._scheduler_thread: threading.Thread | None = None
        self._stop_event = threading.Event()
        self._lock = threading.RLock()
        self._queue_condition = threading.Condition(self._lock)

        # Logging
        self._setup_logging(log_file)

    def _setup_logging(self, log_file: Path | None) -> None:
        """Setup logging configuration."""
        self._logger = logging.getLogger(f"TaskDaemon-{self.project_dir.name}")
        self._logger.setLevel(logging.DEBUG)

        # Prevent duplicate handlers
        if self._logger.handlers:
            return

        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(
            logging.DEBUG
            if os.environ.get("DEBUG", "").lower() in ("1", "true", "yes")
            else logging.INFO
        )
        console_format = logging.Formatter(
            "[%(asctime)s] [%(levelname)s] %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
        )
        console_handler.setFormatter(console_format)
        self._logger.addHandler(console_handler)

        if log_file:
            file_handler = logging.FileHandler(log_file, encoding="utf-8")
            file_handler.setLevel(logging.DEBUG)
            file_format = logging.Formatter(
                "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s",
                datefmt="%Y-%m-%d %H:%M:%S",
            )
            file_handler.setFormatter(file_format)
            self._logger.addHandler(file_handler)

    def _find_auto_claude_backend(self) -> Path | None:
        """Find the Auto-Claude backend directory."""
        candidates = [
            self.project_dir / "Auto-Claude" / "apps" / "backend",
            self.project_dir.parent / "Auto-Claude" / "apps" / "backend",
            self.project_dir.parent.parent / "Auto-Claude" / "apps" / "backend",
            Path(__file__).parent.parent,
        ]
        for candidate in candidates:
            if (candidate / "run.py").exists():
                return candidate.resolve()
        return None

    def _find_claude_cli(self) -> str | None:
        """Find the Claude CLI executable."""
        import shutil as sh

        # Check common locations
        candidates = [
            "claude",
            "claude.exe",
        ]

        # Try to find in PATH
        for name in candidates:
            path = sh.which(name)
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

    def _get_execution_mode(self, task_type: str) -> str:
        """Determine execution mode based on task type."""
        # Design and architecture tasks use plan mode for exploration
        if task_type in (TaskType.DESIGN, TaskType.ARCHITECTURE, "design", "architecture"):
            return ExecutionMode.PLAN

        # All other tasks use headless mode if enabled
        if self.headless_mode:
            return ExecutionMode.HEADLESS

        return ExecutionMode.STANDARD

    # -------------------------------------------------------------------------
    # Git Worktree Management (for parallel isolation)
    # -------------------------------------------------------------------------

    def _create_worktree(self, spec_id: str) -> Path | None:
        """Create a git worktree for isolated task execution.

        This enables true parallel execution without file conflicts.
        Each task gets its own copy of the repository.
        """
        if not self.use_worktrees:
            return None

        worktree_path = self.worktrees_dir / spec_id

        # Check if worktree already exists
        if worktree_path.exists():
            self._log_debug(f"Worktree already exists: {spec_id}")
            return worktree_path

        # Create worktrees directory
        self.worktrees_dir.mkdir(parents=True, exist_ok=True)

        try:
            # Create a new branch for this task
            branch_name = f"task/{spec_id}"

            # First, try to create the worktree
            result = subprocess.run(
                ["git", "worktree", "add", "-b", branch_name, str(worktree_path)],
                cwd=str(self.project_dir),
                capture_output=True,
                text=True,
            )

            if result.returncode != 0:
                # Branch might already exist, try without -b
                result = subprocess.run(
                    ["git", "worktree", "add", str(worktree_path), branch_name],
                    cwd=str(self.project_dir),
                    capture_output=True,
                    text=True,
                )

            if result.returncode == 0:
                self._log_info(f"Created worktree: {spec_id}", path=str(worktree_path))
                return worktree_path
            else:
                self._log_warning(
                    f"Failed to create worktree: {result.stderr}",
                    spec_id=spec_id,
                )
                return None

        except Exception as e:
            self._log_error(f"Worktree creation error: {e}", spec_id=spec_id)
            return None

    def _cleanup_worktree(self, spec_id: str) -> bool:
        """Remove a git worktree after task completion."""
        if not self.use_worktrees:
            return True

        worktree_path = self.worktrees_dir / spec_id

        if not worktree_path.exists():
            return True

        try:
            # Remove the worktree
            result = subprocess.run(
                ["git", "worktree", "remove", str(worktree_path), "--force"],
                cwd=str(self.project_dir),
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                self._log_info(f"Removed worktree: {spec_id}")

                # Also delete the branch
                branch_name = f"task/{spec_id}"
                subprocess.run(
                    ["git", "branch", "-D", branch_name],
                    cwd=str(self.project_dir),
                    capture_output=True,
                    text=True,
                )
                return True
            else:
                # Try manual cleanup
                if worktree_path.exists():
                    shutil.rmtree(worktree_path, ignore_errors=True)
                return True

        except Exception as e:
            self._log_warning(f"Worktree cleanup error: {e}", spec_id=spec_id)
            # Try manual cleanup
            if worktree_path.exists():
                shutil.rmtree(worktree_path, ignore_errors=True)
            return False

    def _merge_worktree(self, spec_id: str) -> bool:
        """Merge completed worktree changes back to main branch."""
        if not self.use_worktrees:
            return True

        worktree_path = self.worktrees_dir / spec_id
        branch_name = f"task/{spec_id}"

        if not worktree_path.exists():
            return True

        try:
            # Get current branch
            result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=str(self.project_dir),
                capture_output=True,
                text=True,
            )
            main_branch = result.stdout.strip() or "main"

            # Merge the task branch
            result = subprocess.run(
                ["git", "merge", branch_name, "--no-edit", "-m", f"Merge task {spec_id}"],
                cwd=str(self.project_dir),
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                self._log_info(f"Merged worktree: {spec_id} -> {main_branch}")
                return True
            else:
                self._log_warning(
                    f"Worktree merge conflict: {result.stderr}",
                    spec_id=spec_id,
                )
                return False

        except Exception as e:
            self._log_error(f"Worktree merge error: {e}", spec_id=spec_id)
            return False

    # -------------------------------------------------------------------------
    # Logging helpers
    # -------------------------------------------------------------------------

    def _log_extra(self, **kwargs) -> str:
        if not kwargs:
            return ""
        filtered = {k: v for k, v in kwargs.items() if v is not None}
        if not filtered:
            return ""
        return " | " + " ".join(f"{k}={v}" for k, v in filtered.items())

    def _log_debug(self, message: str, **kwargs) -> None:
        self._logger.debug(f"{message}{self._log_extra(**kwargs)}")

    def _log_info(self, message: str, **kwargs) -> None:
        self._logger.info(f"{message}{self._log_extra(**kwargs)}")

    def _log_warning(self, message: str, **kwargs) -> None:
        self._logger.warning(f"{message}{self._log_extra(**kwargs)}")

    def _log_error(self, message: str, **kwargs) -> None:
        self._logger.error(f"{message}{self._log_extra(**kwargs)}")

    # -------------------------------------------------------------------------
    # State persistence
    # -------------------------------------------------------------------------

    def _get_state_file_path(self) -> Path:
        return self.specs_dir / self.STATE_FILE_NAME

    def _load_daemon_state(self) -> None:
        state_file = self._get_state_file_path()
        if not state_file.exists():
            self._daemon_state = DaemonState()
            return
        try:
            with open(state_file, encoding="utf-8") as f:
                data = json.load(f)
            self._daemon_state = DaemonState.from_dict(data)
            self._log_info("Daemon state restored",
                          completed_tasks=len(self._daemon_state.completed_tasks))
        except (OSError, json.JSONDecodeError) as e:
            self._log_warning(f"Failed to load daemon state: {e}")
            self._daemon_state = DaemonState()

    def _save_daemon_state(self) -> None:
        state_file = self._get_state_file_path()
        try:
            self._daemon_state.last_updated = datetime.now(timezone.utc).isoformat()
            temp_path = state_file.with_suffix(".tmp")
            with open(temp_path, "w", encoding="utf-8") as f:
                json.dump(self._daemon_state.to_dict(), f, indent=2)
            temp_path.replace(state_file)
        except Exception as e:
            self._log_warning(f"Failed to save daemon state: {e}")

    def _get_recovery_count(self, spec_id: str) -> int:
        return self._daemon_state.recovery_counts.get(spec_id, 0)

    def _increment_recovery_count(self, spec_id: str) -> int:
        count = self._daemon_state.recovery_counts.get(spec_id, 0) + 1
        self._daemon_state.recovery_counts[spec_id] = count
        self._save_daemon_state()
        return count

    def _reset_recovery_count(self, spec_id: str) -> None:
        self._daemon_state.recovery_counts.pop(spec_id, None)
        self._daemon_state.error_counts.pop(spec_id, None)
        self._daemon_state.last_errors.pop(spec_id, None)
        self._save_daemon_state()

    def _record_error(self, spec_id: str, error: str) -> None:
        self._daemon_state.error_counts[spec_id] = (
            self._daemon_state.error_counts.get(spec_id, 0) + 1
        )
        self._daemon_state.last_errors[spec_id] = error
        self._save_daemon_state()

    def _mark_task_completed(self, spec_id: str) -> None:
        """Mark task as completed for dependency tracking."""
        if spec_id not in self._daemon_state.completed_tasks:
            self._daemon_state.completed_tasks.append(spec_id)
            self._save_daemon_state()

    def _is_task_completed(self, spec_id: str) -> bool:
        """Check if task is completed."""
        return spec_id in self._daemon_state.completed_tasks

    def _are_dependencies_met(self, depends_on: list[str]) -> bool:
        """Check if all dependencies are completed."""
        for dep in depends_on:
            if not self._is_task_completed(dep):
                return False
        return True

    # -------------------------------------------------------------------------
    # Lifecycle
    # -------------------------------------------------------------------------

    def start(self) -> None:
        """Start the daemon (blocking)."""
        if not HAS_WATCHDOG:
            self._log_error("watchdog package not installed")
            raise ImportError("watchdog package required")

        if not self.specs_dir.exists():
            self._log_info(f"Creating specs directory: {self.specs_dir}")
            self.specs_dir.mkdir(parents=True, exist_ok=True)

        if not self.auto_claude_dir:
            self._log_error("Could not find Auto-Claude backend directory")
            raise FileNotFoundError("Auto-Claude backend not found")

        self._log_info(
            "Starting Task Daemon",
            project_dir=str(self.project_dir),
            max_concurrent=self.max_concurrent_tasks,
        )

        self._load_daemon_state()
        self._daemon_state.started_at = datetime.now(timezone.utc).isoformat()
        self._save_daemon_state()

        # Scan and queue existing tasks
        self._scan_existing_tasks()

        # Start components
        self._start_watcher()
        self._start_scheduler()
        self._start_stuck_checker()

        self._log_info("Daemon started, watching specs folder...")

        try:
            while not self._stop_event.is_set():
                self._stop_event.wait(timeout=1.0)
        except KeyboardInterrupt:
            self._log_info("Received interrupt, shutting down...")
            self.stop()

    def stop(self) -> None:
        """Stop the daemon gracefully."""
        self._log_info("Stopping daemon...")
        self._stop_event.set()

        # Wake up scheduler
        with self._queue_condition:
            self._queue_condition.notify_all()

        if self._observer:
            self._observer.stop()
            self._observer.join(timeout=5.0)
            self._observer = None

        if self._checker_thread and self._checker_thread.is_alive():
            self._checker_thread.join(timeout=5.0)

        if self._scheduler_thread and self._scheduler_thread.is_alive():
            self._scheduler_thread.join(timeout=5.0)

        with self._lock:
            for spec_id, state in list(self.running_tasks.items()):
                if state.is_running():
                    self._log_info(f"Stopping task: {spec_id}")
                    self._kill_task(state)

        self._save_daemon_state()
        self._log_info("Daemon stopped")

    def _start_watcher(self) -> None:
        handler = SpecsEventHandler(self._on_spec_change)
        self._observer = Observer()
        self._observer.schedule(handler, str(self.specs_dir), recursive=True)
        self._observer.start()

    def _start_scheduler(self) -> None:
        """Start the task scheduler thread."""
        self._scheduler_thread = threading.Thread(
            target=self._scheduler_loop,
            name="TaskScheduler",
            daemon=True,
        )
        self._scheduler_thread.start()
        self._log_debug("Scheduler started", max_concurrent=self.max_concurrent_tasks)

    def _start_stuck_checker(self) -> None:
        self._checker_thread = threading.Thread(
            target=self._stuck_checker_loop,
            name="StuckChecker",
            daemon=True,
        )
        self._checker_thread.start()

    # -------------------------------------------------------------------------
    # Task discovery and queueing
    # -------------------------------------------------------------------------

    def _scan_existing_tasks(self) -> None:
        """Scan for existing tasks and queue them."""
        if not self.specs_dir.exists():
            return

        self._log_info("Scanning existing specs...")
        queued_count = 0

        for spec_dir in sorted(self.specs_dir.iterdir()):
            if not spec_dir.is_dir() or spec_dir.name.startswith("."):
                continue

            plan_path = spec_dir / "implementation_plan.json"
            if plan_path.exists():
                plan = self._load_plan(spec_dir)
                if plan:
                    status = plan.get("status", "").lower()
                    if status in QUEUE_STATUSES:
                        self._enqueue_task(spec_dir.name, spec_dir, plan)
                        queued_count += 1

        self._log_info(f"Scan complete", queued=queued_count)

    def _on_spec_change(self, spec_id: str, spec_dir: Path) -> None:
        """Handle implementation_plan.json change event."""
        plan = self._load_plan(spec_dir)
        if not plan:
            return

        status = plan.get("status", "").lower()

        self._log_debug(f"Spec change: {spec_id}", status=status)

        with self._lock:
            # Update running task state
            if spec_id in self.running_tasks:
                state = self.running_tasks[spec_id]
                state.last_update = datetime.now(timezone.utc)
                state.status = status
                return

            # Check if already queued
            if any(t.spec_id == spec_id for t in self.task_queue):
                return

            # Queue if eligible
            if self._should_queue_task(status, spec_id):
                self._enqueue_task(spec_id, spec_dir, plan)

    def _should_queue_task(self, status: str, spec_id: str) -> bool:
        """Check if task should be queued."""
        if status in NO_START_STATUSES:
            return False
        if status not in QUEUE_STATUSES:
            return False
        if self._get_recovery_count(spec_id) >= self.max_recovery:
            self._log_warning(f"Skipping (max recovery): {spec_id}")
            return False
        return True

    def _enqueue_task(self, spec_id: str, spec_dir: Path, plan: dict) -> None:
        """Add task to priority queue."""
        # Extract task metadata
        task_type = plan.get("taskType", plan.get("task_type", "default"))
        priority = plan.get("priority", TaskPriority.NORMAL)
        depends_on = plan.get("dependsOn", plan.get("depends_on", []))
        parent_task = plan.get("parentTask", plan.get("parent_task"))

        queued_task = QueuedTask(
            spec_id=spec_id,
            spec_dir=spec_dir,
            priority=priority,
            task_type=task_type,
            depends_on=depends_on,
            parent_task=parent_task,
        )

        with self._queue_condition:
            # Insert maintaining priority order
            self.task_queue.append(queued_task)
            self.task_queue.sort()
            self._queue_condition.notify()

        self._log_info(
            f"Task queued: {spec_id}",
            priority=priority,
            type=task_type,
            depends_on=depends_on if depends_on else None,
        )

    def _load_plan(self, spec_dir: Path) -> dict | None:
        plan_path = spec_dir / "implementation_plan.json"
        if not plan_path.exists():
            return None
        try:
            with open(plan_path, encoding="utf-8") as f:
                return json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            self._log_warning(f"Failed to load plan: {e}")
            return None

    def _update_plan_status(
        self,
        spec_dir: Path,
        status: str,
        xstate_state: str | None = None,
        error_message: str | None = None,
    ) -> bool:
        plan_path = spec_dir / "implementation_plan.json"
        try:
            plan = self._load_plan(spec_dir) or {}
            plan["status"] = status
            plan["updated_at"] = datetime.now(timezone.utc).isoformat()
            if xstate_state:
                plan["xstateState"] = xstate_state
            if error_message:
                plan["lastError"] = error_message
                plan["daemonError"] = error_message
            temp_path = plan_path.with_suffix(".tmp")
            with open(temp_path, "w", encoding="utf-8") as f:
                json.dump(plan, f, indent=2)
            temp_path.replace(plan_path)
            return True
        except Exception as e:
            self._log_error(f"Failed to update plan: {e}")
            return False

    # -------------------------------------------------------------------------
    # Task scheduler (parallel execution)
    # -------------------------------------------------------------------------

    def _scheduler_loop(self) -> None:
        """Main scheduler loop - manages parallel task execution."""
        while not self._stop_event.is_set():
            with self._queue_condition:
                # Wait if at max capacity or queue empty
                while not self._stop_event.is_set():
                    running_count = len(self.running_tasks)

                    if running_count >= self.max_concurrent_tasks:
                        self._queue_condition.wait(timeout=1.0)
                        continue

                    # Find next ready task
                    next_task = self._get_next_ready_task()
                    if next_task:
                        break

                    # No ready tasks, wait for changes
                    self._queue_condition.wait(timeout=1.0)

                if self._stop_event.is_set():
                    break

            # Start the task (outside lock)
            if next_task:
                self._start_task(next_task)

    def _get_next_ready_task(self) -> QueuedTask | None:
        """Get next task that has all dependencies met."""
        for i, task in enumerate(self.task_queue):
            if self._are_dependencies_met(task.depends_on):
                return self.task_queue.pop(i)
        return None

    # -------------------------------------------------------------------------
    # Task execution
    # -------------------------------------------------------------------------

    def _start_task(self, queued_task: QueuedTask) -> bool:
        """Start a build task with worktree isolation and execution mode support."""
        spec_id = queued_task.spec_id
        spec_dir = queued_task.spec_dir

        with self._lock:
            if spec_id in self.running_tasks:
                return False

        if not self.auto_claude_dir and not self.use_claude_cli:
            self._log_error("Auto-Claude backend not found")
            return False

        recovery_count = self._get_recovery_count(spec_id)
        execution_mode = self._get_execution_mode(queued_task.task_type)

        # Create worktree for parallel isolation
        worktree_path = None
        if self.use_worktrees and self.max_concurrent_tasks > 1:
            worktree_path = self._create_worktree(spec_id)
            if worktree_path is None and self.use_worktrees:
                self._log_warning(f"Worktree creation failed, using main directory: {spec_id}")

        # Determine working directory
        work_dir = worktree_path if worktree_path else self.project_dir

        self._log_info(
            f"Starting task: {spec_id}",
            type=queued_task.task_type,
            priority=queued_task.priority,
            mode=execution_mode,
            worktree=str(worktree_path) if worktree_path else None,
            recovery=recovery_count if recovery_count > 0 else None,
        )

        # Build command based on mode
        cmd = self._build_task_command(spec_id, work_dir, execution_mode)
        if cmd is None:
            self._log_error("Failed to build task command")
            return False

        try:
            process = subprocess.Popen(
                cmd,
                cwd=str(self.auto_claude_dir) if not self.use_claude_cli else str(work_dir),
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                stdin=subprocess.DEVNULL,
            )

            state = TaskState(
                spec_id=spec_id,
                spec_dir=spec_dir,
                process=process,
                pid=process.pid,
                started_at=datetime.now(timezone.utc),
                last_update=datetime.now(timezone.utc),
                status="in_progress",
                recovery_count=recovery_count,
                task_type=queued_task.task_type,
                priority=queued_task.priority,
                depends_on=queued_task.depends_on,
                parent_task=queued_task.parent_task,
                worktree_path=worktree_path,
                execution_mode=execution_mode,
            )

            with self._lock:
                self.running_tasks[spec_id] = state

            self._update_plan_status(spec_dir, "in_progress", "coding")

            # Output reader thread
            threading.Thread(
                target=self._read_output,
                args=(spec_id, process),
                name=f"Output-{spec_id}",
                daemon=True,
            ).start()

            if self._on_task_start:
                try:
                    self._on_task_start(spec_id)
                except Exception as e:
                    self._log_warning(f"Callback error: {e}")

            self._log_info(f"Task started: {spec_id}", pid=process.pid, mode=execution_mode)
            return True

        except Exception as e:
            self._log_error(f"Failed to start task: {e}", spec_id=spec_id)
            self._record_error(spec_id, str(e))
            # Cleanup worktree on failure
            if worktree_path:
                self._cleanup_worktree(spec_id)
            return False

    def _build_task_command(
        self,
        spec_id: str,
        work_dir: Path,
        execution_mode: str,
    ) -> list[str] | None:
        """Build the command to run the task based on execution mode.

        Supports:
        - Standard run.py execution
        - Claude CLI with --permission-mode plan (for design tasks)
        - Claude CLI with --dangerously-skip-permissions (for headless)
        """
        # Option 1: Use Claude CLI directly
        if self.use_claude_cli and self.claude_cli_path:
            return self._build_claude_cli_command(spec_id, work_dir, execution_mode)

        # Option 2: Use run.py (default)
        return self._build_run_py_command(spec_id, work_dir, execution_mode)

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
        cmd = [
            sys.executable,
            str(run_script),
            "--spec", spec_id,
            "--project-dir", str(work_dir),
            "--auto-continue",
        ]

        # Add execution mode flags (if supported by run.py)
        if execution_mode == ExecutionMode.PLAN:
            cmd.extend(["--plan-only"])  # Design phase: just create plan
        elif execution_mode == ExecutionMode.HEADLESS:
            cmd.extend(["--headless"])  # Skip interactive prompts

        return cmd

    def _build_claude_cli_command(
        self,
        spec_id: str,
        work_dir: Path,
        execution_mode: str,
    ) -> list[str] | None:
        """Build command using Claude CLI directly.

        This leverages Claude CLI's native features:
        - --permission-mode plan: Read-only exploration
        - --dangerously-skip-permissions: Unattended operation
        """
        if not self.claude_cli_path:
            return None

        # Read the spec to get the task prompt
        spec_dir = self.specs_dir / spec_id
        spec_path = spec_dir / "spec.md"
        plan_path = spec_dir / "implementation_plan.json"

        if not spec_path.exists():
            self._log_warning(f"Spec file not found: {spec_path}")
            return None

        # Build base command
        cmd = [self.claude_cli_path]

        # Add execution mode
        if execution_mode == ExecutionMode.PLAN:
            cmd.extend(["--permission-mode", "plan"])
        elif execution_mode == ExecutionMode.HEADLESS:
            cmd.append("--dangerously-skip-permissions")

        # Add prompt from spec
        try:
            spec_content = spec_path.read_text(encoding="utf-8")
            prompt = f"Implement the following specification:\n\n{spec_content}"

            # If there's an implementation plan, include context
            if plan_path.exists():
                plan = json.loads(plan_path.read_text(encoding="utf-8"))
                if "subtasks" in plan:
                    subtasks = plan.get("subtasks", [])
                    prompt += f"\n\nSubtasks to complete: {len(subtasks)}"

            cmd.extend(["-p", prompt])

        except Exception as e:
            self._log_error(f"Failed to read spec: {e}")
            return None

        # Add output format for structured results
        cmd.extend(["--output-format", "json"])

        return cmd

    def _read_output(self, spec_id: str, process: subprocess.Popen) -> None:
        """Read process output and track updates."""
        worktree_path = None

        try:
            for line in process.stdout:
                line = line.rstrip()
                if line:
                    with self._lock:
                        if spec_id in self.running_tasks:
                            self.running_tasks[spec_id].last_update = datetime.now(timezone.utc)
                    self._log_debug(f"[{spec_id}] {line}")
        except Exception as e:
            self._log_debug(f"Output reader error: {e}")

        return_code = process.wait()
        success = return_code == 0

        self._log_info(
            f"Task completed: {spec_id}",
            return_code=return_code,
            success=success,
        )

        with self._lock:
            if spec_id in self.running_tasks:
                state = self.running_tasks[spec_id]
                state.status = "done" if success else "error"
                worktree_path = state.worktree_path

                if success:
                    self._reset_recovery_count(spec_id)
                    self._mark_task_completed(spec_id)
                    self._update_plan_status(state.spec_dir, "human_review", "human_review")

                    # Check for child tasks created by this task
                    self._scan_for_child_tasks(spec_id)
                else:
                    error_msg = f"Task failed (return code {return_code})"
                    state.error_count += 1
                    state.last_error = error_msg
                    self._record_error(spec_id, error_msg)
                    self._update_plan_status(state.spec_dir, "error", "error", error_msg)

                del self.running_tasks[spec_id]

        # Handle worktree cleanup
        if worktree_path and self.use_worktrees:
            if success:
                # Merge changes back to main branch
                self._merge_worktree(spec_id)
            # Cleanup worktree (regardless of success)
            self._cleanup_worktree(spec_id)

        # Notify scheduler that a slot is free
        with self._queue_condition:
            self._queue_condition.notify()

        if self._on_task_complete:
            try:
                self._on_task_complete(spec_id, success)
            except Exception as e:
                self._log_warning(f"Callback error: {e}")

        # Check if all tasks done
        self._check_all_tasks_complete()

    def _scan_for_child_tasks(self, parent_spec_id: str) -> None:
        """Scan for new tasks created by a parent task."""
        # Look for specs with parent_task matching this task
        for spec_dir in self.specs_dir.iterdir():
            if not spec_dir.is_dir() or spec_dir.name.startswith("."):
                continue
            if spec_dir.name == parent_spec_id:
                continue

            plan = self._load_plan(spec_dir)
            if plan:
                parent = plan.get("parentTask", plan.get("parent_task"))
                status = plan.get("status", "").lower()

                if parent == parent_spec_id and status in QUEUE_STATUSES:
                    # Found a child task, queue it
                    with self._lock:
                        if spec_dir.name not in self.running_tasks:
                            if not any(t.spec_id == spec_dir.name for t in self.task_queue):
                                self._enqueue_task(spec_dir.name, spec_dir, plan)

    def _check_all_tasks_complete(self) -> None:
        """Check if all tasks are complete."""
        with self._lock:
            if len(self.running_tasks) == 0 and len(self.task_queue) == 0:
                self._log_info("All tasks complete!")
                if self._on_all_tasks_complete:
                    try:
                        self._on_all_tasks_complete()
                    except Exception as e:
                        self._log_warning(f"Callback error: {e}")

    # -------------------------------------------------------------------------
    # Stuck task detection and recovery
    # -------------------------------------------------------------------------

    def _stuck_checker_loop(self) -> None:
        while not self._stop_event.is_set():
            self._stop_event.wait(timeout=self.check_interval)
            if self._stop_event.is_set():
                break
            self._check_stuck_tasks()

    def _check_stuck_tasks(self) -> None:
        now = datetime.now(timezone.utc)
        tasks_to_recover: list[tuple[str, TaskState]] = []

        with self._lock:
            for spec_id, state in list(self.running_tasks.items()):
                if not state.is_running():
                    continue
                if state.last_update:
                    elapsed = (now - state.last_update).total_seconds()
                    if elapsed > self.stuck_timeout:
                        self._log_warning(
                            f"Task stuck: {spec_id}",
                            elapsed=int(elapsed),
                        )
                        tasks_to_recover.append((spec_id, state))

        for spec_id, state in tasks_to_recover:
            self._recover_task(spec_id, state)

    def _recover_task(self, spec_id: str, state: TaskState) -> None:
        recovery_count = self._increment_recovery_count(spec_id)

        if recovery_count > self.max_recovery:
            self._log_error(f"Max recovery reached: {spec_id}")
            self._update_plan_status(
                state.spec_dir, "error", "error",
                f"Stuck after {recovery_count} attempts"
            )
            with self._lock:
                self.running_tasks.pop(spec_id, None)
            if self._on_task_stuck:
                try:
                    self._on_task_stuck(spec_id)
                except Exception:
                    pass
            return

        self._log_info(f"Recovering task: {spec_id}", attempt=recovery_count)
        self._kill_task(state)
        time.sleep(5)

        with self._lock:
            self.running_tasks.pop(spec_id, None)

        self._update_plan_status(state.spec_dir, "queue", "backlog")

        # Re-queue with same priority
        plan = self._load_plan(state.spec_dir) or {}
        self._enqueue_task(spec_id, state.spec_dir, plan)

        if self._on_task_recovered:
            try:
                self._on_task_recovered(spec_id, recovery_count)
            except Exception:
                pass

    def _kill_task(self, state: TaskState) -> None:
        if state.process is None:
            return
        try:
            state.process.terminate()
            try:
                state.process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                state.process.kill()
                state.process.wait(timeout=5)
            self._log_info(f"Task killed: {state.spec_id}")
        except Exception as e:
            self._log_error(f"Failed to kill task: {e}")

    # -------------------------------------------------------------------------
    # Status and health
    # -------------------------------------------------------------------------

    def get_status(self) -> dict:
        """Get current daemon status."""
        with self._lock:
            return {
                "project_dir": str(self.project_dir),
                "running": not self._stop_event.is_set(),
                "started_at": self._daemon_state.started_at,
                "config": {
                    "max_concurrent_tasks": self.max_concurrent_tasks,
                    "stuck_timeout": self.stuck_timeout,
                    "check_interval": self.check_interval,
                    "use_worktrees": self.use_worktrees,
                    "headless_mode": self.headless_mode,
                    "use_claude_cli": self.use_claude_cli,
                    "claude_cli_path": self.claude_cli_path,
                },
                "running_tasks": {
                    spec_id: state.to_dict()
                    for spec_id, state in self.running_tasks.items()
                },
                "queued_tasks": [
                    {
                        "spec_id": t.spec_id,
                        "priority": t.priority,
                        "type": t.task_type,
                        "depends_on": t.depends_on,
                    }
                    for t in self.task_queue
                ],
                "completed_tasks": self._daemon_state.completed_tasks,
                "stats": {
                    "running": len(self.running_tasks),
                    "queued": len(self.task_queue),
                    "completed": len(self._daemon_state.completed_tasks),
                },
            }

    def is_healthy(self) -> bool:
        return (
            not self._stop_event.is_set()
            and self._observer is not None
            and self._observer.is_alive()
            and self._scheduler_thread is not None
            and self._scheduler_thread.is_alive()
            and self._checker_thread is not None
            and self._checker_thread.is_alive()
        )

    # -------------------------------------------------------------------------
    # Manual task management
    # -------------------------------------------------------------------------

    def add_task(
        self,
        spec_id: str,
        *,
        priority: int = TaskPriority.NORMAL,
        task_type: str = "default",
        depends_on: list[str] | None = None,
        parent_task: str | None = None,
    ) -> bool:
        """Manually add a task to the queue.

        Useful for programmatic task creation (e.g., design agent creating sub-tasks).
        """
        spec_dir = self.specs_dir / spec_id
        if not spec_dir.exists():
            self._log_error(f"Spec directory not found: {spec_id}")
            return False

        queued_task = QueuedTask(
            spec_id=spec_id,
            spec_dir=spec_dir,
            priority=priority,
            task_type=task_type,
            depends_on=depends_on or [],
            parent_task=parent_task,
        )

        with self._queue_condition:
            if any(t.spec_id == spec_id for t in self.task_queue):
                return False
            if spec_id in self.running_tasks:
                return False

            self.task_queue.append(queued_task)
            self.task_queue.sort()
            self._queue_condition.notify()

        self._log_info(f"Task added: {spec_id}", priority=priority, type=task_type)
        return True

    def cancel_task(self, spec_id: str) -> bool:
        """Cancel a queued or running task."""
        with self._lock:
            # Remove from queue
            self.task_queue = [t for t in self.task_queue if t.spec_id != spec_id]

            # Kill if running
            if spec_id in self.running_tasks:
                state = self.running_tasks[spec_id]
                self._kill_task(state)
                del self.running_tasks[spec_id]
                self._log_info(f"Task cancelled: {spec_id}")
                return True

        return False

    def get_task_status(self, spec_id: str) -> str:
        """Get status of a specific task."""
        with self._lock:
            if spec_id in self.running_tasks:
                return "running"
            if any(t.spec_id == spec_id for t in self.task_queue):
                return "queued"
            if self._is_task_completed(spec_id):
                return "completed"
        return "unknown"


# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================


def create_daemon(project_dir: str | Path, **kwargs) -> TaskDaemon:
    """Create a TaskDaemon instance."""
    return TaskDaemon(Path(project_dir), **kwargs)


# =============================================================================
# CLI
# =============================================================================

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Task Daemon for Large Projects",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Basic daemon for sequential execution
    python task_daemon.py --project-dir /path/to/project

    # Parallel execution with worktree isolation
    python task_daemon.py --project-dir /path/to/project \\
        --max-concurrent 4 --use-worktrees

    # Use Claude CLI directly (experimental)
    python task_daemon.py --project-dir /path/to/project \\
        --use-claude-cli --headless
        """,
    )
    parser.add_argument("--project-dir", type=Path, default=Path.cwd())
    parser.add_argument("--max-concurrent", type=int, default=1,
                        help="Maximum parallel tasks (default: 1)")
    parser.add_argument("--use-worktrees", action="store_true",
                        help="Use git worktrees for parallel isolation")
    parser.add_argument("--headless", action="store_true", default=True,
                        help="Run in headless mode (default: True)")
    parser.add_argument("--use-claude-cli", action="store_true",
                        help="Use Claude CLI directly instead of run.py")
    parser.add_argument("--claude-cli-path", type=str, default=None,
                        help="Custom path to claude CLI executable")
    parser.add_argument("--log-file", type=Path, default=None)
    args = parser.parse_args()

    daemon = TaskDaemon(
        args.project_dir,
        max_concurrent_tasks=args.max_concurrent,
        use_worktrees=args.use_worktrees,
        headless_mode=args.headless,
        use_claude_cli=args.use_claude_cli,
        claude_cli_path=args.claude_cli_path,
        log_file=args.log_file,
    )
    daemon.start()
