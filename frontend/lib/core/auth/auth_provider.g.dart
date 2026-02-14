// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod provider for JWT authentication state.
///
/// Manages anonymous JWT authentication flow:
/// - On app launch: checks if JWT exists in secure storage
/// - login(): calls POST /auth/anon, saves JWT, updates state
/// - logout(): deletes JWT from secure storage, updates state to null
///
/// State: `AsyncValue<String?>` where String is the JWT token.
///
/// Usage:
/// ```dart
/// // Watch auth state
/// final authState = ref.watch(authProvider);
///
/// // Trigger login
/// await ref.read(authProvider.notifier).login();
///
/// // Trigger logout
/// await ref.read(authProvider.notifier).logout();
/// ```

@ProviderFor(Auth)
final authProvider = AuthProvider._();

/// Riverpod provider for JWT authentication state.
///
/// Manages anonymous JWT authentication flow:
/// - On app launch: checks if JWT exists in secure storage
/// - login(): calls POST /auth/anon, saves JWT, updates state
/// - logout(): deletes JWT from secure storage, updates state to null
///
/// State: `AsyncValue<String?>` where String is the JWT token.
///
/// Usage:
/// ```dart
/// // Watch auth state
/// final authState = ref.watch(authProvider);
///
/// // Trigger login
/// await ref.read(authProvider.notifier).login();
///
/// // Trigger logout
/// await ref.read(authProvider.notifier).logout();
/// ```
final class AuthProvider extends $AsyncNotifierProvider<Auth, String?> {
  /// Riverpod provider for JWT authentication state.
  ///
  /// Manages anonymous JWT authentication flow:
  /// - On app launch: checks if JWT exists in secure storage
  /// - login(): calls POST /auth/anon, saves JWT, updates state
  /// - logout(): deletes JWT from secure storage, updates state to null
  ///
  /// State: `AsyncValue<String?>` where String is the JWT token.
  ///
  /// Usage:
  /// ```dart
  /// // Watch auth state
  /// final authState = ref.watch(authProvider);
  ///
  /// // Trigger login
  /// await ref.read(authProvider.notifier).login();
  ///
  /// // Trigger logout
  /// await ref.read(authProvider.notifier).logout();
  /// ```
  AuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authHash();

  @$internal
  @override
  Auth create() => Auth();
}

String _$authHash() => r'ebd9ee6f74c959790379e5c1cd7a73f8c96d3250';

/// Riverpod provider for JWT authentication state.
///
/// Manages anonymous JWT authentication flow:
/// - On app launch: checks if JWT exists in secure storage
/// - login(): calls POST /auth/anon, saves JWT, updates state
/// - logout(): deletes JWT from secure storage, updates state to null
///
/// State: `AsyncValue<String?>` where String is the JWT token.
///
/// Usage:
/// ```dart
/// // Watch auth state
/// final authState = ref.watch(authProvider);
///
/// // Trigger login
/// await ref.read(authProvider.notifier).login();
///
/// // Trigger logout
/// await ref.read(authProvider.notifier).logout();
/// ```

abstract class _$Auth extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
