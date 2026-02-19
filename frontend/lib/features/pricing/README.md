# Pricing Feature

> 요금제 비교 (Free vs Pro) + 업그레이드 + 크레딧 충전

## 파일

| 파일 | 역할 |
|------|------|
| `pricing_screen.dart` | Free/Pro 플랜 비교 화면 (반응형: 600px 기준) |
| `widgets/pricing_card.dart` | 단일 플랜 카드 컴포넌트 |
| `widgets/plan_upgrade_flow.dart` | 업그레이드 다이얼로그 |
| `widgets/credit_topup_dialog.dart` | 크레딧 충전 다이얼로그 |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /me` | `workers/src/user/user.route.ts` | 현재 plan, credits 조회 |

## BM 모델

| 항목 | Free | Pro |
|------|------|-----|
| 룰 슬롯 | 2 | 20 |
| 배치 이미지 | 10 | 200 |
| 동시 Job | 1 | 3 |
