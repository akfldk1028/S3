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

**Plan Mode Tasks** (Claude CLI `--permission-mode plan`):
| Task Type | Description |
|-----------|-------------|
| `design` | Project/module design, creates child tasks |
| `architecture` | Architecture analysis and design |
| `planning` | Implementation planning |
| `research` | Codebase analysis and investigation |
| `review` | Code review |

**Implementation Tasks** (Claude CLI `--dangerously-skip-permissions`):
| Task Type | Description |
|-----------|-------------|
| `impl` | General implementation |
| `frontend` | Frontend development |
| `backend` | Backend development |
| `database` | Database work |
| `api` | API development |
| `test` | Test execution |
| `integration` | Integration tasks |
| `docs` | Documentation |

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
├── spec_factory.py      # Programmatic spec creation for design agents
├── orchestrator.py      # Service coordination
├── recovery.py          # Stuck task recovery
└── context.py           # Service context

runners/
└── daemon_runner.py     # CLI entry point

prompts/
└── design_architect.md  # Design agent prompt for large projects
```

## Spec Factory (For Large Architecture Projects)

The `SpecFactory` enables design agents to create multiple child specs programmatically:

```python
from services import SpecFactory

factory = SpecFactory(project_dir)

# Single child spec
spec_dir = await factory.create_child_spec(
    parent_spec_id="001-design",
    task_description="Implement user auth module",
    priority=1,
    depends_on=["002-database"],
)

# Batch creation (recommended)
specs = await factory.create_batch_specs(
    parent_spec_id="001-design",
    specs=[
        {"task": "Database schema", "priority": 0},
        {"task": "Backend API", "priority": 1, "depends_on": ["002-database"]},
        {"task": "Frontend UI", "priority": 1, "depends_on": ["002-database"]},
        {"task": "Integration tests", "priority": 2, "depends_on": ["003-backend", "004-frontend"]},
    ]
)
```

### Agent Tools

Design agents have access to these tools via `subtask.py`:

| Tool | Description |
|------|-------------|
| `create_child_spec` | Create single child spec |
| `create_batch_child_specs` | Create multiple specs at once |
| `update_subtask_status` | Update subtask status |

### Large Project Workflow

```
1. User creates "design" task
   └── taskType: "design", priority: 0

2. Design Agent analyzes project
   └── Uses plan mode (read-only exploration)

3. Design Agent calls create_batch_child_specs
   └── Creates N child specs with dependencies

4. Task Daemon picks up child specs
   └── Runs them in parallel (respecting dependencies)

5. All child specs complete
   └── Integration task runs (if configured)
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
