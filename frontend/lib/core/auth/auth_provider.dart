import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client_provider.dart';

const _kTokenKey = 'accessToken';
const _storage = FlutterSecureStorage();

/// Manages anonymous JWT authentication state.
///
/// State: [AsyncValue<String?>] where String is the JWT token.
/// - `null` → not authenticated
/// - non-empty string → authenticated
///
/// Storage key is `'accessToken'` — same key that [S3ApiClient]'s
/// interceptor reads from [FlutterSecureStorage].
class _AuthNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return await _storage.read(key: _kTokenKey);
  }

  /// Performs anonymous login via POST /auth/anon.
  ///
  /// Stores the JWT token in [FlutterSecureStorage] under `'accessToken'`.
  /// The GoRouter auth guard will redirect to /domain-select on success.
  Future<void> login() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.createAnonUser();
      await _storage.write(key: _kTokenKey, value: response.token);
      state = AsyncValue.data(response.token);
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
