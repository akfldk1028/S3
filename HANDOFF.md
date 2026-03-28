# S3 HANDOFF — 2026-03-28

> DK-A 브랜치 기준. Workers 배포 완료, GPU Worker(Runpod) 배포만 남은 상태.

---

## 이번 세션에서 한 것 (2026-03-28)

### 1. D1 프로덕션 스키마 생성
- 5테이블: `users`, `rules`, `jobs_log`, `job_items_log`, `billing_events`
- 4인덱스: user_id+created_at 복합 인덱스
- MCP `d1_database_query`로 직접 실행 (이전에 `num_tables: 0`이었음)

### 2. Workers 버그 수정 + 배포
| 수정 | 파일 | 상세 |
|------|------|------|
| UserLimiterDO rule_slots 마이그레이션 | `do/UserLimiterDO.ts` | 기존 DO에 `rule_slots` 컬럼 없어서 `/me` 500 에러 → ALTER TABLE 안전 추가 |
| GET /jobs 없는 컬럼 | `jobs/jobs.route.ts` | `progress_done/failed/total` 컬럼이 D1에 없음 → 실제 스키마 컬럼으로 교체 |
| Queue consumer Runpod 전송 | `index.ts` | Runpod Serverless API 호출 구현 |

### 3. Wrangler OAuth 로그인 (Playwright 자동화)
- `wrangler login` → OAuth URL → Playwright로 CF 대시보드 인증 → 콜백 완료
- 토큰 갱신 성공 → `npx wrangler deploy` 실행

### 4. Workers 프로덕션 배포
- **URL**: `https://s3-workers.clickaround8.workers.dev`
- **Version**: `1b1b8874-5dac-4098-9330-39deb7407300`
- 바인딩: D1(`s3-db`), R2(`s3-images`), DO(2개), Queue(`gpu-jobs`)

### 5. API 전체 테스트 통과
| 엔드포인트 | 결과 |
|-----------|------|
| GET /health | OK |
| POST /auth/anon | OK — JWT 발급, credits=10, plan=free |
| GET /me | OK — plan, credits, rule_slots, concurrent_jobs |
| GET /presets | OK — interior + seller |
| GET /rules | OK — 빈 목록 |
| GET /jobs | OK — 빈 목록 |

### 6. Runpod API 키 갱신
- `.env` + `~/.claude.json` MCP 설정 둘 다 업데이트
- Claude Code 재시작 후 MCP 반영

### 7. 프로토콜 통일 확인
| 항목 | GPU Worker | Workers | 상태 |
|------|-----------|---------|------|
| callback 헤더 | `X-Callback-Secret` | `X-Callback-Secret` | ✅ 일치 |
| status enum | `"done"` / `"failed"` | `"done"` / `"failed"` | ✅ 일치 |
| idempotency_key | body에 포함 | body에서 파싱 | ✅ 일치 |

---

## 인프라 상태 (2026-03-28)

| 항목 | 상태 | 상세 |
|------|------|------|
| CF 계정 | ✅ | `Clickaround8@gmail.com` |
| Workers `s3-workers` | ✅ 배포됨 | 6개 API 정상 동작 |
| D1 `s3-db` | ✅ | 5테이블 + 4인덱스 |
| R2 `s3-images` | ✅ | 버킷 존재 |
| DO | ✅ | UserLimiterDO + JobCoordinatorDO (SQLite DO) |
| Queue `gpu-jobs` | ✅ | producer + consumer 바인딩 |
| Wrangler 로그인 | ✅ | OAuth 갱신 완료 |
| Runpod API 키 | ✅ | 갱신 완료 |
| Runpod Endpoint | ❌ | Docker 빌드 + endpoint 생성 필요 |
| Flutter baseUrl | ✅ | `s3-workers.clickaround8.workers.dev` 맞음 |

---

## E2E 흐름 (현재 아키텍처)

```
 1. Flutter → POST /auth/anon → JWT
 2. Flutter → GET /presets/interior → concepts 로드
 3. Flutter → POST /jobs { preset, item_count }
    → UserLimiterDO.reserve() → JobCoordinatorDO.create()
    → presigned URLs 반환
 4. Flutter → R2 직접 업로드 → POST /jobs/{id}/confirm-upload
 5. Flutter → POST /jobs/{id}/execute { concepts, protect }
    → JobCoordinatorDO.markQueued() → Queue push
 6. Queue consumer → Runpod Serverless에 전체 job 전달 → 즉시 ack
 7. GPU Worker (Runpod):
    → R2에서 이미지 다운로드
    → SAM3 segment (concept별)
    → rule apply (recolor)
    → R2에 결과 업로드
    → POST /jobs/{id}/callback (item별, X-Callback-Secret 인증)
 8. Workers callback → JobCoordinatorDO.onItemResult()
    → 멱등성 체크 → 진행률 갱신
    → 전체 완료 시 alarm → D1 flush + UserLimiterDO.release()
 9. Flutter → GET /jobs/{id} (polling 3초) → 진행률/결과 표시
```

---

## 남은 작업 (E2E 완성까지)

| # | 작업 | 상세 | 난이도 |
|---|------|------|--------|
| 1 | Claude Code 재시작 | Runpod MCP 키 반영 | 즉시 |
| 2 | SAM3 모델 가중치 다운로드 | HF_TOKEN으로 gated repo 접근, 3.4GB | 중 |
| 3 | Docker 빌드 + push | `cd gpu-worker && docker build -t <registry>/s3-gpu .` | 중 |
| 4 | Runpod Template 생성 | Docker 이미지, GPU: RTX 4090+, 볼륨 /models | MCP |
| 5 | Runpod Endpoint 생성 | Serverless endpoint → ENDPOINT_ID 획득 | MCP |
| 6 | Workers secrets 등록 | `RUNPOD_ENDPOINT_ID`, `RUNPOD_API_KEY` | wrangler |
| 7 | Workers 재배포 | `npx wrangler deploy` | 즉시 |
| 8 | E2E 테스트 | curl → job 생성 → GPU 처리 → callback → 결과 확인 | |
| 9 | Flutter 실 연동 테스트 | 앱에서 Workers API 호출 → 결과 표시 | |

### Workers secrets (6번 상세)

```bash
cd workers
wrangler secret put RUNPOD_ENDPOINT_ID   # 5번에서 획득
wrangler secret put RUNPOD_API_KEY       # .env에서 복사
```

> JWT_SECRET, GPU_CALLBACK_SECRET 등 기존 시크릿은 이미 설정되어 있을 수 있음. 확인 필요.

---

## 변경 파일 (이번 세션 커밋: 6741270)

```
workers/src/do/UserLimiterDO.ts   — rule_slots ALTER TABLE 마이그레이션
workers/src/jobs/jobs.route.ts    — GET /jobs 없는 컬럼 제거
workers/src/index.ts              — Queue consumer Runpod 전송 구현
workers/src/_shared/types.ts      — Runpod env 타입 추가
gpu-worker/engine/callback.py     — X-Callback-Secret 헤더 통일
gpu-worker/engine/pipeline.py     — status "done" 매칭
gpu-worker/handler.py             — pipeline 전체 실행
```

---

## 알려진 이슈

| # | 이슈 | 심각도 | 설명 |
|---|------|--------|------|
| 1 | `WORKERS_API_URL` 불일치 | 중 | `.env`에 `https://api.s3app.workers.dev` → 실제 `s3-workers.clickaround8.workers.dev` |
| 2 | `GPU_CALLBACK_SECRET` placeholder | 중 | `.env`에 `your_shared_callback_secret` — Workers와 동일 실제 값 세팅 필요 |
| 3 | `postprocess.py` 미구현 | 낮 | pipeline.py가 직접 PIL로 처리하므로 미사용 |
| 4 | applier.py tone/texture 미구현 | 낮 | v2 feature. recolor만 MVP |

---

## 다음 세션 시작 시

1. Claude Code 재시작 (Runpod MCP 키 반영)
2. `mcp__runpod__list-endpoints` 로 연결 확인
3. Docker 빌드 → Runpod Template → Endpoint 생성
4. Workers secrets 등록 + 배포
5. E2E 테스트
