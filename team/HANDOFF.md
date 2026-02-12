# S3 프로젝트 핸드오프 (2026-02-12)

> 이전 AI 세션에서 중단된 작업 인수인계 문서.
> 다음 세션의 AI가 이 문서를 읽고 현재 상태를 파악하면 됨.

---

## 현재 상태 요약

### 완료된 작업

1. **v3.0 아키텍처 전환 완료** — Supabase 제거 → CF-native (D1+DO+Workers+R2+Queues)
   - `workflow.md` v3.0 (835줄, SSoT) ✅
   - `CLAUDE.md` v3.0 (에이전트 가이드) ✅
   - `ARCHITECTURE.md` v3.0 (아키텍처 심화) ✅
   - 디렉토리 전환: `edge/` → `workers/`, `backend/` → `cf-backend/`, `ai/` → `ai-backend/+gpu-worker/`
   - `supabase/` 삭제 완료

2. **Workers 스캐폴딩** (`workers/src/`)
   - 완성: `types.ts`, `errors.ts`, `response.ts`, `presets.data.ts`, `do.helpers.ts`, `wrangler.toml`, `migrations/0001_init.sql`
   - 미구현 (0%): `jwt.ts`, `r2.ts`, `UserLimiterDO.ts`, `JobCoordinatorDO.ts`, 모든 route/service/validator

3. **GPU Worker 스캐폴딩** (`gpu-worker/`)
   - 완성: `presets/interior.py`, `presets/seller.py`, `Dockerfile`, `requirements.txt`
   - 미구현 (0%): `pipeline.py`, `segmenter.py`, `applier.py`, `postprocess.py`, `callback.py`

4. **팀 가이드 생성** (`team/`)
   - `README.md` — 역할 분배 + 타임라인
   - `SETUP.md` — 공통 환경 설정
   - `LEAD.md` — 리드 가이드
   - `MEMBER-A-WORKERS-CORE.md` — Workers Auth/JWT/Presets/Rules
   - `MEMBER-B-WORKERS-DO.md` — Workers DO/Jobs/Queue/R2
   - `MEMBER-C-GPU.md` — GPU Worker SAM3 Engine/Pipeline
   - `MEMBER-D-FRONTEND.md` — Flutter UI + Mock API → 실 API

5. **Auto-Claude 버그 수정 (이번 세션)**
   - `projects/S3/custom_agents/config.json` — v2.0.0 → v3.0.0 업데이트 ✅
   - `spec_runner.py` 라인 299, 312 — `args.no_ai_assessment` → `args.no_ai_cf_backend_assessment` ✅
   - `task_daemon/__init__.py` 라인 691 — `process.wait()` 에 2시간 타임아웃 추가 ✅

---

## 수정된 파일 (이번 세션)

| 파일 | 수정 내용 |
|------|----------|
| `clone/Auto-Claude/projects/S3/custom_agents/config.json` | v2.0.0 → v3.0.0 (Supabase 참조 제거, MCP 서버 추가) |
| `clone/Auto-Claude/apps/backend/runners/spec_runner.py` | 라인 299, 312: AttributeError 버그 수정 |
| `clone/Auto-Claude/apps/backend/services/task_daemon/__init__.py` | 라인 691: process.wait() 타임아웃 추가 |

---

## 미해결 이슈 (다음 세션에서 처리)

### 이슈 1: MCP 서버가 Claude CLI 모드에서 전달 안 됨 (중요도: HIGH)

**문제**: `CLAUDE.md`의 daemon 명령어에 `--use-claude-cli` 플래그가 있음. 이 모드에서는 `executor.py` → `_build_claude_cli_command()`가 호출되는데, MCP 서버 플래그(`--mcp`)를 전혀 전달하지 않음.

**영향**: cloudflare-observability, runpod, dart, flutter-docs 등 모든 MCP 도구 사용 불가.

**파일 위치**:
- `clone/Auto-Claude/apps/backend/services/task_daemon/executor.py` — 라인 413-457
- `AgentConfig.mcp_servers` 필드는 존재하지만 `_build_claude_cli_command()`에서 사용 안 함

**해결 옵션 (택 1)**:

**옵션 A (권장)**: `--use-claude-cli` 제거
- `CLAUDE.md` daemon 명령어에서 `--use-claude-cli` + `--claude-cli-path` 제거
- Auto-Claude backend가 `clone/Auto-Claude/apps/backend/`에 존재하므로 `run.py`가 자동 사용됨
- `run.py`는 `create_client()` → MCP 서버 자동 연결
- 가장 안전하고 MCP 완전 지원

**옵션 B**: executor.py에 MCP 전달 추가
```python
# _build_claude_cli_command()에 추가:
if agent_config and agent_config.mcp_servers:
    for mcp_server in agent_config.mcp_servers:
        cmd.extend(["--mcp", mcp_server])
```

**옵션 C**: 프로젝트 루트에 `.mcp.json` 생성
- Claude CLI가 자동으로 읽는 MCP 설정 파일
- 단, 형식 확인 필요 (Claude Code 공식 문서 참조)

### 이슈 2: Merge 동시성 보호 없음 (중요도: MEDIUM)

**문제**: 여러 워크트리가 동시에 merge하면 충돌 가능. `git add .`이 아티팩트를 포함할 수 있음.

**파일 위치**: merge 로직은 `clone/Auto-Claude/apps/backend/` 내부 (정확한 위치 확인 필요)

**해결**:
- 파일 기반 lock (`flock` 또는 Windows `msvcrt.locking`)을 merge 전에 획득
- `git add .` 대신 특정 파일만 `git add`
- 이건 Auto-Claude 코어 이슈이므로, Auto-Claude 프로젝트에서 수정하는 게 맞음

### 이슈 3: Daemon 명령어 업데이트 필요 (중요도: LOW)

**현재 CLAUDE.md의 daemon 명령어**:
```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py ^
  --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json" ^
  --use-worktrees ^
  --skip-qa ^
  --use-claude-cli ^
  --claude-cli-path "C:\Users\User\.local\bin\claude.exe"
```

**권장 수정** (이슈 1 해결 후):
```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py ^
  --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json" ^
  --use-worktrees ^
  --skip-qa
```
(`--use-claude-cli` + `--claude-cli-path` 제거 → run.py 모드로 전환)

---

## 프로젝트 핵심 파일 경로

### SSoT 문서
| 파일 | 경로 | 역할 |
|------|------|------|
| workflow.md | `C:\DK\S3\workflow.md` | **마스터 SSoT** (835줄, 17섹션) |
| CLAUDE.md | `C:\DK\S3\CLAUDE.md` | Agent 가이드 (v3.0) |
| ARCHITECTURE.md | `C:\DK\S3\ARCHITECTURE.md` | 아키텍처 심화 (v3.0) |

### Workers (입구)
| 파일 | 경로 | 상태 |
|------|------|------|
| types.ts | `C:\DK\S3\workers\src\_shared\types.ts` | 90% (공유 인터페이스) |
| errors.ts | `C:\DK\S3\workers\src\_shared\errors.ts` | 100% |
| response.ts | `C:\DK\S3\workers\src\_shared\response.ts` | 95% |
| presets.data.ts | `C:\DK\S3\workers\src\presets\presets.data.ts` | 100% |
| do.helpers.ts | `C:\DK\S3\workers\src\do\do.helpers.ts` | 100% |
| 0001_init.sql | `C:\DK\S3\workers\migrations\0001_init.sql` | 100% (D1 DDL) |
| wrangler.toml | `C:\DK\S3\workers\wrangler.toml` | 90% |
| index.ts | `C:\DK\S3\workers\src\index.ts` | 10% (선언만) |

### GPU Worker (근육)
| 파일 | 경로 | 상태 |
|------|------|------|
| interior.py | `C:\DK\S3\gpu-worker\presets\interior.py` | 100% |
| seller.py | `C:\DK\S3\gpu-worker\presets\seller.py` | 100% |
| Dockerfile | `C:\DK\S3\gpu-worker\Dockerfile` | 100% |
| main.py | `C:\DK\S3\gpu-worker\main.py` | 구조만 |
| pipeline.py | `C:\DK\S3\gpu-worker\engine\pipeline.py` | 0% |
| segmenter.py | `C:\DK\S3\gpu-worker\engine\segmenter.py` | 0% |

### Auto-Claude
| 파일 | 경로 | 역할 |
|------|------|------|
| config.json (프로젝트) | `C:\DK\S3\clone\Auto-Claude\projects\S3\custom_agents\config.json` | **v3.0 (수정됨)** |
| config.json (앱) | `C:\DK\S3\clone\Auto-Claude\apps\backend\custom_agents\config.json` | v3.2 (정본) |
| spec_runner.py | `C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py` | **버그 수정됨** |
| daemon __init__.py | `C:\DK\S3\clone\Auto-Claude\apps\backend\services\task_daemon\__init__.py` | **타임아웃 추가** |
| executor.py | `C:\DK\S3\clone\Auto-Claude\apps\backend\services\task_daemon\executor.py` | MCP 미전달 이슈 |
| daemon_runner.py | `C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py` | Daemon CLI |
| agent_registry.py | `C:\DK\S3\clone\Auto-Claude\apps\backend\core\agent_registry.py` | 통합 에이전트 레지스트리 |

### 팀 가이드
| 파일 | 경로 |
|------|------|
| README.md | `C:\DK\S3\team\README.md` |
| SETUP.md | `C:\DK\S3\team\SETUP.md` |
| LEAD.md | `C:\DK\S3\team\LEAD.md` |
| MEMBER-A | `C:\DK\S3\team\MEMBER-A-WORKERS-CORE.md` |
| MEMBER-B | `C:\DK\S3\team\MEMBER-B-WORKERS-DO.md` |
| MEMBER-C | `C:\DK\S3\team\MEMBER-C-GPU.md` |
| MEMBER-D | `C:\DK\S3\team\MEMBER-D-FRONTEND.md` |

---

## 다음 단계 (Critical Path)

### 즉시 (Before Coding)
1. **이슈 1 해결**: daemon 명령어에서 `--use-claude-cli` 제거 또는 executor.py MCP 전달 추가
2. **CLAUDE.md 업데이트**: daemon 명령어 수정 반영

### 실제 코딩 시작 순서 (5명 병렬)
```
팀원 A: workers/ → jwt.ts → auth.middleware.ts → auth.route.ts → presets.route.ts → rules.*
팀원 B: workers/ → UserLimiterDO.ts → JobCoordinatorDO.ts → jobs.* → user.route.ts
팀원 C: gpu-worker/ → r2_io.py → callback.py → segmenter.py → applier.py → pipeline.py → runpod adapter
팀원 D: frontend/ → Freezed models → MockApiClient → Auth UI → Palette UI → Upload → Rules → Jobs → Results
리드  : 설계 갭 보완 → types.ts 관리 → PR 리뷰 → index.ts 통합
```

### 설계 갭 (LEAD.md 참고)
- JWT TTL 미정의 → 24h 권장
- HTTP 에러코드 매핑 미완성
- GPU segment→apply 중간 데이터 형식 미정의
- 부분 실패 시 크레딧 환불 정책 미정의

---

## Git 상태 (2026-02-12)

- **브랜치**: `master`
- **최근 커밋**: `5ae8788` (팀 가이드 생성)
- **미커밋**: Auto-Claude 버그 수정 3건 + 이 핸드오프 MD (커밋 예정)

---

## 메모리 파일

- `C:\Users\User\.claude\projects\C--DK-S3\memory\MEMORY.md` — 프로젝트 메모리 (자동 로드)
- `.auto-claude/daemon_status.json` — daemon 상태
- `.auto-claude/specs/` — Auto-Claude 스펙 저장소
