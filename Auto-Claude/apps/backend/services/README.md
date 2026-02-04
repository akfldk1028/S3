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

**Design/Analysis Tasks** (run.py pipeline with MCP tools):
| Task Type | Description | Execution |
|-----------|-------------|-----------|
| `design` | Project/module design, creates child tasks | run.py (MCP: `create_batch_child_specs`) |
| `architecture` | Architecture analysis and design | run.py (MCP tools) |

**Plan Mode Tasks** (Claude CLI `--permission-mode plan`):
| Task Type | Description | Execution |
|-----------|-------------|-----------|
| `planning` | Implementation planning | Claude CLI plan mode |
| `research` | Codebase analysis and investigation | Claude CLI plan mode |
| `review` | Code review | Claude CLI plan mode |

**Implementation Tasks** (run.py Auto-Claude pipeline):
| Task Type | Description | MCP Servers |
|-----------|-------------|-------------|
| `impl` | General implementation | default |
| `frontend` | Frontend development | puppeteer |
| `backend` | Backend development | context7 |
| `database` | Database work | context7 |
| `api` | API development | default |
| `test` | Test execution | default |
| `integration` | Integration tasks | default |
| `docs` | Documentation | default |

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
├── __init__.py              # Public API (re-exports all)
├── task_daemon/             # Modular daemon package
│   ├── __init__.py         # TaskDaemon class (slim orchestration)
│   ├── types.py            # Enums, constants, data classes
│   ├── watcher.py          # File system watching (SpecsWatcher)
│   ├── executor.py         # Task execution (run.py, Claude CLI)
│   └── state.py            # State persistence (StateManager)
├── spec_factory.py          # Programmatic spec creation
├── orchestrator.py          # Service coordination
├── recovery.py              # Recovery utilities
└── context.py               # Service context

runners/
└── daemon_runner.py         # CLI entry point

prompts/
└── design_architect.md      # Design agent prompt
```

### Module Responsibilities

| Module | Responsibility | Lines |
|--------|----------------|-------|
| `types.py` | Enums, constants, data classes | ~200 |
| `watcher.py` | File system watching, debouncing | ~100 |
| `executor.py` | Command building, process spawning | ~200 |
| `state.py` | State persistence, recovery counts | ~150 |
| `__init__.py` | Orchestration, lifecycle | ~400 |

### Benefits of Modular Structure

1. **Single Responsibility**: Each module handles one concern
2. **Easy Testing**: Test individual modules in isolation
3. **Easy Extension**: Add new executors without touching other code
4. **Maintainability**: Smaller files are easier to understand
5. **Reusability**: StateManager can be used elsewhere

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

## Agent Invocation Flow (How Tasks Are Automatically Executed)

**핵심: Daemon이 specs 폴더를 감시하고, status가 "queue"인 task를 자동으로 실행합니다.**

### 전체 흐름도

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          TaskDaemon.start()                              │
│                               │                                          │
│                               ▼                                          │
│                     ┌─────────────────────┐                              │
│                     │  specs 폴더 감시     │  ← watchdog (file watcher)   │
│                     │  (SpecsWatcher)     │                              │
│                     └─────────────────────┘                              │
│                               │                                          │
│                               ▼                                          │
│               implementation_plan.json 변경 감지                          │
│                               │                                          │
│                               ▼                                          │
│              ┌────────────────────────────────┐                           │
│              │  status == "queue"?            │                           │
│              │  + AGENT_REGISTRY 조회         │                           │
│              │  (task_type → AgentConfig)     │                           │
│              └────────────────────────────────┘                           │
│                    │              │              │                        │
│     ┌──────────────┘              │              └──────────────┐         │
│     ▼                             ▼                             ▼         │
│ ┌──────────────────┐  ┌──────────────────────┐  ┌──────────────────┐     │
│ │ Design/Arch      │  │ Plan Mode Tasks      │  │ Implementation   │     │
│ │ (design, arch)   │  │ (research, review,   │  │ (impl, frontend, │     │
│ │                  │  │  planning)           │  │  backend, etc.)  │     │
│ └──────────────────┘  └──────────────────────┘  └──────────────────┘     │
│          │                        │                        │              │
│          ▼                        ▼                        ▼              │
│ ┌──────────────────┐  ┌──────────────────────┐  ┌──────────────────┐     │
│ │ run.py 호출      │  │ Claude CLI 직접      │  │ run.py 호출      │     │
│ │ (Auto-Claude)    │  │ --permission-mode    │  │ (Auto-Claude     │     │
│ │                  │  │ plan                 │  │  agent pipeline) │     │
│ │ create_client()  │  │                      │  │                  │     │
│ │ → MCP server 연결│  │ Read-only 탐색       │  │ planner → coder  │     │
│ │ → MCP tool 사용  │  │ 코드 변경 불가       │  │ → QA → fixer     │     │
│ └──────────────────┘  └──────────────────────┘  └──────────────────┘     │
│          │                        │                        │              │
│          ▼                        ▼                        ▼              │
│  create_batch_child_specs   분석/리뷰 결과            코드 구현 완료      │
│  → 자식 task 자동 생성       작성                                         │
│  → Daemon이 감지 & 실행                                                   │
└──────────────────────────────────────────────────────────────────────────┘
```

### 자동 실행 조건

Task가 자동으로 실행되려면:

| 조건 | 값 | 설명 |
|------|-----|------|
| `status` | `"queue"` 또는 `"backlog"` | 대기 상태여야 함 |
| `dependsOn` | `[]` 또는 모든 의존성 완료 | 선행 task 완료 필요 |
| recovery_count | < max_recovery (기본 3) | 실패 횟수 초과 안됨 |

**자동 실행 안되는 status:**
- `in_progress` - 이미 실행 중
- `human_review` - 사람 검토 대기
- `done`, `completed`, `merged` - 이미 완료
- `error`, `failed` - 실패 상태

### Task Type별 실행 방식

#### Design/Architecture Tasks (run.py + MCP tools)

| Task Type | 실행 방식 | 특징 |
|-----------|----------|------|
| `design` | run.py → create_client() → MCP | `create_batch_child_specs` tool로 자식 task 생성 |
| `architecture` | run.py → create_client() → MCP | 구조 설계 + MCP tool 접근 |

**Design Agent가 할 수 있는 것:**
- 코드 읽기/분석
- `create_batch_child_specs` tool로 자식 task 생성
- MCP server (context7, graphiti 등) 사용
- 전문 프롬프트 (prompt_template) 적용

#### Plan Mode Tasks (Claude CLI)

```python
# types.py에서 정의
PLAN_MODE_TASK_TYPES = {"design", "architecture", "planning", "research", "review"}
```

| Task Type | 실행 방식 | 특징 |
|-----------|----------|------|
| `planning` | Claude CLI `--permission-mode plan` | 구현 계획 수립 |
| `research` | Claude CLI `--permission-mode plan` | 코드베이스 조사 |
| `review` | Claude CLI `--permission-mode plan` | 코드 리뷰 |

**Plan Mode에서 할 수 있는 것:**
- 코드 읽기 (Read)
- 파일 검색 (Glob, Grep)
- 분석 및 계획 작성

**Plan Mode에서 못하는 것:**
- 파일 쓰기/수정
- 명령어 실행 (npm, python 등)
- MCP tool 사용 (auto-claude MCP server 미연결)

#### Implementation Tasks (run.py pipeline)

```python
# 나머지 모든 task type
IMPL_TASK_TYPES = {"impl", "frontend", "backend", "database", "api", "test", "integration", "docs"}
```

| Task Type | 실행 방식 | MCP Servers |
|-----------|----------|-------------|
| `impl` | run.py → Auto-Claude pipeline | default |
| `frontend` | run.py → Auto-Claude pipeline | puppeteer |
| `backend` | run.py → Auto-Claude pipeline | context7 |
| `database` | run.py → Auto-Claude pipeline | context7 |
| `api` | run.py → Auto-Claude pipeline | default |
| `test` | run.py → Auto-Claude pipeline | default |

**Implementation Mode에서:**
- 기존 Auto-Claude agent pipeline 사용
- `planner.py` → `coder.py` → `qa/reviewer.py` → `qa/fixer.py`
- 코드 읽기/쓰기 모두 가능
- 모든 MCP tool 사용 가능 (context7, graphiti 등)

### 코드 레벨 설명

#### executor.py - AGENT_REGISTRY 기반 실행 방식 결정

```python
# executor.py - build_command()
def build_command(self, spec_id, work_dir, execution_mode, task_type="default"):
    agent_config = get_agent_config(task_type)  # AGENT_REGISTRY 조회

    # 1. Agent에 custom script 있으면 → 해당 스크립트 실행
    if agent_config.script:
        return self._build_custom_agent_command(...)

    # 2. Agent가 Claude CLI 강제 → Claude CLI (prompt_template 적용)
    if agent_config.use_claude_cli:
        cmd = self._build_claude_cli_command(..., agent_config)
        return cmd, work_dir

    # 3. Plan mode → Claude CLI
    if execution_mode == ExecutionMode.PLAN:
        cmd = self._build_claude_cli_command(..., agent_config)
        return cmd, work_dir

    # 4. 기본값 → run.py (Auto-Claude pipeline + MCP tools)
    cmd = self._build_run_py_command(...)
    return cmd, self.auto_claude_dir
```

#### __init__.py - task_type 전달

```python
# __init__.py - _start_task()
execution_mode = self._executor.get_execution_mode(queued_task.task_type)
cmd, cwd = self._executor.build_command(
    spec_id, self.project_dir, execution_mode,
    task_type=queued_task.task_type,  # AGENT_REGISTRY 활용
)
```

#### AGENT_REGISTRY - Task Type별 Agent 설정

```python
AGENT_REGISTRY = {
    # Design/Architecture → run.py (MCP tool 접근 필요)
    "design": AgentConfig(use_claude_cli=False, system_prompt="design_architect.md"),
    "architecture": AgentConfig(use_claude_cli=False),

    # Research/Review → Claude CLI plan mode
    "research": AgentConfig(use_claude_cli=True, execution_mode="plan"),
    "review": AgentConfig(use_claude_cli=True, execution_mode="plan"),

    # Implementation → run.py (Auto-Claude pipeline)
    "frontend": AgentConfig(mcp_servers=["puppeteer"]),
    "backend": AgentConfig(mcp_servers=["context7"]),
    "database": AgentConfig(mcp_servers=["context7"]),
    "impl": AgentConfig(),  # default
}
```

### 예시: 대형 프로젝트 (쇼핑몰)

```
.auto-claude/specs/
├── 001-design/               # taskType: design → run.py (MCP tools)
│   └── implementation_plan.json    → create_batch_child_specs로 자식 생성
│
├── 002-database-schema/      # taskType: database, dependsOn: []
│   └── implementation_plan.json    → run.py (Auto-Claude pipeline)
│
├── 003-backend-api/          # taskType: backend, dependsOn: [002]
│   └── implementation_plan.json    → 002 완료 후 실행
│
├── 004-frontend-ui/          # taskType: frontend, dependsOn: [002]
│   └── implementation_plan.json    → 002 완료 후 실행 (003과 병렬)
│
└── 005-integration-tests/    # taskType: integration, dependsOn: [003, 004]
    └── implementation_plan.json    → 003, 004 모두 완료 후 실행
```

## Claude CLI Integration

The daemon leverages Claude CLI features:

| Feature | Usage |
|---------|-------|
| Plan Mode | `--permission-mode plan` for research/review tasks |
| Headless | `--dangerously-skip-permissions` for 24/7 |
| Git Worktrees | Complete isolation for parallel tasks |
| Fan-out | Distribute work across Claude sessions |

## Agent + MCP 연결 아키텍처

### 핵심 설계 결정

Design/Architecture task는 Claude CLI가 아닌 **run.py**를 통해 실행됩니다:

- **run.py 경로**: `create_client()` → auto-claude MCP server 연결 → `create_batch_child_specs` tool 사용 가능
- **Claude CLI 경로**: MCP server 미연결 → `create_batch_child_specs` tool 사용 불가

따라서 자식 task를 생성해야 하는 design/architecture agent는 반드시 run.py를 사용해야 합니다.

### AgentConfig 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `script` | `str \| None` | 커스텀 agent 스크립트 경로 |
| `extra_args` | `list[str]` | 스크립트 추가 인자 |
| `use_claude_cli` | `bool` | Claude CLI 사용 여부 |
| `prompt_template` | `str \| None` | 전문 프롬프트 (변수: `{spec_id}`, `{task}`, `{spec_content}`) |
| `system_prompt` | `str \| None` | 시스템 프롬프트 파일 |
| `execution_mode` | `str \| None` | 실행 모드 오버라이드 |
| `mcp_servers` | `list[str]` | 향후 확장용 MCP 서버 목록 |
| `pre_hook` | `Callable \| None` | 실행 전 훅 |
| `post_hook` | `Callable \| None` | 실행 후 훅 |

### 대형 프로젝트 전체 흐름

```
사용자: "쇼핑몰 앱 만들어줘"
    │
    ▼
Spec 생성 (status: queue, taskType: design, priority: 0)
    │
    ▼
TaskDaemon 감지 → _start_task(task_type="design")
    │
    ├── AGENT_REGISTRY["design"] → AgentConfig(use_claude_cli=False)
    ├── run.py 사용 → create_client(agent_type="planner")
    └── auto-claude MCP server 연결 → create_batch_child_specs 사용 가능
    │
    ▼
Design Agent가 프로젝트 분석 후 child spec 생성:
    ├── 002-database-schema    (priority:0, type:database, depends:[])
    ├── 003-backend-api        (priority:1, type:backend,  depends:[002])
    ├── 004-frontend-ui        (priority:1, type:frontend, depends:[002])
    └── 005-integration-tests  (priority:2, type:integration, depends:[003,004])
    │
    ▼
Daemon이 새 spec 감지 → Queue에 추가 (priority 순)
    │
    ▼
Scheduler 실행:
    T0:  002-database (deps 없음) → START
    T1:  002 완료 → 003 & 004 deps 충족
    T1:  003-backend + 004-frontend → START (병렬)
    T2:  003, 004 완료 → 005 deps 충족
    T2:  005-integration → START
    T3:  005 완료 → ALL COMPLETE
```

## Related Files

- `runners/daemon_runner.py` - CLI entry point
- `core/task_event.py` - Task event emission
- `requirements.txt` - `watchdog>=4.0.0` dependency
