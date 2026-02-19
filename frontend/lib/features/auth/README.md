# Auth Feature

> 익명 인증 (POST /auth/anon) + JWT 토큰 관리

## 파일

| 파일 | 역할 |
|------|------|
| `auth_screen.dart` | 자동 로그인 화면 — mount 시 POST /auth/anon 호출, JWT 획득 후 /domain-select 이동 |
| `models/user_model.dart` | Freezed User 모델 (user_id, plan, credits, rule_slots, concurrent_jobs) |
| `models/user_model.freezed.dart` | [generated] Freezed 코드 |
| `models/user_model.g.dart` | [generated] JSON 직렬화 |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `POST /auth/anon` | `workers/src/auth/auth.route.ts` | 익명 유저 생성 + JWT 발급 |

## 상태 관리

- `core/auth/auth_provider.dart` — JWT 토큰 저장/조회 (SecureStorage)
- `core/auth/user_provider.dart` — GET /me 유저 데이터

## 흐름

```
앱 시작 → SplashScreen → AuthScreen
  → POST /auth/anon → JWT → SecureStorage 저장
  → GoRouter redirect → /domain-select
```
