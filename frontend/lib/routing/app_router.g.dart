// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// GoRouter with auth guard via redirect callback.
///
/// Routes:
/// - /splash : Animated splash (initial)
/// - /auth : Auto anonymous login
/// - /domain-select : Domain/preset selection
/// - /palette : Concept chips, instance selection
/// - /upload : Image picker, R2 upload
/// - /rules : Rule editor (CRUD)
/// - /jobs/:id : Job progress with polling
///
/// Auth Guard:
/// - /splash is always allowed (no redirect)
/// - Unauthenticated → /auth
/// - Authenticated on /auth → /domain-select

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// GoRouter with auth guard via redirect callback.
///
/// Routes:
/// - /splash : Animated splash (initial)
/// - /auth : Auto anonymous login
/// - /domain-select : Domain/preset selection
/// - /palette : Concept chips, instance selection
/// - /upload : Image picker, R2 upload
/// - /rules : Rule editor (CRUD)
/// - /jobs/:id : Job progress with polling
///
/// Auth Guard:
/// - /splash is always allowed (no redirect)
/// - Unauthenticated → /auth
/// - Authenticated on /auth → /domain-select

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// GoRouter with auth guard via redirect callback.
  ///
  /// Routes:
  /// - /splash : Animated splash (initial)
  /// - /auth : Auto anonymous login
  /// - /domain-select : Domain/preset selection
  /// - /palette : Concept chips, instance selection
  /// - /upload : Image picker, R2 upload
  /// - /rules : Rule editor (CRUD)
  /// - /jobs/:id : Job progress with polling
  ///
  /// Auth Guard:
  /// - /splash is always allowed (no redirect)
  /// - Unauthenticated → /auth
  /// - Authenticated on /auth → /domain-select
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'acdf5fba43273431c1789ff3c14b3a5a52c01513';
