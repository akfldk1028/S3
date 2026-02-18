import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'api_client.dart';
import 's3_api_client.dart';

part 'api_client_provider.g.dart';

/// Riverpod provider for ApiClient instance.
///
/// Returns [S3ApiClient] which communicates with the Cloudflare Workers API.
/// S3ApiClient reads JWT from FlutterSecureStorage internally (no circular dep).
///
/// For testing, override this provider in ProviderScope with MockApiClient.
@riverpod
ApiClient apiClient(Ref ref) {
  return S3ApiClient();
}
