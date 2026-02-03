# Services Module - 24/7 Background Task Daemon

Background services for autonomous task orchestration. Run Auto-Claude without UI for 24/7 headless operation.

## Overview

The services module provides:
- **Task Daemon**: 24/7 background task manager with auto-recovery
- **Service Orchestrator**: Coordinates multiple services
- **Recovery Manager**: Handles stuck task recovery

## Task Daemon

The `TaskDaemon` class watches the `.auto-claude/specs/` folder and automatically executes tasks.

### Features

| Feature | Description |
|---------|-------------|
| **Parallel Execution** | Run multiple tasks concurrently (`--max-concurrent`) |
| **Priority Queue** | Critical tasks execute first |
| **Task Dependencies** | Task B waits for Task A (`depends_on`) |
| **Hierarchical Tasks** | Design tasks spawn child implementation tasks |
| **Git Worktree Isolation** | Parallel tasks run in separate worktrees |
| **Auto-Recovery** | Stuck tasks automatically restart |
| **Claude CLI Integration** | Plan mode for design, headless for 24/7 |

### Quick Start

```bash
cd Auto-Claude/apps/backend

# Basic: Sequential execution
python runners/daemon_runner.py --project-dir "C:\path\to\project"

# Parallel: 4 concurrent tasks with worktree isolation
python runners/daemon_runner.py --project-dir "..." \
    --max-concurrent 4 \
    --use-worktrees

# Full 24/7 Setup
python runners/daemon_runner.py --project-dir "..." \
    --max-concurrent 4 \
    --use-worktrees \
    --status-file daemon_status.json \
    --log-file daemon.log
```

### CLI Options

| Option | Default | Description |
|--------|---------|-------------|
| `--project-dir` | required | Project directory with `.auto-claude/specs/` |
| `--max-concurrent` | 1 | Maximum parallel tasks |
| `--use-worktrees` | false | Git worktree isolation for parallel tasks |
| `--headless` | true | Skip permission prompts (24/7 mode) |
| `--stuck-timeout` | 600 | Seconds before task is stuck |
| `--check-interval` | 60 | Seconds between stuck checks |
| `--max-recovery` | 3 | Recovery attempts before giving up |
| `--status-file` | none | JSON status file for monitoring |
| `--log-file` | none | Log file path |

### Task Types and Execution Modes

| Task Type | Execution Mode | Description |
|-----------|---------------|-------------|
| `design` | Plan Mode | Read-only exploration, creates child tasks |
| `architecture` | Plan Mode | Architecture analysis |
| `impl` | Headless | Standard implementation |
| `test` | Headless | Test execution |
| `integration` | Headless | Integration tasks |

### Task Priority Levels

| Priority | Value | Use Case |
|----------|-------|----------|
| CRITICAL | 0 | Design, architecture tasks |
| HIGH | 1 | Core module implementation |
| NORMAL | 2 | Standard implementation |
| LOW | 3 | Documentation, cleanup |

### Implementation Plan JSON Schema

Tasks are configured via `implementation_plan.json`:

```json
{
  "status": "queue",
  "taskType": "impl",
  "priority": 2,
  "dependsOn": ["001-design"],
  "parentTask": "001-design",
  "xstateState": "backlog"
}
```

### Large Project Workflow

```
1. Design Task (priority: 0, type: design)
   └── Plan mode exploration
   └── Creates child tasks for each module

2. Module Tasks (priority: 1-2, type: impl)
   └── Run in parallel with worktree isolation
   └── Each task has dependencies

3. Integration Task (priority: 2, type: integration)
   └── Waits for all module tasks
   └── Merges and validates
```

### Programmatic Usage

```python
from services import TaskDaemon, create_daemon

# Create daemon
daemon = TaskDaemon(
    project_dir=Path("C:/path/to/project"),
    max_concurrent_tasks=4,
    use_worktrees=True,
    headless_mode=True,
    on_task_complete=lambda spec_id, success: print(f"{spec_id}: {success}"),
)

# Start (blocking)
daemon.start()

# Or get status
status = daemon.get_status()
print(f"Running: {status['stats']['running']}")
print(f"Queued: {status['stats']['queued']}")
```

### Background Execution

**Linux/Mac:**
```bash
nohup python runners/daemon_runner.py --project-dir "..." > daemon.log 2>&1 &
```

**Windows (PowerShell):**
```powershell
Start-Process -NoNewWindow python "runners/daemon_runner.py --project-dir ..."
```

**Windows Service (NSSM):**
```bash
nssm install AutoClaudeDaemon "python.exe" "runners/daemon_runner.py --project-dir ..."
nssm start AutoClaudeDaemon
```

### Monitoring

Check daemon status via status file:
```bash
# Enable status file
python runners/daemon_runner.py --project-dir "..." --status-file status.json

# Monitor
watch cat status.json
```

Status file contains:
- Running tasks with PIDs
- Queued tasks with priorities
- Completed task count
- Configuration settings

## Architecture

```
services/
├── __init__.py          # Module exports
├── task_daemon.py       # Core 24/7 daemon
├── orchestrator.py      # Service coordination
├── recovery.py          # Stuck task recovery
└── context.py           # Service context

runners/
└── daemon_runner.py     # CLI entry point
```

## Claude CLI Integration

The daemon leverages Claude CLI features:

| Feature | Usage |
|---------|-------|
| Plan Mode | `--permission-mode plan` for design tasks |
| Headless | `--dangerously-skip-permissions` for 24/7 |
| Git Worktrees | Complete isolation for parallel tasks |
| Fan-out | Distribute work across Claude sessions |

## Related Files

- `runners/daemon_runner.py` - CLI entry point
- `core/task_event.py` - Task event emission
- `requirements.txt` - `watchdog>=4.0.0` dependency
