# Splash Feature

> 앱 시작 시 2초 애니메이션 스플래시 화면

## 파일

| 파일 | 역할 |
|------|------|
| `splash_screen.dart` | 페이드+스케일 애니메이션, 2초 후 auth 상태에 따라 /auth 또는 /domain-select 이동 |

## Workers 연동

없음 (순수 UI)

## 흐름

```
앱 시작 → /splash → 2초 대기
  → JWT 있음 → /domain-select
  → JWT 없음 → /auth
```
