# Results Feature

> 완료된 Job 결과 이미지 갤러리 + 전체화면 뷰어

## 파일

| 파일 | 역할 |
|------|------|
| `results_screen.dart` | 3열 그리드 + 탭→전체화면 다이얼로그 (CachedNetworkImage) |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /jobs/:id` | `workers/src/jobs/jobs.route.ts` | 완료된 item의 결과 URL (presigned GET) |

## 기능

- JobResult → items 목록 → previewUrl/resultUrl 표시
- 3열 그리드 썸네일 (CachedNetworkImage)
- 탭 → 전체화면 뷰어 다이얼로그
- 캐시 키: `result_{jobId}_{idx}` (presigned URL 만료 대응)
- preset 이름 AppBar 표시
