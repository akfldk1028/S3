# Workspace Feature

> 메인 작업 영역 — 5단 파이프라인 통합 (사진 → concept → protect → rules → 적용)
> 앱의 핵심 화면. SNOW/B612 스타일 다크 UI.

## 파일

| 파일 | 역할 |
|------|------|
| `workspace_screen.dart` | 루트 화면 — 반응형 레이아웃 (600px 기준) |
| `workspace_provider.dart` | Riverpod notifier — 이미지 선택, 업로드, 상태 관리 |
| `workspace_provider.g.dart` | [generated] |
| `workspace_state.dart` | Freezed 상태 (phase, images, job, results) + SelectedImage |
| `workspace_state.freezed.dart` | [generated] |
| `preset_detail_provider.dart` | GET /presets/:id 상세 provider |
| `preset_detail_provider.g.dart` | [generated] |
| `theme.dart` | WsColors + WsTheme (SNOW 다크 팔레트, glassmorphism) |

### widgets/

| 파일 | 역할 |
|------|------|
| `photo_grid.dart` | 이미지 그리드 + EmptyState + AddMoreTile + 카메라/갤러리 BottomSheet |
| `concepts_section.dart` | Concept 칩 선택 UI (Wall, Floor, Tile...) |
| `protect_section.dart` | Protect 영역 토글 UI |
| `rules_section.dart` | 룰 선택/적용 UI |
| `domain_section.dart` | 도메인 정보 표시 |
| `top_bar.dart` | SNOW-style 상단 바 (사진 선택 후만 표시) |
| `action_bar.dart` | 하단 액션 버튼 ("Apply" 등) → **TODO: Jobs API 연결** |
| `progress_overlay.dart` | 처리 진행률 오버레이 → **TODO: polling 연결** |
| `results_overlay.dart` | 완료 결과 표시 오버레이 → **TODO: 결과 이미지 표시** |
| `side_panel.dart` | 데스크톱 좌측 사이드 패널 (280px) |
| `mobile_bottom_sheet.dart` | 모바일 바텀시트 (concept/protect/rule 컨트롤) |
| `mobile_pipeline_tabs.dart` | 모바일 탭 네비게이션 (palette/protect/rules) |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /presets/:id` | `workers/src/presets/presets.route.ts` | 프리셋 상세 |
| `POST /jobs` | `workers/src/jobs/jobs.route.ts` | Job 생성 + presigned URLs |
| `POST /jobs/:id/confirm-upload` | `workers/src/jobs/jobs.route.ts` | 업로드 확인 |
| `POST /jobs/:id/execute` | `workers/src/jobs/jobs.route.ts` | 룰 적용 실행 |
| `GET /jobs/:id` | `workers/src/jobs/jobs.route.ts` | 상태/진행률 polling |
| `POST /jobs/:id/cancel` | `workers/src/jobs/jobs.route.ts` | Job 취소 |

## 레이아웃

```
데스크톱 (≥600px):
┌──────────┬────────────────────┐
│ SidePanel│    PhotoGrid       │
│ (280px)  │   (전체 나머지)     │
│ concepts │                    │
│ protect  │                    │
│ rules    │                    │
│ domain   │                    │
└──────────┴────────────────────┘
         [ActionBar]

모바일 (<600px):
┌────────────────────┐
│    PhotoGrid       │
│   (전체 화면)       │
│                    │
│                    │
├────────────────────┤
│ MobilePipelineTabs │
│ (palette/protect/  │
│  rules 탭)         │
└────────────────────┘
    [ActionBar]
```

## Phase Machine (WorkspacePhase)

```
idle → photosSelected → uploading → processing → completed
                                                → error
```

## 핵심 메서드 (workspace_provider.dart)

- `addPhotos()` — 갤러리에서 이미지 선택
- `addPhotosFromFiles(List<XFile>)` — 카메라/갤러리에서 받은 파일 추가
- `uploadAndProcess(presignedUrls)` — 청크 병렬 업로드
- `clearPhotos()` / `removePhoto(index)` — 이미지 관리
- `retryJob()` / `cancelJob()` — Job 제어
