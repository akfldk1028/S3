# Onboarding Feature

> 최초 1회 3페이지 가이드 화면

## 파일

| 파일 | 역할 |
|------|------|
| `onboarding_screen.dart` | PageView 호스트 + 점 인디케이터 + Skip/CTA 버튼 |
| `onboarding_provider.dart` | 온보딩 완료 상태 Riverpod provider |
| `onboarding_provider.g.dart` | [generated] |
| `widgets/onboarding_page_1.dart` | 1페이지 |
| `widgets/onboarding_page_2.dart` | 2페이지 |
| `widgets/onboarding_page_3.dart` | 3페이지 |

## Workers 연동

없음 (로컬 상태만)

## 흐름

```
HomeScreen → 온보딩 미완료 → /onboarding
  → 3페이지 슬라이드 → "시작하기" → 완료 저장 → /home
```
