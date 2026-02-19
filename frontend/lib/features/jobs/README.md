# Jobs Feature

> Job 진행률 추적 (3초 polling)

## 파일

| 파일 | 역할 |
|------|------|
| `job_progress_screen.dart` | Job 진행률 화면 — **현재 stub, 구현 필요** |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /jobs/:id` | `workers/src/jobs/jobs.route.ts` | 상태/진행률 조회 |
| `POST /jobs/:id/cancel` | `workers/src/jobs/jobs.route.ts` | Job 취소 |

## TODO

```
1. Timer.periodic(3초) → GET /jobs/:id
2. 진행률 바: done / total
3. 상태별 UI:
   - queued: "대기 중..."
   - running: 진행률 + 완료 이미지 미리보기
   - done: 결과 갤러리 이동
   - failed: 에러 메시지 + 재시도
4. 취소 버튼 → POST /jobs/:id/cancel
```

## 상태: Phase 2 구현 필요

현재 placeholder. `workspace/widgets/progress_overlay.dart`와 통합하여 구현 예정.
