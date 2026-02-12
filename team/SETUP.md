# S3 프로젝트 — 공통 환경 설정 가이드

> 모든 팀원이 작업 시작 전에 반드시 완료해야 할 설정

---

## 1. 저장소 클론

```bash
git clone https://github.com/akfldk1028/S3.git
cd S3
```

---

## 2. Claude Code 설치

```bash
# npm 글로벌 설치
npm install -g @anthropic-ai/claude-code

# 또는 직접 다운로드
# https://claude.ai/claude-code
```

---

## 3. MCP 서버 설치 (역할별 필수/선택)

### 3.1 모든 팀원 필수

```bash
# context7 — 라이브러리 최신 문서 조회
npx -y @anthropic-ai/claude-code mcp add context7 -- npx -y @upstash/context7-mcp@latest

# cloudflare-observability — Workers 로그, CF 문서 검색
# (Cloudflare API Token 필요: https://dash.cloudflare.com/profile/api-tokens)
npx -y @anthropic-ai/claude-code mcp add cloudflare-observability -- npx -y @anthropic-ai/mcp-cloudflare-observability
```

### 3.2 Workers 팀 (팀원 A, B) 추가

```bash
# cloudflare-workers — D1, R2, KV, Workers 관리
npx -y @anthropic-ai/claude-code mcp add cloudflare-workers -- npx -y @anthropic-ai/mcp-cloudflare
```

### 3.3 GPU 팀 (팀원 C) 추가

```bash
# e2b — Python 코드 실행 샌드박스 (GPU 코드 테스트용)
npx -y @anthropic-ai/claude-code mcp add e2b -- npx -y @anthropic-ai/mcp-e2b
```

### 3.4 Frontend 팀 (팀원 D) 추가

```bash
# dart — 공식 Dart MCP (코드 분석, 테스트, pub.dev 검색)
# Dart SDK 3.9+ 필요 (Flutter 3.38+ 포함)
npx -y @anthropic-ai/claude-code mcp add dart -- dart language-server --protocol=lsp

# marionette — Flutter 앱 실시간 제어 (선택)
npx -y @anthropic-ai/claude-code mcp add marionette -- npx -y @anthropic-ai/mcp-marionette
```

### 3.5 설치 확인

```bash
# 설치된 MCP 서버 목록 확인
claude mcp list
```

---

## 4. 역할별 환경 설정

### Workers 팀 (팀원 A, B)

```bash
cd workers/
npm install

# 환경변수 설정
cp .dev.vars.example .dev.vars
# .dev.vars 편집:
#   JWT_SECRET=your-dev-secret-key-min-32-chars
#   GPU_CALLBACK_SECRET=your-callback-secret

# D1 로컬 DB 생성 + 마이그레이션
npx wrangler d1 execute s3-db --local --file=migrations/0001_init.sql

# 로컬 실행 확인
npx wrangler dev
```

### GPU 팀 (팀원 C)

```bash
cd gpu-worker/

# Python 가상환경
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Mac/Linux

pip install -r requirements.txt

# 환경변수
cp .env.example .env
# .env 편집 (R2 credentials 등)

# Docker 빌드 (GPU 있는 경우)
docker build -t s3-gpu .
```

### Frontend 팀 (팀원 D)

```bash
cd frontend/

# Flutter SDK 확인
flutter --version  # 3.38.9+ 필요

# 의존성 설치
flutter pub get

# 코드 생성 (Freezed/Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 실행 확인
flutter run -d chrome  # 또는 android/ios
```

---

## 5. Git 브랜치 규칙

```
master                          ← 메인 (안정)
├── feat/workers-auth           ← 팀원 A
├── feat/workers-do-jobs        ← 팀원 B
├── feat/gpu-engine             ← 팀원 C
└── feat/frontend-core          ← 팀원 D
```

**커밋 컨벤션:**
```
feat(workers): Auth 엔드포인트 구현
fix(gpu): SAM3 모델 로딩 오류 수정
refactor(frontend): API client Supabase→REST 전환
```

**PR 규칙:**
- 본인 브랜치 → master로 PR
- 리드 리뷰 후 머지

---

## 6. 프로젝트 핵심 문서

| 문서 | 위치 | 용도 |
|------|------|------|
| **workflow.md** | `C:\DK\S3\workflow.md` | **SSoT** — API 스키마, 데이터 모델, 아키텍처 전부 |
| **CLAUDE.md** | `C:\DK\S3\CLAUDE.md` | Agent 가이드 — 규칙, MCP, 명령어 |
| **ARCHITECTURE.md** | `C:\DK\S3\ARCHITECTURE.md` | 아키텍처 심화 — 모듈 설계, 통신 맵 |
| **본인 역할 MD** | `C:\DK\S3\team\MEMBER-*.md` | 각자 담당 범위, 구현 순서, 파일 목록 |

---

## 7. 소통 규칙

1. **API 계약 변경 시** → workflow.md PR + 전체 공지
2. **타입 변경 시** → workers/src/_shared/types.ts 수정 후 공지
3. **블로커 발생 시** → 즉시 리드에게 연락
4. **완료 시** → PR 생성 + 리드 리뷰 요청

---

## 8. 자주 쓰는 명령어

```bash
# Workers 로컬 실행
cd workers && npx wrangler dev

# Workers 타입 체크
cd workers && npx tsc --noEmit

# GPU Worker 테스트
cd gpu-worker && pytest

# Frontend 실행
cd frontend && flutter run

# Frontend 분석
cd frontend && flutter analyze

# Git 상태 확인
git status && git log --oneline -5
```
