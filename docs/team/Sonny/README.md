# Sonny — 통합/검증 확인사항

> 브랜치: `Sonny` → DK-A에서 변경된 내용 머지 필요

## 머지 시 확인

### 1. 충돌 예상 파일
| 파일 | 변경 내용 |
|------|----------|
| `frontend/lib/features/rules/rules_screen.dart` | action 드롭다운 + 프롬프트 입력 UI |
| `frontend/lib/core/models/rule.dart` | ConceptAction 주석 변경 |
| `workers/src/jobs/jobs.route.ts` | R2 키 패턴 변경 |
| `workers/src/jobs/jobs.service.ts` | R2 키 패턴 + preset 파라미터 |
| `workers/src/jobs/jobs.validator.ts` | action enum 제한 |
| `workers/src/_shared/types.ts` | action 타입 union |

### 2. 새로 추가된 파일
| 파일 | 설명 |
|------|------|
| `gpu-worker/engine/generator.py` | Gemini API inpaint 모듈 |
| `docs/ops/*` | 운영 가이드 (6개) |
| `docs/team/*/README.md` | 팀원별 확인사항 |
| `docs/superpowers/specs/` | Gemini inpaint 설계 spec |
| `docs/superpowers/plans/` | E2E 감사 + Gemini plan |

### 3. E2E 검증 체크리스트
```bash
# Workers health
curl -s https://s3-workers.clickaround8.workers.dev/health

# Auth
curl -s -X POST https://s3-workers.clickaround8.workers.dev/auth/anon \
  -H "Content-Type: application/json"

# Presets
curl -s https://s3-workers.clickaround8.workers.dev/presets \
  -H "Authorization: Bearer <TOKEN>"
```

GPU 테스트는 Runpod endpoint 필요 → `docs/ops/gpu-worker.md` 참조

### 4. 핵심 변경 요약
- **recolor + generate** 두 가지 action 지원
- R2 키: `{userId}/{preset}/{jobId}/originals|results|previews/`
- GPU Worker: SAM3 마스크 → Gemini API inpaint (프롬프트 기반 질감 생성)

## 참고 문서
- `docs/HANDOFF-20260329.md` — 전체 핸드오프
- `docs/ops/README.md` — 운영 가이드 목차
