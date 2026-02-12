# S3 팀 작업 가이드

> 5명 (리드 + 팀원 4명) 병렬 개발 가이드

---

## 역할 분배

| 역할 | 파일 | 담당 범위 | 브랜치 |
|------|------|----------|--------|
| **리드** | `LEAD.md` | 설계 보완, 통합, Auto-Claude, 코드리뷰 | `master` |
| **팀원 A** | `MEMBER-A-WORKERS-CORE.md` | Workers Auth + JWT + Presets + Rules | `feat/workers-auth` |
| **팀원 B** | `MEMBER-B-WORKERS-DO.md` | Workers DO + Jobs + User + Queue + R2 | `feat/workers-do-jobs` |
| **팀원 C** | `MEMBER-C-GPU.md` | GPU Worker 전체 (SAM3 + Pipeline + Docker) | `feat/gpu-engine` |
| **팀원 D** | `MEMBER-D-FRONTEND.md` | Flutter 전체 (UI + Mock API → 실 API) | `feat/frontend-core` |

---

## 병렬 작업 타임라인

```
Week 1-2: 전원 동시 작업
────────────────────────────────────────────
리드   ░░░░░░░░░░ 설계 갭 보완 + workflow.md 업데이트
팀원 A ▓▓▓▓▓▓▓▓▓▓ JWT → Auth → Presets → Rules
팀원 B ▓▓▓▓▓▓▓▓▓▓ UserLimiterDO → JobCoordinatorDO → Jobs
팀원 C ▓▓▓▓▓▓▓▓▓▓ SAM3 → applier → pipeline → adapter
팀원 D ▓▓▓▓▓▓▓▓▓▓ UI 레이아웃 → 상태관리 → Mock API

Week 3: 통합
────────────────────────────────────────────
리드   ▓▓▓▓▓▓▓▓▓▓ PR 머지 → index.ts 통합 → E2E 테스트
팀원 D ▓▓▓▓▓      Mock → 실 API 교체
```

---

## 시작하기

1. `SETUP.md` 읽고 환경 설정
2. 본인 역할 MD 읽기 (예: `MEMBER-A-WORKERS-CORE.md`)
3. 브랜치 생성: `git checkout -b feat/workers-auth`
4. 구현 순서대로 작업
5. 완료 후 PR 생성 → 리드 리뷰 요청

---

## Claude Code 사용법

각 팀원은 자신의 Claude Code 세션에서 역할 MD를 컨텍스트로 제공:

```bash
# 프로젝트 디렉토리에서 Claude Code 실행
cd C:\DK\S3
claude

# 또는 역할 MD를 직접 참조하며 작업
# Claude가 CLAUDE.md + 역할 MD를 참고하여 맥락을 이해함
```

---

## 핵심 규칙

1. **types.ts, errors.ts 수정 금지** → 리드만 수정
2. **각자 폴더만 작업** → 충돌 방지
3. **workflow.md = SSoT** → API 스키마 확인 필수
4. **환경변수 하드코딩 금지** → .env / .dev.vars 사용
