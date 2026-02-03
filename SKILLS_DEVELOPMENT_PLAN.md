# Claude Skills + Auto-Claude 통합 개발 계획

> **AI 확장 가이드**: 이 문서는 AI가 S3 프로젝트의 Skills와 Agents를 확장할 때 참조하는 마스터 문서입니다.

---

## Quick Reference: AI가 확장할 때 참조

### 새 Skill 추가 (3단계)

```bash
# 1. 폴더 생성
mkdir -p "C:/DK/S3/S3/.claude/skills/s3-newskill/scripts"
mkdir -p "C:/DK/S3/S3/.claude/skills/s3-newskill/references"

# 2. SKILL.md 작성 (아래 템플릿 사용)

# 3. README 업데이트
# → .claude/skills/README.md 에 목록 추가
```

### 새 Agent 추가 (2단계)

```bash
# 1. config.json에 에이전트 추가
# → Auto-Claude/apps/backend/custom_agents/config.json

# 2. 프롬프트 파일 생성
# → Auto-Claude/apps/backend/custom_agents/prompts/s3_new_agent.md
```

### 상세 가이드 문서

| 문서 | 경로 | 내용 |
|------|------|------|
| Skills README | `.claude/skills/README.md` | Skills 추가 상세 가이드 |
| Agents README | `Auto-Claude/apps/backend/custom_agents/README.md` | Agents 추가 상세 가이드 |

---

## 현재 구현 상태

### ✅ 완료된 Skills (4개)
- [x] s3-build - 빌드 자동화
- [x] s3-test - 테스트 실행
- [x] s3-feature - 기능 개발 워크플로우
- [x] s3-deploy - 배포 자동화

### ✅ 완료된 Agents (8개)
- [x] s3_backend_auth, s3_backend_data, s3_backend_notification
- [x] s3_ai_assistant, s3_ai_analyzer, s3_ai_recommender
- [x] s3_frontend_auth, s3_frontend_data

### 📋 추가 예정 (아이디어)
- [ ] s3-db - 데이터베이스 마이그레이션
- [ ] s3-api - API 문서 생성
- [ ] s3-lint - 코드 린트
- [ ] s3_backend_cache, s3_backend_queue, s3_ai_vision 등

---

## 1. Claude Skills 개요

### Skills란?
- **SKILL.md** 파일로 정의되는 재사용 가능한 명령어 세트
- `.claude/skills/` 폴더에 저장 (프로젝트별 또는 사용자별)
- YAML frontmatter + Markdown 구조
- Progressive Disclosure: 필요에 따라 점진적 정보 제공

### Skills 구조
```
.claude/
└── skills/
    ├── my-skill/
    │   ├── SKILL.md           # 스킬 정의 (필수)
    │   ├── scripts/           # 스크립트 파일들
    │   │   └── setup.sh
    │   ├── references/        # 참조 문서
    │   │   └── api-spec.md
    │   └── assets/            # 이미지, 데이터 등
    │       └── diagram.png
    └── another-skill/
        └── SKILL.md
```

### SKILL.md 형식
```markdown
---
name: my-skill
description: 스킬 설명 (10단어 이내)
---

# 스킬 지침

여기에 Claude가 따라야 할 지침 작성...
```

---

## 2. Auto-Claude와의 통합 전략

### 현재 Auto-Claude 구조
```
Auto-Claude/
├── apps/backend/
│   ├── agents/               # 에이전트 로직
│   ├── prompts/              # 에이전트 프롬프트 (.md)
│   └── custom_agents/        # S3 커스텀 에이전트
│       ├── config.json       # 에이전트 설정
│       └── prompts/          # 커스텀 프롬프트
└── .claude/
    └── commands/             # Claude Code 명령어
```

### 통합 아키텍처
```
S3 Project/
├── .claude/
│   ├── skills/               # Claude Skills (NEW)
│   │   ├── s3-build/         # 빌드 자동화
│   │   ├── s3-deploy/        # 배포 자동화
│   │   ├── s3-test/          # 테스트 실행
│   │   └── s3-feature/       # 기능 개발 워크플로우
│   └── settings.local.json
├── Auto-Claude/
│   └── apps/backend/
│       └── custom_agents/    # 커스텀 에이전트 (기존)
└── frontend/                 # Flutter 앱
```

### 시너지 포인트

| Claude Skills | Auto-Claude Agents | 연결점 |
|--------------|-------------------|--------|
| `/s3-feature` 명령 | s3_backend_*, s3_frontend_* | Skills가 적절한 Agent 호출 |
| `/s3-build` 명령 | planner, coder | Auto-Claude 빌드 파이프라인 트리거 |
| `/s3-test` 명령 | qa_reviewer, qa_fixer | QA 에이전트 활용 |
| `/s3-deploy` 명령 | - | 배포 스크립트 실행 |

---

## 3. S3 프로젝트 Skills 설계

### Skill 1: s3-feature (기능 개발)
```yaml
name: s3-feature
description: S3 기능 개발 워크플로우
```
**역할:**
- 사용자가 `/s3-feature "사용자 인증"` 실행
- 자동으로 필요한 파일 구조 분석
- Backend/Frontend 작업 분배
- Auto-Claude의 custom agents 활용

### Skill 2: s3-build (빌드 자동화)
```yaml
name: s3-build
description: Flutter + Backend 빌드 자동화
```
**역할:**
- Flutter 빌드 (`flutter build`)
- Backend 빌드 검증
- 코드 생성 (`build_runner`)
- 빌드 에러 자동 수정

### Skill 3: s3-test (테스트 실행)
```yaml
name: s3-test
description: 통합 테스트 실행 및 분석
```
**역할:**
- Flutter 테스트 (`flutter test`)
- Backend pytest
- 테스트 결과 분석
- 실패 테스트 자동 수정 제안

### Skill 4: s3-deploy (배포)
```yaml
name: s3-deploy
description: 웹/모바일 배포 자동화
```
**역할:**
- Flutter web 빌드 및 배포
- APK/IPA 빌드
- 환경별 설정 관리

### Skill 5: s3-db (데이터베이스)
```yaml
name: s3-db
description: DB 스키마 및 마이그레이션 관리
```
**역할:**
- 스키마 변경 감지
- 마이그레이션 생성
- Prisma/TypeORM 연동

---

## 4. 구현 계획

### Phase 1: 기본 Skills 구조 생성
```
목표: .claude/skills/ 폴더 구조 및 기본 Skills 생성
작업:
1. S3 프로젝트에 .claude/skills/ 폴더 생성
2. s3-build SKILL.md 작성
3. s3-test SKILL.md 작성
```

### Phase 2: Auto-Claude 연동
```
목표: Skills에서 Auto-Claude agents 호출
작업:
1. Auto-Claude CLI 호출 스크립트 작성
2. Agent 선택 로직 구현
3. 결과 파싱 및 피드백
```

### Phase 3: s3-feature Skill 완성
```
목표: 완전한 기능 개발 워크플로우
작업:
1. Feature 분석 로직
2. Backend/Frontend 작업 분리
3. Auto-Claude spec 생성 연동
```

### Phase 4: 배포 및 DB Skills
```
목표: 인프라 관련 Skills
작업:
1. s3-deploy 구현
2. s3-db 구현
3. CI/CD 통합
```

---

## 5. 상세 구현: s3-build Skill

### 파일 구조
```
.claude/skills/s3-build/
├── SKILL.md
├── scripts/
│   ├── flutter_build.ps1
│   ├── backend_build.ps1
│   └── generate_code.ps1
└── references/
    └── build_troubleshooting.md
```

### SKILL.md 내용
```markdown
---
name: s3-build
description: S3 프로젝트 빌드 자동화
---

# S3 Build Skill

이 스킬은 S3 프로젝트의 빌드를 자동화합니다.

## 사용법

`/s3-build [target]`

- `flutter` - Flutter 앱만 빌드
- `backend` - Backend만 빌드
- `all` - 전체 빌드 (기본값)
- `web` - Flutter Web 빌드
- `apk` - Android APK 빌드

## 빌드 프로세스

### 1. Flutter 빌드
```bash
cd C:\DK\S3\S3\frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web
```

### 2. Backend 빌드
```bash
cd C:\DK\S3\S3\backend
# (Backend 빌드 명령어)
```

## 에러 처리

빌드 실패 시:
1. 에러 로그 분석
2. 일반적인 수정 사항 제안
3. Auto-Claude의 qa_fixer 에이전트 호출 고려

## 참조

- [Flutter 빌드 문서](references/build_troubleshooting.md)
```

---

## 6. 상세 구현: s3-feature Skill

### SKILL.md 내용
```markdown
---
name: s3-feature
description: S3 기능 개발 워크플로우
---

# S3 Feature Development Skill

새로운 기능을 체계적으로 개발합니다.

## 사용법

`/s3-feature "기능 설명"`

예시:
- `/s3-feature "사용자 프로필 수정"`
- `/s3-feature "푸시 알림 구현"`
- `/s3-feature "소셜 로그인 추가"`

## 워크플로우

### 1. 요구사항 분석
- 기능 범위 파악
- Backend/Frontend 작업 분리
- 의존성 확인

### 2. 파일 구조 생성

#### Backend (필요시)
```
backend/
└── features/
    └── [feature_name]/
        ├── routes.py
        ├── models.py
        ├── services.py
        └── schemas.py
```

#### Frontend (Flutter)
```
frontend/lib/features/
└── [feature_name]/
    ├── models/
    │   └── [feature]_model.dart
    ├── mutations/
    │   └── [action]_mutation.dart
    ├── queries/
    │   └── get_[data]_query.dart
    └── pages/
        ├── providers/
        │   └── [feature]_provider.dart
        ├── screens/
        │   └── [feature]_screen.dart
        └── widgets/
            └── [component].dart
```

### 3. 코드 생성
- Freezed 모델 생성
- Riverpod provider 생성
- API 연동 코드

### 4. Auto-Claude 연동

복잡한 기능의 경우 Auto-Claude 에이전트 활용:
- `s3_backend_auth` - 인증 관련
- `s3_backend_data` - 데이터 CRUD
- `s3_frontend_auth` - 인증 UI
- `s3_frontend_data` - 데이터 동기화

## 예시

`/s3-feature "사용자 프로필 수정"` 실행 시:

1. **분석 결과:**
   - Frontend: 프로필 편집 화면, 이미지 업로드
   - Backend: PUT /users/profile API

2. **생성될 파일:**
   ```
   frontend/lib/features/profile/
   ├── models/profile_model.dart
   ├── mutations/update_profile_mutation.dart
   ├── queries/get_profile_query.dart
   └── pages/
       ├── screens/edit_profile_screen.dart
       └── widgets/profile_form.dart
   ```

3. **다음 단계:**
   - 코드 생성: `dart run build_runner build`
   - 테스트: `/s3-test profile`
```

---

## 7. Auto-Claude 연동 스크립트

### scripts/invoke_agent.py
```python
"""
Auto-Claude 에이전트 호출 스크립트
Claude Skills에서 Auto-Claude agents를 트리거
"""

import sys
import subprocess
from pathlib import Path

AUTO_CLAUDE_PATH = Path("C:/DK/S3/S3/Auto-Claude/apps/backend")

def invoke_agent(agent_type: str, task: str):
    """Auto-Claude 에이전트 호출"""
    cmd = [
        str(AUTO_CLAUDE_PATH / ".venv/Scripts/python.exe"),
        str(AUTO_CLAUDE_PATH / "run.py"),
        "--agent", agent_type,
        "--task", task,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.stdout, result.stderr

if __name__ == "__main__":
    agent = sys.argv[1] if len(sys.argv) > 1 else "coder"
    task = sys.argv[2] if len(sys.argv) > 2 else "Default task"
    stdout, stderr = invoke_agent(agent, task)
    print(stdout)
    if stderr:
        print(f"Errors: {stderr}", file=sys.stderr)
```

---

## 8. 다음 단계

### 즉시 실행 가능한 작업
1. `.claude/skills/` 폴더 구조 생성
2. `s3-build` SKILL.md 작성
3. `s3-test` SKILL.md 작성
4. 빌드 스크립트 작성

### 중기 작업
5. `s3-feature` SKILL.md 완성
6. Auto-Claude 연동 스크립트
7. `s3-deploy` SKILL.md

### 장기 작업
8. CI/CD 통합
9. 다른 프로젝트에서 재사용 가능한 Skills 템플릿화
10. Skills 마켓플레이스 공유 고려

---

## 9. 디렉토리 생성 명령어

```powershell
# S3 프로젝트에 Skills 폴더 생성
$skillsPath = "C:\DK\S3\S3\.claude\skills"

# 각 스킬 폴더 생성
@("s3-build", "s3-test", "s3-feature", "s3-deploy", "s3-db") | ForEach-Object {
    $skillDir = Join-Path $skillsPath $_
    New-Item -ItemType Directory -Force -Path "$skillDir\scripts"
    New-Item -ItemType Directory -Force -Path "$skillDir\references"
}

Write-Host "Skills 폴더 구조 생성 완료"
```

---

## 10. 결론

Claude Skills와 Auto-Claude를 통합하면:

1. **일관된 개발 경험**: `/s3-feature` 같은 간단한 명령으로 복잡한 워크플로우 실행
2. **자동화된 파이프라인**: 빌드, 테스트, 배포가 자동화됨
3. **AI 활용 극대화**: Auto-Claude의 특화 에이전트와 Claude Skills의 유연성 결합
4. **재사용성**: 다른 프로젝트에서도 Skills 템플릿 활용 가능

**핵심 가치**: "한 줄 명령어로 복잡한 개발 작업을 자동화"

---

## 11. AI 확장용 템플릿

### SKILL.md 템플릿

```markdown
---
name: s3-[skillname]
description: [10단어 이내 설명]
---

# S3 [Skill Name] Skill

[스킬 설명 1-2문장]

## 사용법

\`\`\`
/s3-[skillname] [옵션]
\`\`\`

### 옵션
| 옵션 | 설명 |
|------|------|
| `option1` | 설명 |
| `option2` | 설명 |

## 프로세스

### Step 1: [단계명]
\`\`\`bash
# 명령어
\`\`\`

### Step 2: [단계명]
\`\`\`bash
# 명령어
\`\`\`

## Auto-Claude 연동

| 작업 | 에이전트 |
|------|---------|
| [작업1] | s3_xxx |
| [작업2] | s3_yyy |

## 관련 Skills
- `/s3-build` - 빌드
- `/s3-test` - 테스트
```

### Agent config.json 템플릿

```json
{
  "s3_category_name": {
    "prompt_file": "s3_category_name.md",
    "description": "에이전트 설명",
    "tools": ["Read", "Glob", "Grep", "Write", "Edit", "Bash", "WebFetch", "WebSearch"],
    "mcp_servers": ["context7", "auto-claude"],
    "thinking_default": "medium"
  }
}
```

### Agent Prompt 템플릿

```markdown
# S3 [Category] [Name] Agent

당신은 S3 프로젝트의 [역할] 전문 에이전트입니다.

## 핵심 역할
1. [역할 1]
2. [역할 2]
3. [역할 3]

## 기술 스택

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.38.9 | 프론트엔드 |
| Python | 3.11+ | 백엔드 |

## 프로젝트 경로
- **Frontend**: `C:\DK\S3\S3\frontend`
- **Backend**: `C:\DK\S3\S3\backend`
- **Flutter SDK**: `C:\DK\flutter`

## 작업 지침

### 1. 분석 단계
1. 요구사항 확인
2. 기존 코드 분석
3. 영향 범위 파악

### 2. 구현 단계
1. 파일 생성/수정
2. 테스트 작성
3. 문서 업데이트

### 3. 검증 단계
1. 코드 품질 확인
2. 테스트 실행
3. 리뷰 준비

## 코드 패턴

### [패턴명]
\`\`\`dart
// Flutter 코드 예시
\`\`\`

### [패턴명]
\`\`\`python
# Python 코드 예시
\`\`\`

## 주의사항
- [주의사항 1]
- [주의사항 2]

## 출력 형식
작업 완료 후:
1. 수정된 파일 목록
2. 주요 변경사항
3. 다음 단계 제안
```

---

## 12. 파일 경로 총정리

```
C:\DK\S3\S3\
│
├── SKILLS_DEVELOPMENT_PLAN.md      ← 이 파일 (마스터 계획)
│
├── .claude\
│   ├── settings.local.json         ← Claude Code 설정
│   └── skills\                      ← Claude Skills
│       ├── README.md                ← Skills 확장 가이드
│       ├── s3-build\
│       │   ├── SKILL.md
│       │   ├── scripts\build.ps1
│       │   └── references\troubleshooting.md
│       ├── s3-test\
│       │   ├── SKILL.md
│       │   └── scripts\test.ps1
│       ├── s3-feature\
│       │   ├── SKILL.md
│       │   ├── scripts\invoke_autoclaude.py
│       │   └── references\feature_templates.md
│       └── s3-deploy\
│           └── SKILL.md
│
├── Auto-Claude\apps\backend\
│   └── custom_agents\               ← Custom Agents
│       ├── README.md                ← Agents 확장 가이드
│       ├── config.json              ← 에이전트 설정
│       └── prompts\                 ← 에이전트 프롬프트
│           ├── s3_backend_auth.md
│           ├── s3_backend_data.md
│           ├── s3_backend_notification.md
│           ├── s3_ai_assistant.md
│           ├── s3_ai_analyzer.md
│           ├── s3_ai_recommender.md
│           ├── s3_frontend_auth.md
│           └── s3_frontend_data.md
│
└── frontend\                        ← Flutter 앱
    └── lib\
        └── features\                ← Feature-First 구조
```

---

*최종 업데이트: 2026-02-03*
*AI 확장 시 이 문서와 각 폴더의 README.md를 참조하세요.*
