class ApiEndpoints {
  ApiEndpoints._();

  /// Edge Worker URL (Cloudflare Workers)
  /// 프로덕션: https://s3-api.your-domain.workers.dev
  static const baseUrl = 'http://localhost:8787';

  // Auth: Supabase Auth SDK 직접 사용 (HTTP 엔드포인트 아님)
  // → supabase_flutter 패키지의 supabase.auth.signInWithPassword() 등 사용
  // → 별도 엔드포인트 불필요

  // Segmentation (Edge Public API)
  // 상세: docs/contracts/api-contracts.md
  static const upload = '/api/v1/upload';
  static const segment = '/api/v1/segment';
  static const tasks = '/api/v1/tasks';
  static const results = '/api/v1/results';

  // Helpers
  static String taskById(String id) => '/api/v1/tasks/$id';
  static String resultById(String id) => '/api/v1/results/$id';
}
