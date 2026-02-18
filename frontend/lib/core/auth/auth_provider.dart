import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'jwt_token';
const _storage = FlutterSecureStorage();

/// Manages anonymous JWT authentication state.
///
/// State: [AsyncValue<String?>] where String is the JWT token.
/// - `null` / empty string → not authenticated
/// - non-empty string → authenticated
class _AuthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return await _storage.read(key: _kTokenKey);
  }

  /// Performs an anonymous login (or re-reads stored JWT).
  ///
  /// Subclasses / future implementations should call the POST /auth/anon
  /// endpoint here. For now this is a stub that reads from secure storage.
  Future<void> login() async {
    state = const AsyncValue.loading();
    try {
      final token = await _storage.read(key: _kTokenKey);
      state = AsyncValue.data(token);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Clears the stored JWT and resets auth state.
  Future<void> logout() async {
    await _storage.delete(key: _kTokenKey);
    state = const AsyncValue.data(null);
  }
}

/// Provider for JWT-based auth state.
///
/// ```dart
/// final authState = ref.watch(authProvider);
/// authState.when(
///   loading: () => ...,
///   error: (e, _) => ...,
///   data: (token) => token != null ? WorkspaceScreen() : LoginScreen(),
/// );
/// ```
final authProvider = AsyncNotifierProvider<_AuthNotifier, String?>(
  _AuthNotifier.new,
);
