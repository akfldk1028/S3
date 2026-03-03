// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for ApiClient instance.
///
/// Debug 모드에서는 [MockApiClient]를 반환하여 오프라인 개발을 지원.
/// Release 모드에서는 [S3ApiClient]로 실제 Workers API와 통신.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// Riverpod provider for ApiClient instance.
///
/// Debug 모드에서는 [MockApiClient]를 반환하여 오프라인 개발을 지원.
/// Release 모드에서는 [S3ApiClient]로 실제 Workers API와 통신.

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// Riverpod provider for ApiClient instance.
  ///
  /// Debug 모드에서는 [MockApiClient]를 반환하여 오프라인 개발을 지원.
  /// Release 모드에서는 [S3ApiClient]로 실제 Workers API와 통신.
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

String _$apiClientHash() => r'dc99d47d0da26976aab0b26be4d5d4ce8ad4ca32';
