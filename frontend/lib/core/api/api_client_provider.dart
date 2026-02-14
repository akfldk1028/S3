import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'mock_api_client.dart';

part 'api_client_provider.g.dart';

/// Riverpod provider for ApiClient instance.
///
/// Phase 1: Returns MockApiClient for development without backend.
/// Phase 2: Switch to S3ApiClient when Workers API is ready.
///
/// Usage:
/// ```dart
/// final apiClient = ref.watch(apiClientProvider);
/// final user = await apiClient.getMe();
/// ```
@riverpod
ApiClient apiClient(ApiClientRef ref) {
  // Phase 1: Return mock implementation
  return MockApiClient();

  // Phase 2: Uncomment when switching to real API
  // final jwt = ref.watch(authProvider).value;
  // if (jwt == null) {
  //   throw Exception('No JWT token available');
  // }
  // return S3ApiClient(baseUrl: 'WORKERS_API_URL', jwt: jwt);
}
