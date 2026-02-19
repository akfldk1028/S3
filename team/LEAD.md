# S3 리드 가이드 — 통합 + 배포 + E2E 관리 (v3.2)

> 역할: 설계 갭 보완, workflow.md 관리, 팀원 작업 통합, 코드 리뷰, Auto-Claude 운영
> 최종 업데이트: 2026-02-19

---

## 현재 상태 (2026-02-19)

| 영역 | 상태 | 남은 작업 |
|------|------|----------|
| Workers | 14/14 구현 + 배포 ✅ | R2 API Token 생성, E2E 검증 |
| Frontend | UI + API 연결 + 카메라 ✅ | Jobs UI 실연동, 카메라 실기기 테스트 |
| GPU Worker | 코드 23파일 완성 ✅ | **Runpod 배포 (P1)** |
| 레거시 | cf-backend/, ai-backend/ 삭제 ✅ | — |
| E2E 통합 | 미시작 ❌ | **Phase D 전체** |

---

## 즉시 해야 할 일 (우선순위 순)

### TODO-1: R2 API Token 생성 (P0)

presigned URL 기능이 동작하려면 R2 API Token이 필요.

```
1. CF Dashboard → R2 → Manage R2 API Tokens
2. "Create API Token" 클릭
3. Permission: Object Read & Write
4. Bucket: s3-images
5. Token 복사 → Workers .dev.vars에 추가:
   R2_ACCESS_KEY_ID=<access_key>
   R2_SECRET_ACCESS_KEY=<secret_key>
6. wrangler secret 설정:
   cd workers && npx wrangler secret put R2_ACCESS_KEY_ID
   cd workers && npx wrangler secret put R2_SECRET_ACCESS_KEY
7. 재배포: cd workers && npx wrangler deploy
```

**확인할 경로:**
- `workers/wrangler.toml` — R2 바인딩 확인
- `workers/src/_shared/r2.ts` — presigned URL 생성 함수
- `docs/cloudflare-resources.md` — R2 bucket 정보

### TODO-2: E2E curl 테스트 (P1)

Workers 14개 엔드포인트 전체 수동 검증.

```bash
# 1. Auth
TOKEN=$(curl -s -X POST https://s3-workers.clickaround8.workers.dev/auth/anon | jq -r '.data.token')

# 2. Me
curl -H "Authorization: Bearer $TOKEN" https://s3-workers.clickaround8.workers.dev/me

# 3. Presets
curl -H "Authorization: Bearer $TOKEN" https://s3-workers.clickaround8.workers.dev/presets
curl -H "Authorization: Bearer $TOKEN" https://s3-workers.clickaround8.workers.dev/presets/interior

# 4. Rules
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"test","preset_id":"interior","concepts":{"Wall":{"action":"recolor","value":"white"}}}' \
  https://s3-workers.clickaround8.workers.dev/rules

curl -H "Authorization: Bearer $TOKEN" https://s3-workers.clickaround8.workers.dev/rules

# 5. Jobs (presigned URL 동작은 R2 Token 생성 후 테스트)
curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"preset":"interior","item_count":2}' \
  https://s3-workers.clickaround8.workers.dev/jobs
```

**확인할 경로:**
- `workers/VERIFICATION.md` — 상세 curl 테스트 가이드
- `workers/src/index.ts` — 라우트 마운트 확인
- CF Dashboard → Workers → Logs

### TODO-3: GPU Worker 배포 지원 (P1)

팀원 C와 협업:
1. R2 API Token → 팀원 C에게 전달
2. GPU_CALLBACK_SECRET 값 공유 (Workers .dev.vars와 동일)
3. Runpod 계정/API Key 확인
4. 배포 후 E2E 테스트

**확인할 경로:**
- `gpu-worker/.env.example` — GPU Worker에 필요한 환경변수
- `gpu-worker/Dockerfile` — Docker 빌드 설정
- `gpu-worker/adapters/runpod_serverless.py` — Runpod handler

### TODO-4: TODO.md 업데이트

Phase A 완료 반영, Phase D 세부 계획 작성.

**확인할 경로:**
- `TODO.md` — Phase A~E 실행 계획
- `team/README.md` — 팀 전체 상태

---

## 설계 갭 (2026-02-11 작성, 대부분 해결)

### 해결됨 ✅
- [x] JWT Payload + TTL → workflow.md 반영
- [x] HTTP 에러 코드 매핑 → errors.ts 구현
- [x] 부분 실패 크레딧 정책 → DO 구현
- [x] Workers ↔ Frontend 연결
- [x] DO init() 패턴 정립

### 미해결 ⏳
- [ ] **GPU 중간 데이터 포맷 확정** — SAM3 실제 출력 형식 확인 후 조정 필요
- [ ] **R2 presigned URL 실제 동작 검증** — R2 API Token 생성 후
- [ ] **Queue → GPU Worker 메시지 수신 검증** — Runpod 배포 후

---

## 통합 순서 (PR 머지) — 대부분 완료

```
1. ✅ 팀원 A PR 머지 (Auth + JWT + Presets + Rules)
2. ✅ 팀원 B PR 머지 (DO + Jobs)
3. ✅ 리드: index.ts 전체 라우트 마운트 + 배포
4. ⏳ 팀원 C: GPU Worker Runpod 배포
5. ✅ 팀원 D: Frontend API 연결 완료
6. ⏳ E2E 통합 테스트
```

---

## Auto-Claude 운영

### Daemon 시작

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\daemon_runner.py ^
  --project-dir "C:\DK\S3" ^
  --status-file "C:\DK\S3\.auto-claude\daemon_status.json" ^
  --use-worktrees --skip-qa
```

> **주의**: `--use-claude-cli` 사용 금지 — MCP 서버가 전달되지 않는 버그.

### Task 생성

```powershell
set PYTHONUTF8=1
C:\DK\S3\clone\Auto-Claude\apps\backend\.venv\Scripts\python.exe ^
  C:\DK\S3\clone\Auto-Claude\apps\backend\runners\spec_runner.py ^
  --task "태스크 설명" --project-dir "C:\DK\S3" --no-build
```

### 상태 확인

```
파일: C:\DK\S3\.auto-claude\daemon_status.json
WS:   ws://127.0.0.1:18801
```

---

## 코드 리뷰 체크리스트

- [ ] workflow.md API 스키마와 일치?
- [ ] types.ts 타입 사용? (직접 타입 선언 금지)
- [ ] errors.ts 에러 코드 사용?
- [ ] 환경변수 하드코딩 없음?
- [ ] 레이어 간 직접 import 없음?
- [ ] DO: 멱등성 보장?
- [ ] D1: batch() 트랜잭션 사용?
- [ ] Flutter: flutter analyze 0 errors?
