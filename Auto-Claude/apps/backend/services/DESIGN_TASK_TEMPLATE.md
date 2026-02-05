# Design Task Template

Design task를 사용하면 대형 프로젝트를 자동으로 분해해서 **병렬 실행**할 수 있습니다.

## Quick Start

1. `.auto-claude/specs/` 폴더에 새 spec 폴더 생성
2. 아래 4개 파일 복사
3. UI에서 task 시작 (또는 daemon이 자동 감지)

## 필수 파일 (4개)

### 1. spec.md
```markdown
# [프로젝트 이름]

## Overview
[프로젝트 설명]

## Requirements
1. [기능 1]
2. [기능 2]
3. [기능 3]

## Technical Constraints
- [기술 제약 사항]
```

### 2. requirements.json
```json
{
  "task": "[프로젝트 이름]",
  "description": "[간단한 설명]",
  "acceptance_criteria": [
    "[완료 조건 1]",
    "[완료 조건 2]"
  ]
}
```

### 3. implementation_plan.json (핵심!)
```json
{
  "status": "queue",
  "planStatus": "queue",
  "xstateState": "backlog",
  "executionPhase": "backlog",
  "taskType": "design",
  "priority": 0
}
```

**중요: `"taskType": "design"`이 핵심입니다!**

### 4. context.json
```json
{
  "task_description": "[프로젝트 이름]",
  "project_type": "greenfield",
  "files_to_create": [],
  "files_to_modify": [],
  "patterns": {},
  "existing_implementations": {},
  "created_at": "2026-01-01T00:00:00Z"
}
```

## 폴더 구조 예시

```
.auto-claude/specs/
└── 001-shopping-app-design/
    ├── spec.md
    ├── requirements.json
    ├── implementation_plan.json    ← taskType: "design"
    └── context.json
```

## 실행 후 결과

Design agent가 `create_batch_child_specs` 도구를 호출해서 child spec을 자동 생성합니다:

```
.auto-claude/specs/
├── 001-shopping-app-design/       (부모 - 완료됨)
├── 002-database-schema/           (자식 - 자동 생성됨)
├── 003-backend-api/               (자식 - 자동 생성됨)
├── 004-frontend-ui/               (자식 - 자동 생성됨)
└── 005-integration-tests/         (자식 - 자동 생성됨)
```

## Task Type 참고

| taskType | 용도 | 실행 방식 |
|----------|------|----------|
| `design` | 프로젝트 분해, child spec 생성 | run.py (MCP tools) |
| `architecture` | 아키텍처 분석/설계 | run.py (MCP tools) |
| `impl` | 일반 구현 | run.py (Auto-Claude) |
| `frontend` | 프론트엔드 개발 | run.py + puppeteer |
| `backend` | 백엔드 개발 | run.py + context7 |
| `test` | 테스트 작성 | run.py |

## Priority 참고

| Priority | 값 | 용도 |
|----------|-----|------|
| CRITICAL | 0 | design, architecture (먼저 실행) |
| HIGH | 1 | 핵심 기능 |
| NORMAL | 2 | 일반 기능 |
| LOW | 3 | 문서, 정리 |

## 예시: E-Commerce App

```
# spec.md
# E-Commerce Mobile App

## Overview
Build a complete e-commerce mobile app with Flutter.

## Requirements
1. User authentication (login, register, password reset)
2. Product catalog with search and filters
3. Shopping cart with real-time sync
4. Checkout with payment integration
5. Order history and tracking

## Technical Stack
- Flutter 3.x
- Firebase Authentication
- Firestore for data
- Stripe for payments
```

```json
// implementation_plan.json
{
  "status": "queue",
  "planStatus": "queue",
  "xstateState": "backlog",
  "executionPhase": "backlog",
  "taskType": "design",
  "priority": 0
}
```

Design agent가 자동으로 다음과 같이 분해합니다:
- 002-firebase-auth (priority: 0, type: backend)
- 003-product-catalog (priority: 1, depends: [002])
- 004-shopping-cart (priority: 1, depends: [002])
- 005-checkout-flow (priority: 2, depends: [003, 004])
- 006-order-tracking (priority: 2, depends: [005])
