# JP — Frontend (Flutter) 확인사항

> 브랜치: `JP_Front` → DK-A에서 변경된 내용 머지 필요

## 반드시 확인

### 1. rules_screen.dart 변경됨
- `_AddConceptActionDialog`에 action 드롭다운 변경: `recolor` + `generate` (AI 생성)
- `generate` 선택 시 프롬프트 텍스트 입력 + 추천 칩 표시
- **파일**: `frontend/lib/features/rules/rules_screen.dart`

### 2. API 호출 변경 없음 — 기존 코드 호환
- `executeJob()` 호출 형태 동일: `concepts: {action, value}`
- `action`이 `"recolor"` 또는 `"generate"` — Workers validator가 검증

### 3. rule.dart 주석 업데이트
- `ConceptAction.action` 주석: `'recolor' | 'generate'` (이전: tone/texture/remove)
- **파일**: `frontend/lib/core/models/rule.dart:62`

### 4. QuickApply 기본값 변경
- `_executeWithoutRule()`에서 value 기본값: `''` → `'#CCCCCC'`
- **파일**: `rules_screen.dart:90`

### 5. R2 키 패턴 변경됨 — Flutter 영향 없음
- presigned URL은 Workers가 생성 → Flutter는 받아서 PUT만 하므로 변경 없음

## 추천 프롬프트 칩 도메인별 분리 (TODO)
현재 interior 프롬프트만 하드코딩:
```dart
['화이트 대리석', '원목 헤링본', '콘크리트', '벽돌 패턴', '타일']
```
seller 도메인 추가 필요:
```dart
['무광 화이트', '그라데이션 배경', '스튜디오 조명']
```
→ preset 정보를 dialog에 전달해서 분기

## 참고 문서
- `docs/ops/architecture.md` — API 목록
- `docs/ops/e2e-test.md` — curl 테스트 방법
- `docs/superpowers/specs/2026-03-29-gemini-inpaint-design.md` — 전체 설계
