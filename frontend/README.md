# S3 Frontend — Flutter App

> Flutter 3.38.9 + Riverpod 3 + ShadcnUI 기반 크로스 플랫폼 앱 (iOS/Android/Web)

## Current Status (~30%)

### Implemented
- [x] 프로젝트 기본 구조 (feature-based architecture)
- [x] Routing — GoRouter (`/`, `/login`, `/profile`)
- [x] Auth — LoginScreen + SecureStorage 토큰 관리
- [x] Theme — ShadcnUI Slate color scheme (Light/Dark)
- [x] HTTP Client — Dio + Riverpod providers
- [x] Models — Freezed data classes (User, LoginRequest, LoginResponse)

### TODO
- [ ] Segmentation feature (핵심 기능)
  - [ ] SegmentationScreen — 이미지 선택 + 프롬프트 입력
  - [ ] ResultDetailScreen — 결과 오버레이 표시
  - [ ] ImagePickerWidget, PromptInputWidget, MaskOverlayWidget, ResultCardWidget
  - [ ] SegmentationProvider, RunSegmentationMutation
- [ ] Gallery feature — 결과 목록/갤러리
- [ ] Supabase Auth 연동 (현재 커스텀 auth → Supabase Auth로 전환)
- [ ] 실시간 추론 상태 알림 (Supabase Realtime)
- [ ] 이미지 캐싱 + 오프라인 지원
- [ ] Error handling + Loading states

---

## Tech Stack

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_riverpod` | 3.1.0 | State management |
| `go_router` | 17.1.0 | Navigation/Routing |
| `dio` | 5.7.0 | HTTP client |
| `shadcn_ui` | 0.45.1 | UI component library |
| `flutter_secure_storage` | 10.0.0 | Secure token storage |
| `hive_flutter` | 1.1.0 | Local persistence |
| `freezed_annotation` | 3.1.0 | Data class generation |

---

## Architecture

```
lib/
├── main.dart                     # Entry: Hive init + ProviderScope
├── app.dart                      # ShadApp root widget
├── constants/
│   ├── api_endpoints.dart        # Edge API endpoints
│   ├── app_colors.dart           # Color palette
│   └── app_theme.dart            # ShadcnUI theme
├── routing/
│   └── app_router.dart           # GoRouter configuration
├── common_widgets/               # Reusable widgets
├── utils/                        # Helpers
└── features/
    ├── auth/                     # 인증
    │   ├── models/               # Freezed models
    │   ├── mutations/            # Write operations (login, register)
    │   ├── queries/              # Read operations (getMe)
    │   └── pages/
    │       ├── providers/        # Riverpod providers
    │       ├── screens/          # Full pages
    │       └── widgets/          # Feature-specific widgets
    ├── segmentation/             # ★ 핵심 — 세그멘테이션
    ├── gallery/                  # 결과 갤러리
    ├── home/                     # 홈
    └── profile/                  # 프로필
```

### Feature 패턴

각 feature는 동일한 구조를 따른다:
```
feature/
├── models/          # Freezed data classes (immutable)
├── mutations/       # POST/PUT/DELETE operations (Riverpod AsyncNotifier)
├── queries/         # GET operations (Riverpod FutureProvider)
└── pages/
    ├── providers/   # UI state providers
    ├── screens/     # Full-page widgets (Scaffold)
    └── widgets/     # Feature-specific reusable widgets
```

---

## Code Patterns

### Riverpod Provider (Query)
```dart
@riverpod
Future<List<ResultSummary>> getResults(Ref ref, {int page = 1}) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get(ApiEndpoints.results, queryParameters: {'page': page});
  final envelope = ApiResponse.fromJson(response.data);
  return (envelope.data as List).map((e) => ResultSummary.fromJson(e)).toList();
}
```

### Freezed Model
```dart
@freezed
class SegmentationResult with _$SegmentationResult {
  const factory SegmentationResult({
    required String id,
    required String sourceImageUrl,
    required String maskImageUrl,
    required String textPrompt,
    required List<String> labels,
    required String status,
    required DateTime createdAt,
  }) = _SegmentationResult;

  factory SegmentationResult.fromJson(Map<String, dynamic> json) =>
      _$SegmentationResultFromJson(json);
}
```

### ShadcnUI 사용법
```dart
ShadButton(
  onPressed: () => ref.read(loginMutationProvider.notifier).login(email, password),
  child: const Text('Login'),
),
```

---

## API 연동

- **Base URL**: Edge Worker URL (`api_endpoints.dart`) — **Edge = Full API (유일한 API 서버)**
- **Auth**: **Supabase Auth SDK 직접 사용** (`supabase_flutter` 패키지)
  - 로그인/회원가입은 HTTP 엔드포인트가 아닌 SDK 메서드 호출
  - `supabase.auth.signInWithPassword()`, `supabase.auth.signUp()` 등
- **Edge API 호출**: Supabase JWT → `Authorization: Bearer <token>`
  - Edge가 모든 비즈니스 로직 처리 (CRUD, R2 업로드, 크레딧 확인, Backend 추론 프록시)
  - Backend(Vast.ai)를 직접 호출하지 않음
- **HTTP Client**: Dio + interceptors (token refresh)
- 상세 API 스펙: `docs/contracts/api-contracts.md`

## 의존하는 계약

| 대상 | 설명 | 파일 |
|------|------|------|
| Frontend → Edge API | 세그멘테이션 요청, 결과 조회 | `docs/contracts/api-contracts.md` |
| Frontend → Supabase Auth | 로그인/회원가입 (SDK) | `supabase/config.toml` |
| Frontend → Supabase Realtime | 추론 상태 실시간 구독 | `supabase/migrations/` |

---

## Commands

```bash
# 앱 실행
flutter run

# 코드 생성 (Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 코드 생성 (watch 모드)
dart run build_runner watch --delete-conflicting-outputs

# 테스트
flutter test

# 빌드
flutter build apk          # Android
flutter build ios           # iOS
flutter build web           # Web
```

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| File | snake_case | `segmentation_screen.dart` |
| Class | PascalCase | `SegmentationScreen` |
| Variable | camelCase | `imageUrl` |
| Provider | camelCase + Provider suffix | `segmentationProvider` |
| Freezed model | PascalCase | `SegmentationResult` |
| Route | lowercase kebab | `/segment`, `/results/:id` |
