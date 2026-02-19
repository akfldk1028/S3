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
/// - / : Camera home (SNOW-style main screen)
/// - /domain-select : Domain/preset selection
/// - /palette : Concept chips, instance selection
/// - /upload : Image picker, R2 upload
/// - /rules : Rule editor (CRUD)
/// - /jobs/:id : Job progress with polling
///
/// Auth Guard:
/// - /splash is always allowed (no redirect)
/// - Unauthenticated → /auth
/// - Authenticated on /auth → / (camera home)

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// GoRouter with auth guard via redirect callback.
///
/// Routes:
/// - /splash : Animated splash (initial)
/// - /auth : Auto anonymous login
/// - / : Camera home (SNOW-style main screen)
/// - /domain-select : Domain/preset selection
/// - /palette : Concept chips, instance selection
/// - /upload : Image picker, R2 upload
/// - /rules : Rule editor (CRUD)
/// - /jobs/:id : Job progress with polling
///
/// Auth Guard:
/// - /splash is always allowed (no redirect)
/// - Unauthenticated → /auth
/// - Authenticated on /auth → / (camera home)

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// GoRouter with auth guard via redirect callback.
  ///
  /// Routes:
  /// - /splash : Animated splash (initial)
  /// - /auth : Auto anonymous login
  /// - / : Camera home (SNOW-style main screen)
  /// - /domain-select : Domain/preset selection
  /// - /palette : Concept chips, instance selection
  /// - /upload : Image picker, R2 upload
  /// - /rules : Rule editor (CRUD)
  /// - /jobs/:id : Job progress with polling
  ///
  /// Auth Guard:
  /// - /splash is always allowed (no redirect)
  /// - Unauthenticated → /auth
  /// - Authenticated on /auth → / (camera home)
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

String _$appRouterHash() => r'cc82759d39883d489e48be851cb34892f60148a3';
