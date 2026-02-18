import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'presigned_url_cache.g.dart';

/// 세션 내 presigned URL 캐시 — 동일 세션에서 중복 요청 방지
///
/// cacheKey 형식: 'result_{jobId}_{itemIdx}'
/// - [get]: 캐시에서 URL 조회 (없으면 null)
/// - [put]: URL 저장
/// - [clearJob]: 특정 job의 캐시 전체 삭제
/// - [clear]: 전체 캐시 초기화
class PresignedUrlCache {
  final Map<String, String> _cache = {};

  /// 캐시 키로 URL 조회 (없으면 null 반환)
  String? get(String key) => _cache[key];

  /// URL 저장
  void put(String key, String url) => _cache[key] = url;

  /// 특정 jobId 관련 캐시 항목 전체 삭제
  ///
  /// 키 접두사 'result_{jobId}_'로 시작하는 항목을 모두 제거한다.
  void clearJob(String jobId) {
    _cache.removeWhere((key, _) => key.startsWith('result_${jobId}_'));
  }

  /// 전체 캐시 초기화
  void clear() => _cache.clear();
}

/// 세션 전체에서 단일 인스턴스를 공유하는 [PresignedUrlCache] Provider
///
/// keepAlive: true — 위젯 트리 재빌드에도 인스턴스가 유지됨
@Riverpod(keepAlive: true)
PresignedUrlCache presignedUrlCache(Ref ref) {
  return PresignedUrlCache();
}
