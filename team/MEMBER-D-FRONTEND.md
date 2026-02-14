# 팀원 D: Frontend — Flutter UI + 상태관리 + Mock API 연동

> **담당**: Flutter 앱 전체 (Auth UI, 팔레트, 업로드, 진행률, 결과, 세트)
> **브랜치**: `feat/frontend-core`
> **동시 작업**: Mock API로 UI 먼저 구현 → Workers 완성 후 실 API 연결

---

## 프로젝트 컨텍스트 (필독)

S3는 "도메인 팔레트 엔진 기반 세트 생산 앱"이다.
- **5단 파이프라인**: Palette → Instances → Protect → Rules → Output Sets
- **Frontend = Workers API만 호출**: GPU Worker 직접 호출 절대 금지
- **SSoT**: `workflow.md` — 섹션 4(데이터 흐름), 섹션 6(API 스키마)
- **Tech Stack**: Flutter 3.38.9, Riverpod 3, Freezed 3, GoRouter, ShadcnUI

### 기존 코드 주의사항

> **기존 `frontend/` 코드의 일부는 Supabase 기반(v2.0)으로 작성되어 있습니다.**
> - `api_endpoints.dart`는 v3.0으로 재작성 완료
> - 하지만 `auth/`, `providers/` 등에 Supabase SDK 참조가 남아있을 수 있음
> - **Supabase SDK 참조를 발견하면 무시하고 새로 작성하세요**
> - v3.0에서는 모든 통신이 Workers REST API (`Dio` HTTP)를 통해 이루어집니다
> - `supabase_flutter` 패키지 사용 금지 → `dio` + JWT 토큰 사용

---

## Cloudflare MCP 활용 (필수)

> Frontend 팀이라도 Cloudflare MCP가 필수입니다. Workers API 연동 시 에러 디버깅에 씁니다.

### API 연동 실패 시: Workers 로그 확인

```
"s3-api Workers에서 /auth/anon 관련 에러 보여줘"
→ cloudflare-observability: query_worker_observability

"Workers에서 400 에러가 나는데 원인 알려줘"
→ query_worker_observability → 에러 로그 분석
```

### Flutter/Riverpod 문서 조회

```
"Riverpod 3에서 @riverpod annotation 사용법"
→ context7: resolve-library-id → query-docs

"Dio interceptor에서 401 에러 처리 방법"
→ context7: query-docs
```

### API 계약 확인

```
"workflow.md에서 POST /jobs의 request/response 형식 알려줘"
→ 로컬 파일 읽기 (MCP 불필요)
```

> **팁**: Workers가 반환하는 에러 코드는 `workflow.md` 섹션 6.6 에러 카탈로그 참조

---

## 병렬 작업 전략: UI First → API Later

```
Phase 1 (Week 1): UI + Mock API
───────────────────────────────────
화면 레이아웃 → 상태관리(Riverpod) → Mock API Client
팔레트 UI → 업로드 UI → 진행률 UI → 결과 UI

Phase 2 (Week 2): 실 API 연결
───────────────────────────────────
Mock → 실 API 교체 (base URL만 변경)
Auth anon → Presets → Rules CRUD → Jobs → Polling
```

---

## 담당 디렉토리 구조

```
frontend/lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart       ← [구현] Dio + JWT interceptor
│   │   └── mock_api_client.dart  ← [구현] Phase 1용 Mock
│   ├── auth/
│   │   ├── auth_provider.dart    ← [구현] Riverpod Auth state
│   │   └── auth_service.dart     ← [구현] POST /auth/anon
│   ├── models/
│   │   ├── user.dart             ← [구현] Freezed User model
│   │   ├── preset.dart           ← [구현] Freezed Preset model
│   │   ├── rule.dart             ← [구현] Freezed Rule model
│   │   └── job.dart              ← [구현] Freezed Job model
│   ├── router/
│   │   └── app_router.dart       ← [구현] GoRouter + auth guard
│   └── constants.dart            ← [구현] base URL, config
├── features/
│   ├── auth/                     ← [구현] 인증 (anon auto-login)
│   │   ├── auth_screen.dart
│   │   └── onboarding_screen.dart
│   ├── domain_select/            ← [구현] 도메인 선택 (건축/셀러)
│   │   └── domain_select_screen.dart
│   ├── palette/                  ← [구현] 팔레트 + 인스턴스 + 보호
│   │   ├── palette_screen.dart
│   │   ├── concept_chip.dart
│   │   ├── instance_card.dart
│   │   └── protect_toggle.dart
│   ├── upload/                   ← [구현] 이미지 선택 + R2 업로드
│   │   └── upload_screen.dart
│   ├── rules/                    ← [구현] 룰 설정 + 저장/불러오기
│   │   ├── rule_editor_screen.dart
│   │   └── rule_list_screen.dart
│   ├── jobs/                     ← [구현] Job 실행 + 진행률 polling
│   │   ├── job_progress_screen.dart
│   │   └── job_provider.dart
│   ├── results/                  ← [구현] 결과 표시 + Before/After
│   │   └── result_screen.dart
│   └── export/                   ← [구현] 세트 내보내기
│       └── export_screen.dart
└── shared/                       ← [구현] 공통 위젯
    ├── widgets/
    │   ├── s3_button.dart
    │   ├── s3_card.dart
    │   └── loading_indicator.dart
    └── theme/
        └── app_theme.dart
```

---

## 구현 순서

### Step 1: 프로젝트 기반 (Freezed 모델 + API Client)

#### Freezed 모델 정의

```dart
// core/models/job.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'job.freezed.dart';
part 'job.g.dart';

@freezed
class Job with _$Job {
  const factory Job({
    required String jobId,
    required String status,    // created|uploaded|queued|running|done|failed|canceled
    required String preset,
    required JobProgress progress,
    @Default([]) List<JobOutput> outputsReady,
  }) = _Job;
  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}

@freezed
class JobProgress with _$JobProgress {
  const factory JobProgress({
    required int done,
    required int failed,
    required int total,
  }) = _JobProgress;
  factory JobProgress.fromJson(Map<String, dynamic> json) => _$JobProgressFromJson(json);
}

// 유사하게: User, Preset, Rule 모델도 정의
```

#### Mock API Client (Phase 1)

```dart
// core/api/mock_api_client.dart
class MockApiClient implements ApiClient {
  @override
  Future<AuthResponse> authAnon() async {
    await Future.delayed(Duration(milliseconds: 300));
    return AuthResponse(userId: 'u_mock123', token: 'mock-jwt-token');
  }

  @override
  Future<List<Preset>> getPresets() async {
    return [
      Preset(id: 'interior', name: '건축/인테리어', conceptCount: 12),
      Preset(id: 'seller', name: '쇼핑/셀러', conceptCount: 6),
    ];
  }

  @override
  Future<Job> getJob(String jobId) async {
    // 진행률 시뮬레이션
    return Job(
      jobId: jobId, status: 'running', preset: 'interior',
      progress: JobProgress(done: 17, failed: 0, total: 30),
    );
  }

  // ... 나머지 Mock 구현
}
```

#### 실제 API Client (Phase 2)

```dart
// core/api/api_client.dart
class S3ApiClient implements ApiClient {
  final Dio _dio;

  S3ApiClient({required String baseUrl, String? token})
    : _dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  @override
  Future<AuthResponse> authAnon() async {
    final res = await _dio.post('/auth/anon');
    return AuthResponse.fromJson(res.data['data']);
  }

  // ... 14개 API 엔드포인트 매핑
}
```

### Step 2: Auth + 온보딩

```dart
// features/auth/auth_screen.dart
// 앱 최초 실행 → 자동으로 POST /auth/anon
// JWT를 flutter_secure_storage에 저장
// 성공 → 도메인 선택 화면으로 이동
// 실패 → 재시도 버튼
```

### Step 3: 도메인 선택 + 팔레트 UI

```dart
// features/domain_select/domain_select_screen.dart
// GET /presets → 도메인 카드 2개 (건축/셀러)
// 선택 → GET /presets/:id → 상세 로드
// → palette_screen.dart로 이동

// features/palette/palette_screen.dart
// concept_chip.dart: 각 concept 버튼 (Wall, Floor, Tile...)
// instance_card.dart: 인스턴스 #1~#N 카드
// protect_toggle.dart: 보호 on/off 토글
//
// 이 화면은 로컬 상태만 관리 (서버에 보내지 않음)
// "적용" 버튼 누를 때 POST /jobs/:id/execute로 전송
```

### Step 4: 이미지 업로드

```dart
// features/upload/upload_screen.dart
// 1. 사진 선택 (image_picker 또는 file_picker)
// 2. POST /jobs { preset, item_count } → presigned URLs
// 3. 각 이미지를 presigned URL로 R2 직접 PUT (http 패키지)
// 4. POST /jobs/:id/confirm-upload
//
// 진행률 표시: N/total 업로드 완료
```

### Step 5: 룰 설정 + 저장/불러오기

```dart
// features/rules/rule_editor_screen.dart
// concept별 action 선택 (recolor, tone, texture, remove)
// value 선택 (색상 팔레트, 슬라이더 등)
// 저장: POST /rules
// 불러오기: GET /rules → 목록 → 선택 → rule_id로 적용

// features/rules/rule_list_screen.dart
// 내 룰 목록 (GET /rules)
// 삭제: DELETE /rules/:id
```

### Step 6: Job 실행 + 진행률 (Polling)

```dart
// features/jobs/job_provider.dart (Riverpod)
@riverpod
class JobNotifier extends _$JobNotifier {
  Timer? _timer;

  @override
  AsyncValue<Job> build(String jobId) {
    _startPolling(jobId);
    return const AsyncLoading();
  }

  void _startPolling(String jobId) {
    _timer = Timer.periodic(Duration(seconds: 3), (_) async {
      final job = await ref.read(apiClientProvider).getJob(jobId);
      state = AsyncData(job);
      if (job.status == 'done' || job.status == 'failed') {
        _timer?.cancel();
      }
    });
  }
}

// features/jobs/job_progress_screen.dart
// 진행바: done / total
// 완료된 이미지 미리보기 (결과 URL)
// 실패 시 에러 메시지
```

### Step 7: 결과 + 세트 내보내기

```dart
// features/results/result_screen.dart
// Before/After 비교 슬라이더
// 갤러리 그리드
// 다운로드 버튼

// features/export/export_screen.dart
// 템플릿 선택 (시안3안팩, 전후비교, 상품팩 등)
// 로컬에서 이미지 조합 → 저장/공유
```

---

## 화면 Flow (GoRouter)

```
/                      → AuthScreen (자동 anon login)
/onboarding            → OnboardingScreen (최초 1회)
/domains               → DomainSelectScreen
/palette/:presetId     → PaletteScreen (concept + protect)
/upload/:jobId         → UploadScreen
/rules                 → RuleListScreen
/rules/edit            → RuleEditorScreen
/jobs/:jobId/progress  → JobProgressScreen
/jobs/:jobId/results   → ResultScreen
/export/:jobId         → ExportScreen
```

---

## 환경 설정

```bash
cd frontend/
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Phase 1: Mock API
# constants.dart에서 useMock = true

# Phase 2: 실 API
# constants.dart에서 baseUrl = 'http://localhost:8787' (Workers 로컬)
# 또는 배포된 Workers URL

flutter run -d chrome
```

---

## API 스키마 참고 (workflow.md 섹션 6)

| Method | Path | 용도 |
|--------|------|------|
| POST | /auth/anon | JWT 획득 |
| GET | /me | 유저 상태 |
| GET | /presets | 도메인 목록 |
| GET | /presets/:id | 프리셋 상세 |
| POST | /rules | 룰 저장 |
| GET | /rules | 내 룰 목록 |
| PUT | /rules/:id | 룰 수정 |
| DELETE | /rules/:id | 룰 삭제 |
| POST | /jobs | Job 생성 + presigned URLs |
| POST | /jobs/:id/confirm-upload | 업로드 확인 |
| POST | /jobs/:id/execute | 룰 적용 실행 |
| GET | /jobs/:id | 상태/진행률 |
| POST | /jobs/:id/cancel | 취소 |

> Response envelope: `{ success: bool, data: T, error: string?, meta: { request_id, timestamp } }`

---

## 코딩 규칙

1. **Feature-First 구조**: 각 feature = 독립 폴더 (screen + provider + widgets)
2. **Riverpod 3**: `@riverpod` annotation 사용 (code generation)
3. **Freezed 3**: 모든 데이터 모델은 Freezed로 정의
4. **GoRouter**: 라우팅 + auth guard
5. **ShadcnUI**: 디자인 시스템 위젯 사용
6. **API는 interface로 추상화**: `ApiClient` interface → `MockApiClient` / `S3ApiClient`
7. **로컬 상태와 서버 상태 분리**: palette 설정 = 로컬, job 상태 = 서버

---

## 완료 기준

**Phase 1 (Mock API):**
- [ ] Auth: 자동 anon 로그인 동작
- [ ] Domain: 도메인 선택 화면 (건축/셀러)
- [ ] Palette: concept 선택 + protect 토글 UI
- [ ] Upload: 이미지 선택 + 업로드 진행률 UI
- [ ] Rules: 룰 편집 + 목록 UI
- [ ] Jobs: 진행률 바 + polling 시뮬레이션
- [ ] Results: Before/After 비교 UI
- [ ] Export: 템플릿 선택 UI
- [ ] Mock API 전체 연동
- [ ] `flutter analyze` 에러 없음

**Phase 2 (실 API):**
- [ ] Mock → S3ApiClient 교체
- [ ] R2 presigned URL 업로드 동작
- [ ] Polling으로 실제 진행률 갱신
- [ ] 결과 이미지 표시
