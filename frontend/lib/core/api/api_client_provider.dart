import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 'mock_api_client.dart';
import 's3_api_client.dart';

part 'api_client_provider.g.dart';

/// true → MockApiClient (오프라인 개발), false → S3ApiClient (실제 API)
///
/// Workers API 배포 완료 후 false로 전환.
const bool _useMock = kDebugMode;

/// Riverpod provider for ApiClient instance.
///
/// Debug 모드에서는 [MockApiClient]를 반환하여 오프라인 개발을 지원.
/// Release 모드에서는 [S3ApiClient]로 실제 Workers API와 통신.
@riverpod
ApiClient apiClient(Ref ref) {
  if (_useMock) {
    return MockApiClient();
  }
  return S3ApiClient();
}
