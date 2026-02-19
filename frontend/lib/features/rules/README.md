# Rules Feature

> 룰 CRUD (생성/조회/수정/삭제) + 룰 슬롯 제한 (Free 2/Pro 20)

## 파일

| 파일 | 역할 |
|------|------|
| `rules_screen.dart` | 룰 목록 + 생성/편집 다이얼로그 + 삭제 확인 |
| `rules_provider.dart` | Riverpod provider — GET/POST/PUT/DELETE /rules |
| `rules_provider.g.dart` | [generated] |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `POST /rules` | `workers/src/rules/rules.route.ts` | 룰 저장 (D1 INSERT) |
| `GET /rules` | `workers/src/rules/rules.route.ts` | 내 룰 목록 |
| `PUT /rules/:id` | `workers/src/rules/rules.route.ts` | 룰 수정 |
| `DELETE /rules/:id` | `workers/src/rules/rules.route.ts` | 룰 삭제 + 슬롯 반환 |

## Workers DO 연동

- `POST /rules` → `UserLimiterDO.checkRuleSlot()` + `incrementRuleSlot()`
- `DELETE /rules/:id` → `UserLimiterDO.decrementRuleSlot()`

## 기능

- 룰 카드: 이름, preset, 생성일, concept actions 칩 표시
- 룰 quota 표시: `X/2 rules` (Free) 또는 `X/20 rules` (Pro)
- 생성/편집 모달: 이름 + concept actions + protect concepts
- jobId 전달 시 "Continue to Job" 버튼 표시
