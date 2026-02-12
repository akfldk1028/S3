# S3 - SAM3 Segmentation App

> **SAM3**(Segment Anything Model 3, Meta 2025.11) 기반 이미지/비디오 세그멘테이션 앱.
> 텍스트 프롬프트로 객체를 감지하고 세그멘테이션하는 서비스.

---

## System Architecture

```
┌─────────────┐     ┌──────────────────────────┐     ┌─────────────────┐
│   Flutter    │────▶│  Cloudflare Workers       │────▶│  Vast.ai GPU    │
│   App        │◀────│  Full API (Hono + R2)     │◀────│  (FastAPI)      │
│  (Frontend)  │     │  Auth, CRUD, R2, Supabase │     │  SAM3 추론만     │
└──────┬───────┘     └────────────┬─────────────┘     └─────────────────┘
       │                          │                           │
       │              ┌───────────▼──────────┐                │
       └─────────────▶│    Supabase          │◀───────────────┘
                      │  Auth / DB / RT      │  (service_role: 결과 UPDATE)
                      └──────────────────────┘
```

**핵심 원칙:**
- **Edge = Full API** — Flutter가 호출하는 유일한 API. 모든 비즈니스 로직.
- **Backend = SAM3 추론만** — GPU 추론 전용. Edge에서만 호출.
- **Supabase** — Edge가 모든 CRUD (anon key + JWT), Backend는 결과 UPDATE만 (service_role).

---

## Layer Overview

| Layer | Directory | Tech | Role | Status |
|-------|-----------|------|------|--------|
| **Frontend** | [`frontend/`](frontend/README.md) | Flutter 3.38.9 + Riverpod 3 + ShadcnUI | 크로스 플랫폼 앱 | ~30% |
| **Edge** | [`edge/`](edge/README.md) | Hono + CF Workers + R2 | Full API | 부분 구현 |
| **Backend** | [`backend/`](cf-backend/README.md) | FastAPI + SAM3 | GPU 추론 전용 | 스캐폴딩 |
| **Supabase** | [`supabase/`](supabase/README.md) | PostgreSQL + Auth + Realtime | DB + Auth | 스키마 완료 |
| **AI** | [`ai/`](ai-backend/README.md) | SAM3 스크립트/노트북 | 모델 관리 | 스캐폴딩 |
| **Docs** | [`docs/`](docs/README.md) | API 계약서, 아키텍처 문서 | 문서화 | 완료 |

---

## README Index

> 프로젝트 내 모든 README 경로 목차.

| Path | Description |
|------|-------------|
| [`README.md`](README.md) | **루트** — 프로젝트 개요, 아키텍처, README 인덱스 (이 파일) |
| [`CLAUDE.md`](CLAUDE.md) | Agent 마스터 가이드 (규칙, 계약, 커맨드, 환경변수) |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | 초기 아키텍처 설계 문서 |
| [`docs/README.md`](docs/README.md) | 문서 디렉토리 안내 |
| [`docs/contracts/api-contracts.md`](docs/contracts/api-contracts.md) | **API 계약서 (SSoT)** — 모든 엔드포인트 스펙 |
| [`frontend/README.md`](frontend/README.md) | Flutter 앱 — 구조, 패턴, TODO, 커맨드 |
| [`edge/README.md`](edge/README.md) | Edge Full API — Hono, 라우트, 서비스, Agent 가이드 |
| [`backend/README.md`](cf-backend/README.md) | Backend 추론 서버 — FastAPI, SAM3, Agent 가이드 |
| [`supabase/README.md`](supabase/README.md) | Supabase — 스키마, RLS, 마이그레이션, Agent 가이드 |
| [`ai/README.md`](ai-backend/README.md) | AI 스크립트 — 가중치 다운로드, 모델 변환, 벤치마크 |

---

## Implementation Progress

### Completed
- [x] 프로젝트 구조 + 5 레이어 스캐폴딩
- [x] 문서화 (CLAUDE.md, API 계약서, 레이어별 README)
- [x] Supabase 스키마 4 테이블 + RLS + Realtime + Auth 트리거
- [x] Edge: Hono 앱 팩토리 + Upload 라우트 (R2 직접 저장)
- [x] Edge: Response envelope, 타입, 검증 유틸
- [x] Edge: Segment + Results 라우트, Supabase CRUD, Backend 프록시
- [x] Backend: FastAPI 구조 + 스키마 + API Key 인증 + Docker + 테스트
- [x] Frontend: 프로젝트 구조 + Auth feature + 의존성 설정

### TODO (Critical Path)
- [ ] Edge: Auth 미들웨어 JWT 검증 (현재 stub)
- [ ] Backend: SAM3Predictor (모델 로드 + 추론)
- [ ] Backend: Storage 서비스 (R2 다운로드/마스크 업로드)
- [ ] Backend: Tasks 서비스 (Supabase 결과 UPDATE)
- [ ] Frontend: Segmentation feature (핵심 UI)
- [ ] Frontend: Gallery feature
- [ ] Frontend: Supabase Auth 연동

---

## Quick Start

```bash
# Edge (Full API)
cd edge && npm install && cp .dev.vars.example .dev.vars && npx wrangler dev

# Backend (SAM3 추론)
cd cf-backend && python -m venv .venv && .venv\Scripts\activate && pip install -r requirements.txt && uvicorn src.main:app --reload

# Frontend (Flutter)
cd frontend && flutter pub get && dart run build_runner build && flutter run

# Supabase (DB)
cd supabase && supabase start && supabase db push
```

---

## Key Documents

| Document | Purpose |
|----------|---------|
| [`CLAUDE.md`](CLAUDE.md) | Agent가 참조하는 마스터 규칙 + 아키텍처 + 계약 요약 |
| [`docs/contracts/api-contracts.md`](docs/contracts/api-contracts.md) | API Single Source of Truth — 변경 시 여기 먼저 |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | 초기 설계 의도 + Data Flow + Key Decisions |
