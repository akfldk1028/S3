// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presigned_url_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 세션 전체에서 단일 인스턴스를 공유하는 [PresignedUrlCache] Provider
///
/// keepAlive: true — 위젯 트리 재빌드에도 인스턴스가 유지됨

@ProviderFor(presignedUrlCache)
final presignedUrlCacheProvider = PresignedUrlCacheProvider._();

/// 세션 전체에서 단일 인스턴스를 공유하는 [PresignedUrlCache] Provider
///
/// keepAlive: true — 위젯 트리 재빌드에도 인스턴스가 유지됨

final class PresignedUrlCacheProvider
    extends
        $FunctionalProvider<
          PresignedUrlCache,
          PresignedUrlCache,
          PresignedUrlCache
        >
    with $Provider<PresignedUrlCache> {
  /// 세션 전체에서 단일 인스턴스를 공유하는 [PresignedUrlCache] Provider
  ///
  /// keepAlive: true — 위젯 트리 재빌드에도 인스턴스가 유지됨
  PresignedUrlCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presignedUrlCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presignedUrlCacheHash();

  @$internal
  @override
  $ProviderElement<PresignedUrlCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PresignedUrlCache create(Ref ref) {
    return presignedUrlCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PresignedUrlCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PresignedUrlCache>(value),
    );
  }
}

String _$presignedUrlCacheHash() => r'fcbda9d5db8d169350a413f42adb9b8c136b2392';
