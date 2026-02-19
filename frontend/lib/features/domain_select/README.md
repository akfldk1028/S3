# Domain Select Feature

> 도메인 프리셋 선택 (건축/인테리어, 쇼핑/셀러)

## 파일

| 파일 | 역할 |
|------|------|
| `domain_select_screen.dart` | 2열 그리드로 프리셋 카드 표시, 선택 시 /palette 이동 |
| `presets_provider.dart` | GET /presets API 호출 Riverpod provider |
| `presets_provider.g.dart` | [generated] |
| `selected_preset_provider.dart` | 현재 선택된 도메인 ID 추적 (카메라 홈 사이드바용) |
| `selected_preset_provider.g.dart` | [generated] |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /presets` | `workers/src/presets/presets.route.ts` | 도메인 프리셋 목록 |

## 흐름

### 기존 (별도 페이지)
```
/domain-select → GET /presets → 카드 2개 (interior/seller)
  → 탭 → /palette?presetId=interior
```

### 카메라 홈 통합 (사이드바)
```
카메라 홈 ☰ 사이드바 → presetsProvider 목록 표시
  → 탭 → selectedPresetProvider.select(id) → paletteProvider.reset()
  → ConceptChipsBar에 해당 도메인 concepts 표시
  → 사진 촬영 후 → /upload?presetId=... (domain-select 스킵)
```

## 참고

`selectedPresetProvider`는 카메라 홈의 `DomainDrawer`와 `ConceptChipsBar`에서 사용됨.
도메인 변경 시 자동으로 `paletteProvider.reset()` 호출하여 컨셉 선택 초기화.
