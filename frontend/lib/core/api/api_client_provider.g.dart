// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

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

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
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
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<ApiClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiClient create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiClient>(value),
    );
  }
}

String _$apiClientHash() => r'4493721bebaa3c204877cbcb679078d27534f71d';
