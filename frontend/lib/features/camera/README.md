# Camera Feature

> SNOW-style 전체화면 카메라 홈 — 앱의 메인 진입점. 도메인 사이드바 + 컨셉 칩 통합.

## 파일

| 파일 | 역할 |
|------|------|
| `camera_home_screen.dart` | 메인 카메라 홈 (Scaffold + Drawer + ConceptChips + 셔터) |
| `camera_screen.dart` | 독립 카메라 프리뷰 (workspace에서 push용) |
| `widgets/domain_drawer.dart` | 도메인 사이드바 (프리셋 선택 + My Rules + Settings) |
| `widgets/concept_chips_bar.dart` | 수평 스크롤 컨셉 칩 (선택된 도메인의 concepts 표시) |

## Workers 연동

| API | 용도 |
|-----|------|
| `GET /presets` | DomainDrawer에서 도메인 목록 표시 (presetsProvider) |
| `GET /presets/:id` | ConceptChipsBar에서 concepts 로드 (presetDetailProvider) |

## UI 구성

```
┌──────────────────────────────────┐
│ [☰] S3           [switch] [⚙]  │  ← ☰ = 도메인 사이드바
│                                  │
│     전체화면 카메라 프리뷰        │
│     (CameraPreview)              │
│                                  │
│ [flash]                          │
│                                  │
│ ┌──────────────────────────────┐ │
│ │ Wall │ Floor │ Tile │ Grout..│ │  ← 수평 스크롤 컨셉 칩
│ └──────────────────────────────┘ │
│                                  │
│ [gallery]    ( O )    [N→]      │  ← 하단 컨트롤
└──────────────────────────────────┘

☰ 사이드바 (DomainDrawer):
┌────────────┐
│ [S3] S3    │
│ ────────── │
│ DOMAINS    │
│ ▶ 건축/인테리어 │  ← 선택됨 = accent1
│   쇼핑/셀러    │
│            │
│ ────────── │
│ My Rules   │
│ Settings   │
└────────────┘
```

## 주요 기능

- **도메인 사이드바** (☰ 햄버거): `presetsProvider` watch → 도메인 리스트 표시
  - 선택 → `selectedPresetProvider.select(id)` → 컨셉 칩 자동 갱신
- **컨셉 칩 바**: `presetDetailProvider(id)` → concepts 표시
  - 탭 → `paletteProvider.toggleConcept()` (accent1 하이라이트)
  - 도메인 미선택 시 숨김 (`SizedBox.shrink`)
- 후면 카메라 우선, 전면/후면 전환
- 플래시: OFF → AUTO → ON 순환
- 셔터 버튼: SNOW-style 링 (accent1) + 원 (white)
- 갤러리 버튼: `ImagePicker.pickMultiImage()` 호출
- **다음 버튼**: 도메인 선택됨 → `/upload?presetId=...` (스킵), 미선택 → `/domain-select`
- 웹(kIsWeb): 갤러리 전용 UI + 도메인 사이드바 + 컨셉 칩

## Providers 의존성

```
selectedPresetProvider  → 선택된 도메인 ID 추적 (domain_select/)
presetsProvider         → GET /presets (domain_select/)
presetDetailProvider    → GET /presets/:id (workspace/)
paletteProvider         → concept 토글 상태 (palette/)
workspaceProvider       → 사진 전달 (workspace/)
```

## 플랫폼 권한

- **Android**: `AndroidManifest.xml` → `CAMERA` permission
- **iOS**: `Info.plist` → `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`

## 연결 포인트

- 앱 메인 진입점: GoRouter `/` → `CameraHomeScreen`
- `workspace/workspace_provider.dart` → `addPhotosFromFiles(List<XFile>)` 수신
- `domain_select/selected_preset_provider.dart` → 도메인 선택 상태 공유
- `palette/palette_provider.dart` → 컨셉 선택 상태 공유
