# Palette Feature

> Concept 선택 + 인스턴스 + Protect 토글

## 파일

| 파일 | 역할 |
|------|------|
| `palette_screen.dart` | Concept 칩 선택 + 인스턴스 드롭다운 + Protect 토글 |
| `palette_provider.dart` | 팔레트 상태 Riverpod notifier (toggleConcept/toggleProtect/reset) |
| `palette_provider.g.dart` | [generated] |
| `palette_state.dart` | Freezed 상태 (selectedConcepts, protectConcepts) |
| `palette_state.freezed.dart` | [generated] |
| `palette_state.g.dart` | [generated] |

## Workers 연동

| API | Workers 파일 | 설명 |
|-----|-------------|------|
| `GET /presets/:id` | `workers/src/presets/presets.route.ts` | 프리셋 상세 (concepts, protect_defaults) |

## 흐름

### 별도 페이지 (기존)
```
/palette?presetId=interior
  → GET /presets/interior → concepts 12개 로드
  → FilterChip으로 concept 선택
  → 각 concept: 인스턴스(#1~#5) + protect 토글
  → "Next" → /upload
```

### 카메라 홈 통합 (새 흐름)
```
카메라 홈 → DomainDrawer에서 도메인 선택
  → ConceptChipsBar에 concepts 표시 (paletteProvider watch)
  → 칩 탭 → paletteProvider.toggleConcept()
  → 사진 촬영 후 proceed → /upload (palette 페이지 스킵 가능)
```

## 참고

`paletteProvider`는 카메라 홈의 `ConceptChipsBar`에서도 사용됨.
`selectedPresetProvider` 도메인 변경 시 `paletteProvider.reset()` 자동 호출.
