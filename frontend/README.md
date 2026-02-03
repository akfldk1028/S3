# S3 Frontend - Flutter App

## Feature-First Architecture

```
lib/
├── main.dart                    # 앱 진입점
├── app.dart                     # MaterialApp, 테마, 라우터 설정
│
├── common_widgets/              # 공유 위젯 (2개+ feature에서 사용)
├── constants/                   # 상수, 테마, API 엔드포인트
│   ├── app_colors.dart
│   ├── app_theme.dart
│   └── api_endpoints.dart
├── routing/                     # go_router 설정
│   └── app_router.dart
├── utils/                       # 유틸리티, 확장 함수
│
└── features/                    # 기능별 모듈
    ├── auth/
    │   ├── pages/
    │   │   ├── providers/       # Riverpod 상태관리
    │   │   ├── screens/         # 화면 위젯
    │   │   └── widgets/         # feature 전용 위젯
    │   ├── queries/             # GET 요청 (조회)
    │   ├── mutations/           # POST/PUT/DELETE (변경)
    │   └── models/              # 데이터 모델 (Freezed)
    ├── home/
    └── profile/
```

## Tech Stack

| 역할 | 패키지 | 버전 |
|------|--------|------|
| **UI 컴포넌트** | **shadcn_ui** | **^0.45.1** |
| 상태관리 | flutter_riverpod | ^2.6.1 |
| 코드생성 | riverpod_generator | ^2.6.2 |
| 라우팅 | go_router | ^14.6.2 |
| HTTP | dio | ^5.7.0 |
| 로컬저장 | hive_flutter | ^1.1.0 |
| 보안저장 | flutter_secure_storage | ^9.2.2 |
| 모델생성 | freezed | ^2.5.7 |

## Shadcn UI 사용법

### 주요 컴포넌트
```dart
import 'package:shadcn_ui/shadcn_ui.dart';

// Button
ShadButton(onPressed: () {}, child: Text('Click me'))
ShadButton.outline(onPressed: () {}, child: Text('Outline'))
ShadButton.ghost(onPressed: () {}, child: Text('Ghost'))

// Card
ShadCard(
  title: Text('Title'),
  description: Text('Description'),
  child: ...,
)

// Input
ShadInput(placeholder: Text('Enter text'))
ShadInputFormField(
  id: 'email',
  label: Text('Email'),
  validator: (v) => v.isEmpty ? 'Required' : null,
)

// Form
ShadForm(
  key: formKey,
  child: Column(children: [...]),
)

// Toast
ShadToaster.of(context).show(
  ShadToast(title: Text('Success!')),
);
```

### 테마 설정
```dart
ShadApp.materialRouter(
  theme: ShadThemeData(
    brightness: Brightness.light,
    colorScheme: const ShadSlateColorScheme.light(),
  ),
  darkTheme: ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: const ShadSlateColorScheme.dark(),
  ),
)
```

### 컬러 스킴 옵션
- `ShadSlateColorScheme` (기본)
- `ShadGrayColorScheme`
- `ShadZincColorScheme`
- `ShadNeutralColorScheme`
- `ShadStoneColorScheme`

## Quick Start

```powershell
cd C:\DK\S3\S3\frontend

# 의존성 설치
flutter pub get

# 코드 생성 (Freezed, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run
```

## 코드 생성

Freezed 모델이나 Riverpod Provider 수정 후:

```powershell
# 한 번 실행
dart run build_runner build --delete-conflicting-outputs

# 또는 watch 모드 (파일 변경 시 자동 생성)
dart run build_runner watch --delete-conflicting-outputs
```

## Query/Mutation 패턴

### Query (데이터 조회)
```dart
// features/auth/queries/get_me_query.dart
@riverpod
Future<User> getMeQuery(GetMeQueryRef ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/me');
  return User.fromJson(response.data);
}

// 사용
final userAsync = ref.watch(getMeQueryProvider);
userAsync.when(
  data: (user) => Text(user.name),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Mutation (데이터 변경)
```dart
// features/auth/mutations/login_mutation.dart
@riverpod
class LoginMutation extends _$LoginMutation {
  @override
  FutureOr<LoginResponse?> build() => null;

  Future<LoginResponse> call({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await ref.read(dioProvider).post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final result = LoginResponse.fromJson(response.data);
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// 사용
final mutation = ref.read(loginMutationProvider.notifier);
await mutation.call(email: email, password: password);
```

## 새 Feature 추가

```powershell
# 1. 폴더 구조 생성
$feature = "settings"
mkdir -p "lib/features/$feature/pages/providers"
mkdir -p "lib/features/$feature/pages/screens"
mkdir -p "lib/features/$feature/pages/widgets"
mkdir -p "lib/features/$feature/queries"
mkdir -p "lib/features/$feature/mutations"
mkdir -p "lib/features/$feature/models"
```

## 명명 규칙

| 타입 | 규칙 | 예시 |
|------|------|------|
| Screen | `*_screen.dart` | `login_screen.dart` |
| Widget | 기능명 | `login_form.dart` |
| Provider | `*_provider.dart` | `auth_provider.dart` |
| Query | `*_query.dart` | `get_me_query.dart` |
| Mutation | `*_mutation.dart` | `login_mutation.dart` |
| Model | `*_model.dart` | `user_model.dart` |

## 프로젝트 구조 상세

```
lib/
├── main.dart
├── app.dart
│
├── common_widgets/
│   └── .gitkeep
│
├── constants/
│   ├── api_endpoints.dart       # API 엔드포인트 상수
│   ├── app_colors.dart          # 색상 상수
│   └── app_theme.dart           # 테마 설정
│
├── routing/
│   └── app_router.dart          # go_router 설정
│
├── utils/
│   └── .gitkeep
│
└── features/
    ├── auth/
    │   ├── models/
    │   │   └── user_model.dart
    │   ├── mutations/
    │   │   └── login_mutation.dart
    │   ├── pages/
    │   │   ├── providers/
    │   │   │   └── auth_provider.dart
    │   │   ├── screens/
    │   │   │   └── login_screen.dart
    │   │   └── widgets/
    │   └── queries/
    │       └── get_me_query.dart
    │
    ├── home/
    │   └── pages/screens/
    │       └── home_screen.dart
    │
    └── profile/
        └── pages/screens/
            └── profile_screen.dart
```

## 환경 설정

| 항목 | 값 |
|------|-----|
| Flutter SDK | 3.38.9 |
| Dart SDK | 3.10.8 |
| 프로젝트 경로 | `C:\DK\S3\S3\frontend` |

## Commands

| 명령어 | 설명 |
|--------|------|
| `flutter pub get` | 의존성 설치 |
| `flutter run` | 디버그 실행 |
| `flutter run --release` | 릴리즈 실행 |
| `flutter build apk` | APK 빌드 |
| `dart run build_runner build` | 코드 생성 |
| `flutter test` | 테스트 실행 |
