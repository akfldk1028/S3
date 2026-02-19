# Settings Feature

> 사용자 계정 정보 + 플랜 비교 + 다크모드 + 로그아웃

## 파일

| 파일 | 역할 |
|------|------|
| `settings_screen.dart` | 계정(ID/plan/credits/slots) + 플랜비교 + 환경설정 + 로그아웃 |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /me` | `workers/src/user/user.route.ts` | 유저 상태 (credits, plan, rule_slots) |

## 섹션

1. **ACCOUNT**: User ID (마스킹), plan 뱃지, credits (⚡), rule slots 진행바
2. **PLAN**: Free vs Pro 비교 + "Upgrade to Pro" 버튼
3. **PREFERENCES**: 다크 모드 토글, 앱 버전
4. **SIGN OUT**: 로그아웃 확인 다이얼로그 → JWT 삭제 → /auth 이동
