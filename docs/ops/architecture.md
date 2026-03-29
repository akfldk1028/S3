# S3 아키텍처 요약

## 3계층 구조

```
Flutter App ──→ CF Workers (Hono) ──→ Runpod GPU Worker (Docker)
                  │                         │
                  ├── D1 (SQLite DB)        ├── SAM3 추론
                  ├── R2 (이미지 저장)      ├── R2 업로드
                  ├── DO (상태관리)          └── Workers callback
                  └── Queue (GPU 작업)
```

## E2E 데이터 흐름

```
1. Flutter → POST /auth/anon → JWT
2. Flutter → POST /jobs { preset, item_count } → presigned URLs
3. Flutter → R2 PUT (presigned URL로 이미지 직접 업로드)
4. Flutter → POST /jobs/{id}/confirm-upload
5. Flutter → POST /jobs/{id}/execute { concepts, protect }
6. Workers → Queue push → Runpod GPU Worker
7. GPU Worker → R2 다운로드 → SAM3 → R2 업로드 → POST /jobs/{id}/callback
8. Workers → DO 상태 갱신 → done
9. Flutter → GET /jobs/{id} (polling) → 결과 URL 반환
```

## 주요 URL

| 항목 | URL |
|------|-----|
| Workers API | `https://s3-workers.clickaround8.workers.dev` |
| R2 Bucket | `s3-images` (CF 대시보드) |
| D1 Database | `s3-db` (ID: 9e2d53af-ba37-4128-9ef8-0476ace30efa) |
| Docker Image (test) | `jonghwan0309/sam3-worker:test` |
| Docker Image (prod) | `jonghwan0309/sam3-worker:latest` (SAM3 포함, 미완) |

## Workers API 엔드포인트

| Method | Path | 설명 |
|--------|------|------|
| POST | /auth/anon | 익명 JWT 발급 |
| GET | /me | 유저 상태 (credits, plan) |
| GET | /presets | 프리셋 목록 (interior, seller) |
| POST | /rules | 룰 저장 |
| GET | /rules | 룰 목록 |
| POST | /jobs | Job 생성 + presigned URLs |
| POST | /jobs/{id}/confirm-upload | 업로드 완료 확인 |
| POST | /jobs/{id}/execute | 룰 적용 실행 |
| GET | /jobs/{id} | 상태 조회 (polling) |
| POST | /jobs/{id}/callback | GPU Worker 콜백 (내부) |

## Durable Objects

| DO | 역할 | 단위 |
|----|------|------|
| UserLimiterDO | 크레딧/동시성/룰슬롯 | 유저당 1개 |
| JobCoordinatorDO | Job FSM/멱등성/D1 flush | Job당 1개 |

## 플랜 제한

```
free: { credits: 10, maxConcurrency: 1, ruleSlots: 2, maxItems: 10 }
pro:  { credits: 200, maxConcurrency: 3, ruleSlots: 20, maxItems: 200 }
```