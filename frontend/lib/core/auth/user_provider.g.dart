// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for user data from GET /me API endpoint.
///
/// Provides user information including plan, credits, and rule slots.
///
/// State: AsyncValue<User> containing current user data.
///
/// Usage:
/// ```dart
/// // Watch user state
/// final userAsync = ref.watch(userProvider);
/// userAsync.when(
///   data: (user) => Text('Plan: ${user.plan}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
///
/// // Refresh user data
/// await ref.read(userProvider.notifier).refresh();
/// ```

@ProviderFor(User)
final userProvider = UserProvider._();

/// Riverpod provider for user data from GET /me API endpoint.
///
/// Provides user information including plan, credits, and rule slots.
///
/// State: AsyncValue<User> containing current user data.
///
/// Usage:
/// ```dart
/// // Watch user state
/// final userAsync = ref.watch(userProvider);
/// userAsync.when(
///   data: (user) => Text('Plan: ${user.plan}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
///
/// // Refresh user data
/// await ref.read(userProvider.notifier).refresh();
/// ```
final class UserProvider extends $AsyncNotifierProvider<User, models.User> {
  /// Riverpod provider for user data from GET /me API endpoint.
  ///
  /// Provides user information including plan, credits, and rule slots.
  ///
  /// State: AsyncValue<User> containing current user data.
  ///
  /// Usage:
  /// ```dart
  /// // Watch user state
  /// final userAsync = ref.watch(userProvider);
  /// userAsync.when(
  ///   data: (user) => Text('Plan: ${user.plan}'),
  ///   loading: () => CircularProgressIndicator(),
  ///   error: (err, stack) => Text('Error: $err'),
  /// );
  ///
  /// // Refresh user data
  /// await ref.read(userProvider.notifier).refresh();
  /// ```
  UserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userHash();

  @$internal
  @override
  User create() => User();
}

String _$userHash() => r'37abaf87f3fb8138d7b4bf4ea3da2256a647ae9c';

/// Riverpod provider for user data from GET /me API endpoint.
///
/// Provides user information including plan, credits, and rule slots.
///
/// State: AsyncValue<User> containing current user data.
///
/// Usage:
/// ```dart
/// // Watch user state
/// final userAsync = ref.watch(userProvider);
/// userAsync.when(
///   data: (user) => Text('Plan: ${user.plan}'),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Error: $err'),
/// );
///
/// // Refresh user data
/// await ref.read(userProvider.notifier).refresh();
/// ```

abstract class _$User extends $AsyncNotifier<models.User> {
  FutureOr<models.User> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<models.User>, models.User>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<models.User>, models.User>,
              AsyncValue<models.User>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
