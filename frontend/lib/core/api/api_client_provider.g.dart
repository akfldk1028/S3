// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for ApiClient instance.
///
/// Returns [S3ApiClient] which communicates with the Cloudflare Workers API.
/// S3ApiClient reads JWT from FlutterSecureStorage internally (no circular dep).
///
/// For testing, override this provider in ProviderScope with MockApiClient.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// Riverpod provider for ApiClient instance.
///
/// Returns [S3ApiClient] which communicates with the Cloudflare Workers API.
/// S3ApiClient reads JWT from FlutterSecureStorage internally (no circular dep).
///
/// For testing, override this provider in ProviderScope with MockApiClient.

final class ApiClientProvider
    extends $FunctionalProvider<ApiClient, ApiClient, ApiClient>
    with $Provider<ApiClient> {
  /// Riverpod provider for ApiClient instance.
  ///
  /// Returns [S3ApiClient] which communicates with the Cloudflare Workers API.
  /// S3ApiClient reads JWT from FlutterSecureStorage internally (no circular dep).
  ///
  /// For testing, override this provider in ProviderScope with MockApiClient.
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

String _$apiClientHash() => r'1d0ceb175ab0787582a0893424d5afb7dd10e3ce';
