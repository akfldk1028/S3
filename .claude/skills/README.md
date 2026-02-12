# S3 Claude Skills & Auto-Claude Agents Guide

> AI가 ?�로??Skills/Agents�??�게 추�??????�도�??�는 가?�드

**반드??먼�? ?�기**: [BEST_PRACTICES.md](BEST_PRACTICES.md) - 공식 문서 기반 최적???�성�?

---

## 목차

1. [개요](#1-개요)
2. [Claude Skills 추�??�기](#2-claude-skills-추�??�기)
3. [Auto-Claude Custom Agents 추�??�기](#3-auto-claude-custom-agents-추�??�기)
4. [Skills + Agents ?�동 ?�턴](#4-skills--agents-?�동-?�턴)
5. [기존 Skills/Agents 목록](#5-기존-skillsagents-목록)
6. [?�장 ?�이?�어](#6-?�장-?�이?�어)

---

## 1. 개요

S3 ?�로?�트????가지 AI ?�장 ?�스?�을 ?�용?�니??

| ?�스??| ?�치 | ?�도 |
|--------|------|------|
| **Claude Skills** | `.claude/skills/` | ?�용??명령??(`/s3-build` ?? |
| **Auto-Claude Agents** | `Auto-Claude/apps/backend/custom_agents/` | ?�문 AI ?�이?�트 |

### 차이??

- **Skills**: ?�용?��? 직접 ?�출?�는 명령?? 간단???�크?�로???�동??
- **Agents**: 복잡???�업???�행?�는 ?�화??AI. Auto-Claude ?�이?�라?�에???�용.

### ?�너지

```
?�용????/s3-feature "기능" ??Skill??분석 ???�절??Agent ?�출
```

---

## 2. Claude Skills 추�??�기

### Step 1: ?�더 ?�성

```powershell
# ???�킬 ?�더 ?�성
$skillName = "s3-newskill"
$basePath = "C:\DK\S3\.claude\skills\$skillName"

New-Item -ItemType Directory -Force -Path "$basePath\scripts"
New-Item -ItemType Directory -Force -Path "$basePath\references"
```

### Step 2: SKILL.md ?�성 (?�수)

```markdown
---
name: s3-newskill
description: ?�킬 ?�명 (10?�어 ?�내)
---

# ?�킬 ?�목

## ?�용�?
\`\`\`
/s3-newskill [?�션]
\`\`\`

## ?�션
- `option1` - ?�명
- `option2` - ?�명

## ?�로?�스

### Step 1: �?번째 ?�계
?�명...

### Step 2: ??번째 ?�계
?�명...

## 명령???�시
\`\`\`bash
# ?�제 ?�행??명령?�들
\`\`\`

## 관??Skills
- `/s3-build` - 빌드
- `/s3-test` - ?�스??
```

### Step 3: ?�크립트 추�? (?�택)

`scripts/` ?�더???�동???�크립트 추�?:

```powershell
# scripts/run.ps1
param([string]$Option = "default")

$ErrorActionPreference = "Stop"

switch ($Option) {
    "option1" { ... }
    "option2" { ... }
    default { ... }
}
```

### Step 4: 참조 문서 추�? (?�택)

`references/` ?�더???�세 문서:
- `troubleshooting.md` - 문제 ?�결
- `examples.md` - ?�용 ?�시
- `api.md` - API 문서

### ?�성??구조

```
.claude/skills/s3-newskill/
?��??� SKILL.md           # ?�수: ?�킬 ?�의
?��??� scripts/
??  ?��??� run.ps1        # ?�택: ?�동???�크립트
?��??� references/
    ?��??� guide.md       # ?�택: 참조 문서
```

---

## 3. Auto-Claude Custom Agents 추�??�기

### Step 1: config.json???�이?�트 추�?

?�일: `C:\DK\S3\Auto-Claude\apps\backend\custom_agents\config.json`

```json
{
  "agents": {
    "기존 ?�이?�트??..": {},

    "s3_new_agent": {
      "prompt_file": "s3_new_agent.md",
      "description": "???�이?�트 ?�명",
      "tools": [
        "Read", "Glob", "Grep",
        "Write", "Edit", "Bash",
        "WebFetch", "WebSearch"
      ],
      "mcp_servers": ["context7", "auto-claude"],
      "thinking_default": "medium"
    }
  }
}
```

### Step 2: ?�롬?�트 ?�일 ?�성

?�일: `C:\DK\S3\Auto-Claude\apps\backend\custom_agents\prompts\s3_new_agent.md`

```markdown
# S3 New Agent

?�신?� S3 ?�로?�트??[??��] ?�문 ?�이?�트?�니??

## ??��
- 주요 책임 1
- 주요 책임 2
- 주요 책임 3

## 기술 ?�택
- **?�어**: Python, Dart
- **?�레?�워??*: Flutter, FastAPI
- **?�구**: [관???�구??

## ?�업 지�?

### 1. 분석 ?�계
1. ?�구?�항 ?�악
2. 기존 코드 분석
3. ?�향 범위 ?�인

### 2. 구현 ?�계
1. ?�요???�일 ?�성/?�정
2. ?�스???�성
3. 문서??

### 3. 검�??�계
1. 코드 ?�질 ?�인
2. ?�스???�행
3. 리뷰 준�?

## 코드 ?�턴

### ?�턴 1: [?�름]
\`\`\`dart
// ?�시 코드
\`\`\`

### ?�턴 2: [?�름]
\`\`\`python
# ?�시 코드
\`\`\`

## 주의?�항
- 중요 ?�항 1
- 중요 ?�항 2

## 출력 ?�식
?�업 ?�료 ???�음 ?�식?�로 보고:
1. ?�정???�일 목록
2. 주요 변경사??
3. ?�음 ?�계 ?�안
```

### Agent ?�정 ?�션

| ?�션 | �?| ?�명 |
|------|-----|------|
| `tools` | 배열 | ?�용 가?�한 ?�구 |
| `mcp_servers` | 배열 | MCP ?�버 ?�결 |
| `thinking_default` | `none`/`low`/`medium`/`high`/`ultrathink` | ?�고 ?��? |

### ?�용 가?�한 Tools

```
기본 ?�기: Read, Glob, Grep
기본 ?�기: Write, Edit, Bash
?? WebFetch, WebSearch
```

### ?�용 가?�한 MCP Servers

```
context7     - 문서 검??
auto-claude  - 빌드 관�?
graphiti     - 메모�??�스??
linear       - ?�로?�트 관�?
```

---

## 4. Skills + Agents ?�동 ?�턴

### ?�턴 A: Skill??Agent ?�출

```markdown
# SKILL.md?�서

## Auto-Claude ?�동

복잡???�업?� ?�문 ?�이?�트 ?�용:

\`\`\`bash
cd C:\DK\S3\Auto-Claude\apps\backend
.venv\Scripts\python.exe run.py --task "[?�업 ?�용]"
\`\`\`

### 추천 ?�이?�트
| ?�업 | ?�이?�트 |
|------|---------|
| ?�증 구현 | s3_backend_auth |
| ?�이??처리 | s3_backend_data |
```

### ?�턴 B: Skill ??Python ?�크립트�??�동

```python
# scripts/invoke_agent.py
import subprocess

def invoke_agent(agent_type: str, task: str):
    cmd = [
        "C:/DK/S3/clone/Auto-Claude/apps/cf-backend/.venv/Scripts/python.exe",
        "C:/DK/S3/clone/Auto-Claude/apps/cf-backend/run.py",
        "--agent", agent_type,
        "--task", task,
    ]
    return subprocess.run(cmd, capture_output=True, text=True)
```

### ?�턴 C: Feature�?Agent 매핑

```
/s3-feature "?�증" ??s3_backend_auth + s3_frontend_auth
/s3-feature "?�이?? ??s3_backend_data + s3_frontend_data
/s3-feature "AI" ??s3_ai_assistant + s3_ai_analyzer
```

---

## 5. 기존 Skills/Agents 목록

### Claude Skills (5�?

| ?�름 | 명령??| ?�도 |
|------|--------|------|
| s3-auto-task | `/s3-auto-task "?�명"` | Auto-Claude task ?�성/빌드 |
| s3-build | `/s3-build [target]` | 빌드 ?�동??|
| s3-test | `/s3-test [scope]` | ?�스???�행 |
| s3-feature | `/s3-feature "?�명"` | 기능 개발 ?�크?�로??|
| s3-deploy | `/s3-deploy [target]` | 배포 ?�동??|

### Auto-Claude Custom Agents (8�?

| ?�름 | ?�명 |
|------|------|
| s3_backend_auth | Backend ?�증 (JWT, OAuth, Session) |
| s3_backend_data | Backend ?�이??(CRUD, Query, Cache) |
| s3_backend_notification | Backend ?�림 (Push, Email, SMS) |
| s3_ai_assistant | AI ?�시?�턴??(LLM 기반) |
| s3_ai_analyzer | AI 분석�?(?�이??분석, ?�약) |
| s3_ai_recommender | AI 추천 ?�스??|
| s3_frontend_auth | Frontend ?�증 UI (Flutter) |
| s3_frontend_data | Frontend ?�이???�기??(Flutter) |

---

## 6. ?�장 ?�이?�어

### 추�???만한 Skills

| ?�름 | 명령??| ?�도 |
|------|--------|------|
| s3-db | `/s3-db [action]` | DB 마이그레?�션 관�?|
| s3-api | `/s3-api [action]` | API 문서 ?�성/검�?|
| s3-docs | `/s3-docs [target]` | 문서 ?�동 ?�성 |
| s3-lint | `/s3-lint [target]` | 코드 린트 �??�맷 |
| s3-perf | `/s3-perf [target]` | ?�능 분석 |
| s3-security | `/s3-security` | 보안 ?�캔 |

### 추�???만한 Agents

| ?�름 | ?�도 |
|------|------|
| s3_backend_cache | Redis/Memcached 캐싱 |
| s3_backend_queue | 메시지 ??(RabbitMQ, Kafka) |
| s3_backend_file | ?�일 ?�로???�토리�? |
| s3_ai_vision | ?��?지/비디??분석 |
| s3_ai_voice | ?�성 ?�식/?�성 |
| s3_frontend_animation | ?�니메이??구현 |
| s3_frontend_chart | 차트/그래??구현 |
| s3_devops_ci | CI/CD ?�이?�라??|
| s3_devops_monitor | 모니?�링/로깅 |

---

## 빠른 참조: ??Skill/Agent 추�? 체크리스??

### Skill 추�? 체크리스??

- [ ] `.claude/skills/[name]/` ?�더 ?�성
- [ ] `SKILL.md` ?�성 (frontmatter + 지�?
- [ ] (?�택) `scripts/` ?�동???�크립트
- [ ] (?�택) `references/` 참조 문서
- [ ] ??README??목록 추�?

### Agent 추�? 체크리스??

- [ ] `custom_agents/config.json`???�이?�트 추�?
- [ ] `custom_agents/prompts/[name].md` ?�롬?�트 ?�성
- [ ] ??README??목록 추�?
- [ ] (?�택) 관??Skill?�서 ?�동 추�?

---

## ?�일 경로 ?�약

```
C:\DK\S3\
?��??� .claude\
??  ?��??� skills\                              # Claude Skills
??      ?��??� README.md                        # ???�일
??      ?��??� s3-build\SKILL.md
??      ?��??� s3-test\SKILL.md
??      ?��??� s3-feature\SKILL.md
??      ?��??� s3-deploy\SKILL.md
??
?��??� Auto-Claude\apps\backend\
    ?��??� custom_agents\                       # Auto-Claude Agents
        ?��??� config.json                      # ?�이?�트 ?�정
        ?��??� prompts\                         # ?�이?�트 ?�롬?�트
            ?��??� s3_backend_auth.md
            ?��??� s3_backend_data.md
            ?��??� s3_backend_notification.md
            ?��??� s3_ai_assistant.md
            ?��??� s3_ai_analyzer.md
            ?��??� s3_ai_recommender.md
            ?��??� s3_frontend_auth.md
            ?��??� s3_frontend_data.md
```

---

*??문서??AI가 S3 ?�로?�트�??�장????참조?�는 가?�드?�니??*
*??Skill?�나 Agent 추�? ????문서???�께 ?�데?�트?�주?�요.*
