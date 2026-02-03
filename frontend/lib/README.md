# S3 Frontend - Flutter App Structure

## Feature-First Architecture

```
lib/
├── main.dart                    # 앱 진입점
├── app.dart                     # MaterialApp 설정
│
├── common_widgets/              # 공유 위젯
│   ├── buttons/
│   ├── inputs/
│   └── cards/
│
├── constants/                   # 상수, 테마
│   ├── app_colors.dart
│   ├── app_theme.dart
│   └── api_endpoints.dart
│
├── routing/                     # go_router 설정
│   ├── app_router.dart
│   └── guards/
│
├── utils/                       # 유틸리티
│   ├── extensions/
│   └── validators.dart
│
└── features/                    # 기능별 모듈
    ├── auth/
    ├── home/
    └── profile/
```

## Feature 내부 구조

```
features/auth/
├── pages/                       # UI 레이어
│   ├── providers/               # Riverpod 상태관리
│   │   └── auth_provider.dart
│   ├── screens/                 # 화면 위젯
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   └── widgets/                 # feature 전용 위젯
│       ├── login_form.dart
│       └── social_buttons.dart
│
├── queries/                     # GET 요청 (조회)
│   └── get_me_query.dart
│
├── mutations/                   # POST/PUT/DELETE (변경)
│   ├── login_mutation.dart
│   └── register_mutation.dart
│
└── models/                      # 데이터 모델
    └── user_model.dart
```

## Query/Mutation 패턴

### Query (조회)
```dart
// queries/get_me_query.dart
@riverpod
Future<User> getMe(GetMeRef ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/me');
  return User.fromJson(response.data);
}

// 사용
final user = ref.watch(getMeProvider);
user.when(
  data: (user) => Text(user.name),
  loading: () => CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

### Mutation (변경)
```dart
// mutations/login_mutation.dart
@riverpod
class LoginMutation extends _$LoginMutation {
  @override
  FutureOr<User?> build() => null;

  Future<User> call({required String email, required String password}) async {
    state = const AsyncLoading();

    final dio = ref.read(dioProvider);
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final user = User.fromJson(response.data);
    state = AsyncData(user);
    return user;
  }
}

// 사용
final loginMutation = ref.read(loginMutationProvider.notifier);
await loginMutation.call(email: email, password: password);
```

## 새 Feature 추가 방법

```bash
# 1. 폴더 구조 생성
mkdir -p lib/features/settings/pages/{providers,screens,widgets}
mkdir -p lib/features/settings/{queries,mutations,models}

# 2. 파일 생성
touch lib/features/settings/pages/screens/settings_screen.dart
touch lib/features/settings/pages/providers/settings_provider.dart
touch lib/features/settings/models/settings_model.dart
```

## Tech Stack

| 역할 | 패키지 |
|------|--------|
| 상태관리 | flutter_riverpod + riverpod_annotation |
| 코드생성 | riverpod_generator + freezed |
| HTTP | dio |
| 라우팅 | go_router |
| 로컬저장 | hive_flutter |
| 보안저장 | flutter_secure_storage |

## 명명 규칙

| 타입 | 규칙 | 예시 |
|------|------|------|
| Screen | `*_screen.dart` | `login_screen.dart` |
| Widget | `*_widget.dart` 또는 기능명 | `login_form.dart` |
| Provider | `*_provider.dart` | `auth_provider.dart` |
| Query | `get_*_query.dart` | `get_me_query.dart` |
| Mutation | `*_mutation.dart` | `login_mutation.dart` |
| Model | `*_model.dart` | `user_model.dart` |

## 폴더별 책임

| 폴더 | 책임 | 예시 |
|------|------|------|
| `common_widgets/` | 2개 이상 feature에서 사용하는 위젯 | AppButton, AppTextField |
| `constants/` | 앱 전역 상수, 테마 | Colors, TextStyles |
| `routing/` | 라우팅 설정, 가드 | AuthGuard, AppRouter |
| `utils/` | 헬퍼 함수, 확장 | StringExtension, Validators |
| `features/*/pages/` | UI 관련 코드 | Screens, Widgets, Providers |
| `features/*/queries/` | 데이터 조회 (GET) | API GET 호출 |
| `features/*/mutations/` | 데이터 변경 (POST/PUT/DELETE) | API 변경 호출 |
| `features/*/models/` | 데이터 모델 | Freezed 모델 |
