# 팀원 D: Frontend — Flutter UI + API + Camera

> **담당**: Flutter 앱 전체 (Auth, 워크스페이스, 카메라, Jobs 연동)
> **상태**: UI + API 연결 완료 ✅, 카메라 홈 통합 ✅ (도메인 사이드바 + 컨셉 칩), **Jobs 실연동 필요**
> **브랜치**: master

---

## 현재 상태 (2026-02-19)

### ✅ 완료된 작업

| 항목 | 상태 | 파일 |
|------|------|------|
| Auth (anon JWT) | ✅ 완료 | `core/auth/auth_provider.dart` |
| User model | ✅ 완료 | `features/auth/models/user_model.dart` |
| API Client interface | ✅ 완료 | `core/api/api_client.dart` |
| S3ApiClient (Dio) | ✅ 완료 | `core/api/s3_api_client.dart` |
| API provider | ✅ 완료 | `core/api/api_client_provider.dart` |
| GoRouter (8 라우트) | ✅ 완료 | `routing/app_router.dart` |
| Auth guard | ✅ 완료 | `routing/app_router.dart` |
| Splash screen | ✅ 완료 | `features/splash/splash_screen.dart` |
| Domain select | ✅ 완료 | `features/domain_select/domain_select_screen.dart` |
| Workspace (메인) | ✅ 완료 | `features/workspace/workspace_screen.dart` |
| Photo grid | ✅ 완료 | `features/workspace/widgets/photo_grid.dart` |
| Concepts section | ✅ 완료 | `features/workspace/widgets/concepts_section.dart` |
| Protect section | ✅ 완료 | `features/workspace/widgets/protect_section.dart` |
| Rules section | ✅ 완료 | `features/workspace/widgets/rules_section.dart` |
| Action bar | ✅ 완료 | `features/workspace/widgets/action_bar.dart` |
| Progress overlay | ✅ 완료 | `features/workspace/widgets/progress_overlay.dart` |
| Results overlay | ✅ 완료 | `features/workspace/widgets/results_overlay.dart` |
| Side panel (데스크톱) | ✅ 완료 | `features/workspace/widgets/side_panel.dart` |
| Mobile bottom sheet | ✅ 완료 | `features/workspace/widgets/mobile_bottom_sheet.dart` |
| WsColors/WsTheme | ✅ 완료 | `features/workspace/theme.dart` |
| Image service | ✅ 완료 | `core/services/image_service.dart` |
| Camera screen | ✅ 완료 | `features/camera/camera_screen.dart` |
| addPhotosFromFiles | ✅ 완료 | `features/workspace/workspace_provider.dart` |
| **카메라 홈 도메인 사이드바** | ✅ 완료 | `features/camera/widgets/domain_drawer.dart` |
| **카메라 홈 컨셉 칩 바** | ✅ 완료 | `features/camera/widgets/concept_chips_bar.dart` |
| **선택 도메인 provider** | ✅ 완료 | `features/domain_select/selected_preset_provider.dart` |
| **카메라 홈 통합** | ✅ 완료 | `features/camera/camera_home_screen.dart` (drawer+chips+proceed) |
| flutter analyze 0 errors | ✅ 완료 | — |

### ❌ 남은 작업

| 항목 | 우선순위 | 설명 |
|------|---------|------|
| 카메라 실기기 테스트 | P1 | Android/iOS에서 카메라 동작 확인 |
| Jobs UI 실연동 | P1 | Workers Jobs API 호출 연결 |
| R2 presigned 업로드 | P1 | 실제 R2에 이미지 PUT |
| Polling 진행률 | P2 | GET /jobs/:id 3초 polling |
| 결과 이미지 표시 | P2 | R2 presigned download URL 사용 |
| 에러/오프라인 처리 | P3 | 카메라 권한 거부, 네트워크 에러 |

---

## 즉시 해야 할 일 (순서대로)

### Step 1: 카메라 홈 + 도메인 사이드바 테스트 (P1)

카메라 홈에 도메인 사이드바 + 컨셉 칩이 통합됨. 실기기 + 웹에서 확인 필요.

```bash
cd frontend
flutter run -d <device>     # 모바일
flutter run -d chrome        # 웹
```

**테스트 항목:**
1. 앱 실행 → `/` (카메라 홈) 진입
2. ☰ 햄버거 → 사이드바 열림 → 도메인 목록 (건축/인테리어, 쇼핑/셀러) 표시
3. 도메인 선택 → 사이드바 닫힘 → 컨셉 칩 바 나타남
4. 컨셉 칩 탭 → accent1 하이라이트 토글
5. 다른 도메인 선택 → 컨셉 칩 초기화 (리셋)
6. 카메라 프리뷰 정상 표시
7. 셔터 버튼 → 사진 촬영 → 카운터 표시
8. 갤러리 버튼 → 갤러리에서 사진 선택
9. 다음 버튼 (도메인 선택됨): `/upload?presetId=...` 이동
10. 다음 버튼 (도메인 미선택): `/domain-select` 이동
11. 웹(Chrome): 갤러리 전용 UI + 햄버거 + 컨셉 칩 동작 확인
12. 사이드바 하단: "My Rules" → `/rules`, "Settings" → `/settings`

**확인할 파일:**
- `frontend/lib/features/camera/camera_home_screen.dart` — 메인 카메라 홈
- `frontend/lib/features/camera/widgets/domain_drawer.dart` — 도메인 사이드바
- `frontend/lib/features/camera/widgets/concept_chips_bar.dart` — 컨셉 칩 바
- `frontend/lib/features/domain_select/selected_preset_provider.dart` — 도메인 선택 상태
- `frontend/lib/features/palette/palette_provider.dart` — 컨셉 토글 상태

**플랫폼 권한 (이미 설정됨):**
- **Android**: `AndroidManifest.xml` → `CAMERA` permission
- **iOS**: `Info.plist` → `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`

### Step 2: Jobs UI 실연동 (P1)

Workers Jobs 7개 엔드포인트가 구현 완료됨. Frontend에서 호출 연결.

**흐름:**
```
1. User가 워크스페이스에서 사진 추가 + concept 선택 + rule 설정
2. "Apply" 버튼 → POST /jobs { preset, item_count }
   → 응답: { job_id, upload_urls: [...] }
3. 각 이미지를 presigned URL로 R2 직접 PUT
4. POST /jobs/:id/confirm-upload
5. POST /jobs/:id/execute { concepts, protect, rule_id? }
6. GET /jobs/:id (3초 polling) → 진행률 표시
7. status == "done" → 결과 이미지 URL 표시
```

**수정할 파일:**

1. **`features/workspace/widgets/action_bar.dart`**
   - "Apply" 버튼 onTap → Jobs API 호출 시작
   - `workspaceProvider.notifier`에 Job 실행 메서드 추가 필요

2. **`features/workspace/workspace_provider.dart`**
   - `executeJob()` 메서드 추가:
     ```dart
     Future<void> executeJob({
       required String presetId,
       required Map<String, dynamic> concepts,
       required List<String> protect,
       String? ruleId,
     }) async {
       // 1. POST /jobs → job_id + presigned URLs
       // 2. uploadAndProcess(presignedUrls) — 이미 구현됨
       // 3. POST /confirm-upload
       // 4. POST /execute
       // 5. state.copyWith(phase: processing, activeJob: ...)
     }
     ```

3. **`features/workspace/widgets/progress_overlay.dart`**
   - Polling 로직: `Timer.periodic(3초)` → `GET /jobs/:id`
   - 진행률 표시: `done / total`

4. **`features/workspace/widgets/results_overlay.dart`**
   - 완료 시 결과 이미지 URL 표시
   - presigned download URL로 이미지 로드

**참고할 API 스키마:**
- `workflow.md` 섹션 6.5 (Jobs API)
- `frontend/lib/core/api/api_client.dart` — 14개 메서드 인터페이스
- `frontend/lib/core/api/s3_api_client.dart` — Dio 구현

### Step 3: R2 Presigned URL 업로드 (P1)

```dart
// workspace_provider.dart의 _uploadOne() 이미 구현되어 있음
// presigned URL을 Workers에서 받아서 전달하면 됨
//
// 흐름:
// POST /jobs 응답의 upload_urls → presigned PUT URLs
// _uploadChunked(presignedUrls) 호출
```

**확인할 파일:**
- `features/workspace/workspace_provider.dart` L92~163 — uploadAndProcess(), _uploadChunked(), _uploadOne()
- `core/api/s3_api_client.dart` — createJob(), confirmUpload(), executeJob() 메서드

### Step 4: Polling 진행률 (P2)

```dart
// GET /jobs/:id → 3초마다 호출
// status: created → uploaded → queued → running → done/failed/canceled

// Timer.periodic 사용 (workspace_provider.dart에 추가)
Timer? _pollingTimer;

void startPolling(String jobId) {
  _pollingTimer = Timer.periodic(Duration(seconds: 3), (_) async {
    final job = await ref.read(apiClientProvider).getJob(jobId);
    state = state.copyWith(
      // 진행률 업데이트
    );
    if (job.status == 'done' || job.status == 'failed') {
      _pollingTimer?.cancel();
    }
  });
}
```

### Step 5: 에러/오프라인 처리 (P3)

- 카메라 권한 거부 → 갤러리 fallback 또는 설정 안내
- 네트워크 에러 → 재시도 스낵바
- Job 실패 → 에러 메시지 + 재시도 버튼

---

## 프로젝트 구조 (현재)

```
frontend/lib/
├── main.dart
├── app.dart
├── routing/app_router.dart               # 8 라우트 + auth guard
├── constants/api_endpoints.dart           # Workers base URL
├── core/
│   ├── api/
│   │   ├── api_client.dart               # abstract (14 methods)
│   │   ├── s3_api_client.dart            # Dio 구현
│   │   ├── mock_api_client.dart          # 테스트용
│   │   └── api_client_provider.dart      # Riverpod provider
│   ├── auth/
│   │   ├── auth_provider.dart            # JWT 관리
│   │   ├── user_provider.dart            # GET /me
│   │   └── secure_storage_service.dart
│   ├── models/                           # Freezed
│   │   ├── preset.dart
│   │   ├── rule.dart
│   │   ├── job.dart
│   │   ├── job_progress.dart
│   │   └── job_item.dart
│   └── services/image_service.dart       # 압축 + 썸네일
├── features/
│   ├── splash/splash_screen.dart
│   ├── auth/auth_screen.dart
│   ├── camera/                           # ← 메인 진입점 (SNOW-style)
│   │   ├── camera_home_screen.dart       #   카메라 홈 (☰사이드바 + 컨셉칩 + 셔터)
│   │   ├── camera_screen.dart            #   독립 카메라 (workspace push용)
│   │   └── widgets/
│   │       ├── domain_drawer.dart        #   도메인 사이드바 (프리셋 목록)
│   │       └── concept_chips_bar.dart    #   수평 컨셉 칩 바
│   ├── domain_select/
│   │   ├── domain_select_screen.dart     #   별도 페이지 (fallback)
│   │   ├── presets_provider.dart          #   GET /presets
│   │   └── selected_preset_provider.dart #   선택된 도메인 ID 추적
│   ├── palette/
│   │   ├── palette_provider.dart          #   컨셉 토글 (카메라 홈에서도 사용)
│   │   └── palette_state.dart
│   ├── workspace/                        # 메인 작업 영역
│   │   ├── workspace_screen.dart
│   │   ├── workspace_provider.dart       # addPhotosFromFiles()
│   │   ├── workspace_state.dart
│   │   └── widgets/
│   │       ├── photo_grid.dart
│   │       ├── action_bar.dart           # ← TODO: Jobs API 연결
│   │       ├── progress_overlay.dart     # ← TODO: polling 연결
│   │       └── results_overlay.dart      # ← TODO: 결과 표시
│   ├── rules/
│   ├── jobs/
│   └── ...
└── shared/
```

---

## 개발 명령어

```bash
cd frontend

# 의존성 설치
flutter pub get

# 코드 생성 (Freezed/Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 분석
flutter analyze

# 실행
flutter run -d chrome          # 웹
flutter run -d <device_id>     # 모바일

# 테스트
flutter test
```

---

## API 엔드포인트 (전부 구현됨, 연동 필요)

| Method | Path | Frontend 연동 | 파일 |
|--------|------|-------------|------|
| POST | /auth/anon | ✅ 연동됨 | `auth_provider.dart` |
| GET | /me | ✅ 연동됨 | `user_provider.dart` |
| GET | /presets | ✅ 연동됨 | `presets_provider.dart` |
| GET | /presets/:id | ✅ 연동됨 | `preset_detail_provider.dart` |
| POST | /rules | ✅ 연동됨 | `rules_screen.dart` |
| GET | /rules | ✅ 연동됨 | `rules_screen.dart` |
| PUT | /rules/:id | ✅ 연동됨 | `rules_screen.dart` |
| DELETE | /rules/:id | ✅ 연동됨 | `rules_screen.dart` |
| POST | /jobs | ❌ **TODO** | `workspace_provider.dart` |
| POST | /jobs/:id/confirm-upload | ❌ **TODO** | `workspace_provider.dart` |
| POST | /jobs/:id/execute | ❌ **TODO** | `workspace_provider.dart` |
| GET | /jobs/:id | ❌ **TODO** | `workspace_provider.dart` |
| GET | /jobs | ❌ **TODO** | `history_provider.dart` |
| POST | /jobs/:id/cancel | ❌ **TODO** | `workspace_provider.dart` |

> Response envelope: `{ success: bool, data: T, error: string?, meta: { request_id, timestamp } }`
> S3ApiClient의 interceptor에서 자동으로 `data` 필드 추출.

---

## 완료 기준

### Phase 1 (UI + 기존 API) ✅
- [x] Auth: 자동 anon 로그인
- [x] Domain: 도메인 선택 화면
- [x] Workspace: 반응형 (데스크톱+모바일)
- [x] Photo grid: 이미지 선택 + 그리드
- [x] Concepts/Protect/Rules: 설정 UI
- [x] API 연결: S3ApiClient + JWT + envelope
- [x] Camera: SNOW-style 카메라 화면
- [x] Camera 홈 통합: 도메인 사이드바 + 컨셉 칩 바
- [x] flutter analyze: 0 errors

### Phase 2 (Jobs 실연동) ❌
- [ ] **카메라 실기기 테스트 (Android/iOS)**
- [ ] **POST /jobs → presigned URLs**
- [ ] **R2 presigned URL 업로드**
- [ ] **POST /confirm-upload + /execute**
- [ ] **GET /jobs/:id polling (3초)**
- [ ] **결과 이미지 표시**
- [ ] **Job 취소 (POST /cancel)**
- [ ] **에러 처리 (네트워크, 권한)**
