/// S3 API Endpoints — v3.0 (Cloudflare Workers)
///
/// SSoT: workflow.md 섹션 6
/// 모든 통신은 Workers REST API를 통해. Supabase SDK 제거됨.
class ApiEndpoints {
  ApiEndpoints._();

  /// Workers API Base URL
  /// 로컬: http://localhost:8787
  /// 프로덕션: https://s3-api.your-domain.workers.dev
  static const baseUrl = 'http://localhost:8787';

  // ── Auth (1개) ────────────────────────────────────────
  /// POST — 익명 유저 생성 + JWT 발급
  static const authAnon = '/auth/anon';

  // ── User (1개) ────────────────────────────────────────
  /// GET — 유저 상태 (credits, plan, rule_slots)
  static const me = '/me';

  // ── Presets (2개) ─────────────────────────────────────
  /// GET — 도메인 프리셋 목록
  static const presets = '/presets';

  /// GET — 프리셋 상세 (concepts, protect, templates)
  static String presetById(String id) => '/presets/$id';

  // ── Rules (4개) ───────────────────────────────────────
  /// POST — 룰 저장 / GET — 내 룰 목록
  static const rules = '/rules';

  /// PUT — 룰 수정 / DELETE — 룰 삭제
  static String ruleById(String id) => '/rules/$id';

  // ── Jobs (6개) ────────────────────────────────────────
  /// POST — Job 생성 + presigned URLs
  static const jobs = '/jobs';

  /// GET — 상태/진행률 조회
  static String jobById(String id) => '/jobs/$id';

  /// POST — 업로드 완료 확인
  static String confirmUpload(String id) => '/jobs/$id/confirm-upload';

  /// POST — 룰 적용 실행 (Queue push)
  static String execute(String id) => '/jobs/$id/execute';

  /// POST — Job 취소 + 크레딧 환불
  static String cancel(String id) => '/jobs/$id/cancel';

  // ── 내부 (Frontend에서 호출 안 함) ─────────────────────
  // POST /jobs/{id}/callback — GPU Worker 전용 콜백
}
