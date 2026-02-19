# Upload Feature

> 이미지 선택 + R2 presigned URL 업로드

## 파일

| 파일 | 역할 |
|------|------|
| `upload_screen.dart` | 이미지 선택 + 3열 미리보기 그리드 + 업로드 진행률 |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `POST /jobs` | `workers/src/jobs/jobs.route.ts` | Job 생성 + presigned PUT URLs |
| `POST /jobs/:id/confirm-upload` | `workers/src/jobs/jobs.route.ts` | 업로드 완료 확인 |

## 흐름

```
/upload → 이미지 선택 (image_picker)
  → POST /jobs { preset, item_count } → presigned URLs
  → Dio PUT → R2에 이미지 업로드 (각각)
  → POST /jobs/:id/confirm-upload
  → /rules?jobId=xxx
```

## 상태: Phase 2 구현 필요

현재 Mock 업로드 시뮬레이션. 실제 R2 presigned URL 업로드는 `workspace_provider.dart`의 `_uploadOne()` 활용.
