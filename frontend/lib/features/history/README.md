# History Feature

> 과거 Job 히스토리 목록 + 상태 뱃지

## 파일

| 파일 | 역할 |
|------|------|
| `history_screen.dart` | Job 목록 (pull-to-refresh) |
| `history_provider.dart` | Riverpod provider — Job 목록 fetch + refresh |
| `history_provider.g.dart` | [generated] |
| `widgets/job_history_item.dart` | 개별 Job 리스트 타일 |
| `widgets/status_badge.dart` | Job 상태 뱃지 (done/failed/running 등) |
| `widgets/history_empty_state.dart` | 빈 상태 placeholder |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /jobs` | `workers/src/jobs/jobs.route.ts` | Job 목록 (D1 조회) |

## 기능

- SNOW 다크 테마 (WsColors)
- Pull-to-refresh → provider 갱신
- 각 Job 카드: preset, 상태 뱃지, 날짜
- 탭 → `/results/{jobId}`
- 에러 시 재시도 버튼
