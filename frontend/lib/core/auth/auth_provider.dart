import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authentication state provider.
///
/// State: the current JWT access token (`String?`).
/// - `AsyncData(token)` — authenticated
/// - `AsyncData(null)` — unauthenticated
/// - `AsyncLoading` — checking stored token
/// - `AsyncError` — storage read failed
///
/// Usage:
/// ```dart
/// // Logout
/// await ref.read(authProvider.notifier).logout();
/// context.go('/auth');
/// ```
final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<String?> {
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> build() async {
    return _storage.read(key: 'accessToken');
  }

  /// Persist tokens after successful authentication.
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    state = AsyncData(accessToken);
  }

  /// Clear tokens and transition to unauthenticated state.
  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    state = const AsyncData(null);
  }
}
